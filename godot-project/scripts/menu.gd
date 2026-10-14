extends Control
## Main menu: a shelf of black-figure vases, one per job. The selected vase's painting comes alive,
## and the chapters you have seen leave marks on it.

const QUIPS := {
	"sisyphus": [["西西弗斯", "怎么只画我推石头？"], ["石头先生", "我的脸画歪了。"], ["西西弗斯", "把上面踹我的那位也画进去。"]],
	"prometheus": [["普罗米修斯", "鹰怎么画得比我大？"], ["？？？", "这罐上画的是谁？"], ["", "（罐上只剩一座山。）"]],
	"trolley": [["那一个人", "为什么每次都把我画在岔道上？"], ["论文志愿者", "能不能把我们画在正中间？"], ["赫尔墨斯", "扳道杆就别画了，画了也没接上。"]],
	"tbd": [["赫尔墨斯", "别急，先把釉上了。"], ["赫尔墨斯", "别急，先把釉上了。"], ["赫尔墨斯", "别急，先把釉上了。"]],
}
# the chapter that switches each vase's complaint to its middle line
const QUIP_MID := {"sisyphus": 3, "prometheus": 4, "trolley": 4, "tbd": 99}

var sel := 0
var vases: Array[Control] = []        # one holder per vase
var paints: Array[Control] = []       # the animated painting layer of each vase
var layers: Array[Control] = []       # every layer, for full repaints
var t := 0.0
var info: VBoxContainer
var scroll: ScrollContainer

# painting panel, set before each painter runs
var cv: CanvasItem
var W := 0.0
var H := 0.0


func _ready() -> void:
	sel = clampi(Game.menu_sel, 0, Game.EPISODES.size() - 1)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 28)
	col.add_child(header)
	var tb := VBoxContainer.new()
	tb.add_child(_label("一组荒诞短剧", Game.sans, 12, Color(Game.INK, 0.75)))
	tb.add_child(_label("诸神的差事", Game.serif_black, 46, Game.INK))
	header.add_child(tb)
	var lede := _label("这些陶罐上画着几份永远做不完的工作。你是奥林匹斯新录用的公务员，每一只罐子，都是你被调去的一个岗位。", Game.sans, 14, Game.INK)
	lede.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	lede.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lede.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	lede.size_flags_vertical = Control.SIZE_SHRINK_END
	header.add_child(lede)

	scroll = ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 268)
	col.add_child(scroll)
	var shelf := HBoxContainer.new()
	shelf.alignment = BoxContainer.ALIGNMENT_CENTER
	shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelf.add_theme_constant_override("separation", 22)
	scroll.add_child(shelf)
	for i in Game.EPISODES.size():
		var e: Dictionary = Game.EPISODES[i]
		var item := VBoxContainer.new()
		item.add_theme_constant_override("separation", 2)
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		item.gui_input.connect(_on_vase_input.bind(i))
		# a vase is three stacked layers: body (static), painting (animated), bands and outline (static)
		var canvas := Control.new()
		canvas.custom_minimum_size = Vector2(165, 215)
		canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for kind in ["base", "paint", "top"]:
			var layer := CachedLayer.new()
			layer.paint.connect(_draw_layer.bind(layer, i, kind))
			canvas.add_child(layer)
			layers.append(layer)
			if kind == "paint":
				paints.append(layer)
		item.add_child(canvas)
		var no := _label("第%s份差事" % e["no"], Game.sans, 11, Color(Game.INK, 0.7))
		no.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(no)
		var nm := _label(e["title"], Game.serif_black, 16, Game.INK)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nm.name = "Name"
		item.add_child(nm)
		shelf.add_child(item)
		vases.append(canvas)
	var plank := ColorRect.new()
	plank.color = Game.INK
	plank.custom_minimum_size = Vector2(0, 6)
	col.add_child(plank)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Game.INK
	sb.border_color = Game.BONE
	sb.set_border_width_all(2)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(panel)
	info = VBoxContainer.new()
	info.add_theme_constant_override("separation", 10)
	panel.add_child(info)
	_render_info()
	_repaint_all.call_deferred()


func _label(txt: String, font: Font, size: int, c: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	return l


func _btn(txt: String, filled: bool, small := false) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", Game.serif_black if not small else Game.serif)
	b.add_theme_font_size_override("font_size", 17 if not small else 15)
	var n := StyleBoxFlat.new()
	n.bg_color = Game.CLAY if filled else Color(0, 0, 0, 0)
	n.border_color = Color(Game.BONE, 1.0 if not small else 0.45)
	n.set_border_width_all(2 if not small else 1)
	n.set_content_margin_all(10)
	n.content_margin_left = 20
	n.content_margin_right = 20
	var hv := n.duplicate()
	hv.bg_color = Game.GOLD
	hv.border_color = Game.GOLD
	var dis := n.duplicate()
	dis.border_color = Color(Game.BONE, 0.2)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", hv)
	b.add_theme_stylebox_override("pressed", hv)
	b.add_theme_stylebox_override("disabled", dis)
	b.add_theme_color_override("font_color", Game.INK if filled else Game.BONE)
	b.add_theme_color_override("font_hover_color", Game.INK)
	b.add_theme_color_override("font_disabled_color", Color(Game.BONE, 0.35))
	return b


func _quip(e: Dictionary, p: Dictionary) -> Array:
	var q: Array = QUIPS[e["id"]]
	if p["done"]:
		return q[2]
	if p["seen"].has(QUIP_MID[e["id"]]):
		return q[1]
	return q[0]


func _render_info() -> void:
	for c in info.get_children():
		c.queue_free()
	for i in vases.size():
		var nm: Label = vases[i].get_parent().get_node("Name")
		nm.add_theme_color_override("font_color", Game.INK if i == sel else Color(Game.INK, 0.7))
	var e: Dictionary = Game.EPISODES[sel]
	var p := Game.ep_progress(e["id"])
	var title := _label(e["title"] if not e.get("locked", false) else "第%s份差事 · 待定" % e["no"], Game.serif_black, 28, Game.BONE)
	info.add_child(title)
	var q := _quip(e, p)
	var quip := HBoxContainer.new()
	quip.add_theme_constant_override("separation", 10)
	var bar := ColorRect.new()
	bar.color = Game.GOLD
	bar.custom_minimum_size = Vector2(3, 0)
	quip.add_child(bar)
	if q[0] != "":
		quip.add_child(_label(q[0] + "：", Game.serif, 15, Game.GOLD))
	quip.add_child(_label(q[1], Game.serif, 15, Game.BONE))
	info.add_child(quip)
	var blurb := _label(e["blurb"], Game.sans, 14, Color(Game.BONE, 0.9))
	blurb.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	info.add_child(blurb)
	if e.get("locked", false):
		return
	var ported: bool = e["scene"] != ""
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	info.add_child(actions)
	var seen: Array = p["seen"]
	var start := _btn("从头开始" if (p["done"] or seen.size() > 0) else "上岗", true)
	start.disabled = not ported
	start.pressed.connect(func(): Game.play_episode(e["id"], 1))
	actions.add_child(start)
	var last := 0
	if seen.size() > 0 and not p["done"]:
		last = seen.max()
	if last > 1 and ported:
		var cont := _btn("继续：%s · %s" % [e["chapters"][last - 1][0], e["chapters"][last - 1][1]], false)
		cont.pressed.connect(func(): Game.play_episode(e["id"], last))
		actions.add_child(cont)
	if not ported:
		actions.add_child(_label("这一集正在移植到 Godot，暂时只能在网页版玩。", Game.sans, 13, Color(Game.BONE, 0.7)))
	info.add_child(_label("选择章节", Game.sans, 11, Color(Game.BONE, 0.6)))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	info.add_child(flow)
	var chs: Array = e["chapters"]
	for i in chs.size():
		var c: Array = chs[i]
		var b := _btn("%s  %s%s" % [c[0], c[1], "  ·已看过" if seen.has(i + 1) else ""], false, true)
		b.custom_minimum_size = Vector2(150, 0)
		b.disabled = not ported
		var n := i + 1
		b.pressed.connect(func(): Game.play_episode(e["id"], n))
		flow.add_child(b)


func _on_vase_input(ev: InputEvent, i: int) -> void:
	if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
		_select(i)


func _select(i: int) -> void:
	sel = i
	Game.set_menu_sel(i)
	Game.sfx("tick")
	_render_info()
	_repaint_all()
	var item: Control = vases[i].get_parent()
	scroll.ensure_control_visible(item)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_RIGHT:
			_select((sel + 1) % vases.size())
		elif ev.keycode == KEY_LEFT:
			_select((sel + vases.size() - 1) % vases.size())
		elif ev.keycode == KEY_ENTER or ev.keycode == KEY_SPACE:
			var e: Dictionary = Game.EPISODES[sel]
			if e["scene"] != "":
				Game.play_episode(e["id"], 1)


func _process(dt: float) -> void:
	t += dt
	paints[sel].refresh()


func _repaint_all() -> void:
	for l in layers:
		l.refresh()
	for i in vases.size():
		var lift := -8.0 if i == sel else 0.0
		for l in vases[i].get_children():
			l.position.y = lift
		# unselected vases fade a little toward the wall
		vases[i].modulate = Color(1, 1, 1, 1.0 if i == sel else 0.72)


# ---------- the vase ----------
func _vase_poly(w: float, h: float) -> PackedVector2Array:
	var P := func(x: float, y: float) -> Vector2: return Vector2(w * x, h * y)
	var pts := PackedVector2Array()
	pts.append_array(Paint.cubic_pts(P.call(.36, .06), P.call(.36, .14), P.call(.4, .17), P.call(.38, .22), 8))
	pts.append_array(Paint.cubic_pts(P.call(.38, .22), P.call(.18, .27), P.call(.08, .4), P.call(.1, .52), 14))
	pts.append_array(Paint.cubic_pts(P.call(.1, .52), P.call(.12, .68), P.call(.3, .8), P.call(.38, .88), 14))
	pts.append_array(PackedVector2Array([P.call(.31, .92), P.call(.31, .97), P.call(.69, .97), P.call(.69, .92)]))
	pts.append_array(Paint.cubic_pts(P.call(.62, .88), P.call(.7, .8), P.call(.88, .68), P.call(.9, .52), 14))
	pts.append_array(Paint.cubic_pts(P.call(.9, .52), P.call(.92, .4), P.call(.82, .27), P.call(.62, .22), 14))
	pts.append_array(Paint.cubic_pts(P.call(.62, .22), P.call(.6, .17), P.call(.64, .14), P.call(.64, .06), 8))
	return pts


var _geo_size := Vector2.ZERO
var _poly := PackedVector2Array()
var _left := PackedFloat32Array()   # left edge x for each pixel row


func _geometry(w: float, h: float) -> PackedVector2Array:
	if _geo_size != Vector2(w, h):
		_geo_size = Vector2(w, h)
		_poly = _vase_poly(w, h)
		_left.resize(int(h) + 2)
		var half := _poly.size() / 2
		for row in _left.size():
			var y := float(row)
			_left[row] = w * 0.5
			for i in range(1, half):
				var a := _poly[i - 1]
				var b := _poly[i]
				if a.y <= y and b.y >= y and b.y != a.y:
					_left[row] = lerpf(a.x, b.x, (y - a.y) / (b.y - a.y))
					break
	return _poly


## The vase's left edge at height y. The vase is symmetric.
func _left_x(_poly_unused: PackedVector2Array, _w: float, y: float) -> float:
	return _left[clampi(int(y), 0, _left.size() - 1)]


## A horizontal band between y0 and y1 that follows the vase's outline.
func _band(c: CanvasItem, poly: PackedVector2Array, w: float, y0: float, y1: float, col: Color) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := 6
	for i in n + 1:
		var y := lerpf(y0, y1, float(i) / n)
		var lx := _left_x(poly, w, y)
		left.append(Vector2(lx, y))
		right.append(Vector2(w - lx, y))
	right.reverse()
	left.append_array(right)
	c.draw_colored_polygon(left, col)


func _draw_layer(c: CanvasItem, layer: CachedLayer, i: int, kind: String) -> void:
	var e: Dictionary = Game.EPISODES[i]
	var active := i == sel
	var w := layer.size.x
	var h := layer.size.y
	var poly := _geometry(w, h)
	if kind == "base":
		Paint.ellipse(c, Vector2(w * 0.5, h * 0.975 + (8.0 if active else 0.0)), w * 0.26, h * 0.018, 0.0, Color(Game.INK, 0.25))
		for s in [[1.0, 0.36], [-1.0, 0.64]]:
			var x: float = s[1]
			var sg: float = s[0]
			Paint.polyline(c, Paint.cubic_pts(Vector2(w * x, h * .12), Vector2(w * (x - sg * .2), h * .1), Vector2(w * (x - sg * .26), h * .24), Vector2(w * (x - sg * .14), h * .29)), Game.INK, maxf(3.0, w * 0.03))
		c.draw_colored_polygon(poly, Game.CLAY)
		Paint.ellipse(c, Vector2(w * 0.4, h * 0.45), w * 0.3, h * 0.2, 0.0, Color(Game.LIGHT, 0.6))
	elif kind == "paint":
		# the painted panel: draw the painting, then mask what falls outside the vase
		var px := w * 0.1
		var py := h * 0.3
		var pw := w * 0.8
		var ph := h * 0.42
		cv = c
		W = pw
		H = ph
		c.draw_set_transform(Vector2(px, py))
		_paint(e["id"], t if active else 1.4 + i, Game.ep_progress(e["id"]))
		c.draw_set_transform(Vector2.ZERO)
		var lm := PackedVector2Array([Vector2(-20, py - 4)])
		var rm := PackedVector2Array([Vector2(w + 20, py - 4)])
		for k in 15:
			var y := lerpf(py - 4, py + ph + 4, k / 14.0)
			var lx := _left_x(poly, w, y)
			lm.append(Vector2(lx, y))
			rm.append(Vector2(w - lx, y))
		lm.append(Vector2(-20, py + ph + 4))
		rm.append(Vector2(w + 20, py + ph + 4))
		c.draw_colored_polygon(lm, Game.CLAY)
		c.draw_colored_polygon(rm, Game.CLAY)
	else:
		# lip, neck bands, tongues, rays and foot
		_band(c, poly, w, h * 0.06, h * 0.09, Game.INK)
		_band(c, poly, w, h * 0.15, h * 0.162, Game.INK)
		for k in 14:
			var x := w * (0.2 + k * 0.045)
			var lx := _left_x(poly, w, h * 0.245)
			if x > lx + 3 and x < w - lx - 3:
				Paint.ellipse(c, Vector2(x, h * 0.245), w * 0.016, h * 0.022, 0.0, Game.INK)
		_band(c, poly, w, h * 0.27, h * 0.278, Game.INK)
		_band(c, poly, w, h * 0.72, h * 0.73, Game.INK)
		_band(c, poly, w, h * 0.84, h * 0.97, Game.INK)
		for k in 10:
			var x := w * (0.24 + k * 0.058)
			var lx := _left_x(poly, w, h * 0.84)
			if x - w * 0.02 > lx and x + w * 0.02 < w - lx:
				c.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.02, h * 0.84), Vector2(x, h * 0.745), Vector2(x + w * 0.02, h * 0.84)]), Game.INK)
		c.draw_line(Vector2(w * 0.31, h * 0.92), Vector2(w * 0.69, h * 0.92), Game.CLAY, 1.2)
		Paint.ellipse(c, Vector2(w * 0.27, h * 0.48), w * 0.03, h * 0.12, -0.15, Color(Game.BONE, 0.18))
		var outline := poly.duplicate()
		outline.append(poly[0])
		c.draw_polyline(outline, Game.INK, 2.0, true)
		if Game.ep_progress(e["id"])["done"]:
			var r := Rect2(w * 0.7, h * 0.02, 52, 20)
			c.draw_rect(r, Game.INK)
			Paint.text(c, Game.sans, r.get_center(), "已完成", 11, Game.GOLD, 0)


# ---------- paintings: each draws inside W×H, with marks left by progress ----------
func _paint(id: String, tt: float, p: Dictionary) -> void:
	cv.draw_rect(Rect2(0, 0, W, H), Game.LIGHT)
	match id:
		"sisyphus":
			_p_sisyphus(tt, p)
		"prometheus":
			_p_prometheus(tt, p)
		"trolley":
			_p_trolley(tt, p)
		_:
			Paint.text(cv, Game.serif_black, Vector2(W / 2, H * 0.52), "？", int(H * 0.5), Color(Game.INK, 0.18 + 0.06 * sin(tt * 1.5)), 0)


func _ground(y: float) -> void:
	cv.draw_rect(Rect2(0, y, W, H - y), Game.DEEP)
	cv.draw_line(Vector2(0, y), Vector2(W, y), Game.INK, 2.0)


func _fig(x: float, y: float, h: float, lean := 0.0) -> void:
	var hip := Vector2(x, y - h * 0.45)
	var sh := Vector2(x + lean * h * 0.28, y - h * 0.45 - h * 0.3 * (1.0 - absf(lean) * 0.3))
	Paint.line(cv, hip, Vector2(x - h * 0.1, y), Game.INK, h * 0.09)
	Paint.line(cv, hip, Vector2(x + h * 0.1, y), Game.INK, h * 0.09)
	Paint.line(cv, hip, sh, Game.INK, h * 0.14)
	var hand := sh + (Vector2(h * 0.28, -h * 0.02) if lean != 0.0 else Vector2(h * 0.05, h * 0.28))
	Paint.line(cv, sh, hand, Game.INK, h * 0.08)
	cv.draw_circle(sh + Vector2(lean * h * 0.08, -h * 0.12), h * 0.09, Game.INK)


func _tag(x: float, y: float, s: String) -> void:
	var fs := int(maxf(9.0, H * 0.075))
	var tw := Paint.text_width(Game.serif, s, fs) + fs * 0.6
	var th := fs * 1.4
	var r := Rect2(x - tw / 2, y - th, tw, th)
	cv.draw_rect(r, Game.BONE)
	cv.draw_rect(r, Game.INK, false, 1.0)
	Paint.text(cv, Game.serif, r.get_center(), s, fs, Game.INK, 0)


func _boulder(c: Vector2, r: float, rot: float, with_face: bool) -> void:
	cv.draw_circle(c, r, Game.INK)
	var T := Transform2D(rot, c)
	if with_face:
		cv.draw_circle(T * Vector2(-r * 0.32, -r * 0.2), r * 0.11, Game.BONE)
		cv.draw_circle(T * Vector2(r * 0.32, -r * 0.2), r * 0.11, Game.BONE)
		var pts := PackedVector2Array()
		for k in 9:
			var a := lerpf(0.35, PI - 0.35, k / 8.0)
			pts.append(T * (Vector2(0, r * 0.08) + Vector2(cos(a), sin(a)) * r * 0.42))
		cv.draw_polyline(pts, Game.BONE, 1.6, true)
	else:
		var pts := PackedVector2Array()
		for k in 9:
			var a := lerpf(0.2, 2.6, k / 8.0)
			pts.append(T * (Vector2(cos(a), sin(a)) * r * 0.6))
		cv.draw_polyline(pts, Game.CLAY, 1.4, true)


func _p_sisyphus(tt: float, p: Dictionary) -> void:
	var a0 := Vector2(W * 0.12, H * 0.86)
	var a1 := Vector2(W * 0.84, H * 0.3)
	var L := a0.distance_to(a1)
	var u := (a1 - a0) / L
	cv.draw_colored_polygon(PackedVector2Array([Vector2(-2, H), Vector2(-2, a0.y), a0, a1, Vector2(W + 2, a1.y), Vector2(W + 2, H)]), Game.DEEP)
	Paint.polyline(cv, PackedVector2Array([Vector2(-2, a0.y), a0, a1, Vector2(W + 2, a1.y)]), Game.INK, 2.0)
	var r := H * 0.085
	var k := fmod(tt, 6.0) / 6.0
	var up := 0.72
	var fpos := 0.0
	if k < up:
		fpos = 0.06 + 0.8 * (k / up)
	else:
		var q := minf(1.0, (k - up) / (1.0 - up) * 1.6)
		fpos = 0.86 - 0.8 * q * q
	var at := func(s: float) -> Vector2: return a0 + u * s * L
	var p0: Vector2 = at.call(fpos)
	var bc := p0 + Vector2(u.y * r, -u.x * r)
	var pf := fpos - r * 2.4 / L if k < up else maxf(0.0, 0.86 - r * 2.4 / L - ((k - up) / (1.0 - up)) * 0.6)
	var pp: Vector2 = at.call(pf)
	_fig(pp.x, pp.y, H * 0.26, 0.9 if k < up else 0.0)
	_boulder(bc, r, fpos * L / r, p["seen"].has(3))
	if k > up - 0.04 and k < up + 0.08:
		var e := 1.0 - absf(k - up) / 0.08
		var top: Vector2 = at.call(0.86)
		var fp := top + Vector2(u.y * r + r * 1.1 + r * 4 * (1 - e), -u.x * r - r * 0.4 - r * 5 * (1 - e))
		Paint.line(cv, fp + Vector2(r * 6, -r * 7), fp + Vector2(r * 0.5, -r * 0.6), Game.INK, r * 0.6)
		Paint.ellipse(cv, fp, r * 0.9, r * 0.4, -0.75, Game.INK)
	if p["seen"].has(4):
		cv.draw_line(Vector2(W * 0.07, a0.y), Vector2(W * 0.07, a0.y - H * 0.24), Game.INK, 1.5)
		_tag(W * 0.07, a0.y - H * 0.2, "罢工")
	if p["seen"].has(5):
		cv.draw_rect(Rect2(W * 0.15, a0.y - H * 0.04, W * 0.08, H * 0.04), Game.INK)
		cv.draw_rect(Rect2(W * 0.155, a0.y - H * 0.035, W * 0.07, H * 0.01), Game.BONE)


func _p_prometheus(tt: float, p: Dictionary) -> void:
	var hills := PackedVector2Array([Vector2(0, H * 0.88)])
	for q in [[0, .6], [.12, .46], [.24, .56], [.36, .4], [.5, .55], [.58, .88]]:
		hills.append(Vector2(W * q[0], H * q[1]))
	cv.draw_colored_polygon(hills, Game.FAR)
	_ground(H * 0.88)
	var cliff := PackedVector2Array([Vector2(W + 2, H * 0.1)])
	var y := H * 0.1
	while y <= H:
		cliff.append(Vector2(W * 0.56 - (y / H) * W * 0.05 + sin(y * 0.12) * 2, y))
		y += 4
	cliff.append(Vector2(W + 2, H))
	cv.draw_colored_polygon(cliff, Game.ROCK)
	var edge := cliff.slice(1, cliff.size() - 1)
	Paint.polyline(cv, edge, Game.INK, 2.0, false)
	var done: bool = p["done"]
	var sunk: bool = p["seen"].has(3)
	if not done:
		var px := W * 0.76
		var fy := H * 0.74
		var h := H * 0.4
		var col := Game.ROCK if sunk else Game.INK
		var hip := Vector2(px, fy - h * 0.45)
		var sh := Vector2(px, fy - h * 0.78)
		for s in [-1, 1]:
			Paint.line(cv, hip, Vector2(px + s * h * 0.1, fy), col, h * 0.08)
			Paint.line(cv, sh, Vector2(px + s * h * 0.32, sh.y - h * 0.2), col, h * 0.08)
		Paint.line(cv, hip, sh, col, h * 0.15)
		cv.draw_circle(Vector2(px, fy - h * 0.92), h * 0.09, Color("#7d3a1b") if sunk else Game.INK)
		cv.draw_rect(Rect2(px - h * 0.3, fy, h * 0.6, h * 0.05), Game.INK)
		var k := fmod(tt, 4.0) / 4.0
		var gr := k / 0.55 if k < 0.55 else (1.0 if k < 0.65 else 0.0)
		var lv := Vector2(px - h * 0.07, fy - h * 0.56)
		Paint.ellipse(cv, lv, h * 0.07 * (0.3 + 0.7 * gr), h * 0.055 * (0.3 + 0.7 * gr), -0.3, Game.GOLD if gr >= 0.98 else Game.LIGHT)
		var A := Vector2(W * 0.2, H * 0.34)
		var r := H * 0.07
		var B := lv + Vector2(-r * 1.25, r * 0.3)
		Paint.polyline(cv, PackedVector2Array([Vector2(A.x - r * 0.2, H * 0.88), Vector2(A.x - r * 0.2, A.y + r * 0.5), Vector2(A.x + r * 1.1, A.y + r * 0.3)]), Game.INK, r * 0.35)
		var uu := 0.0
		if k > 0.55 and k < 0.65:
			uu = (k - 0.55) / 0.1
		elif k >= 0.65 and k < 0.85:
			uu = 1.0 - (k - 0.65) / 0.2
		uu = uu * uu * (3.0 - 2.0 * uu)
		var e := A.lerp(B, uu) - Vector2(0, sin(uu * PI) * H * 0.12)
		var dir := -1.0 if (k >= 0.65 and k < 0.85) else 1.0
		var fly := k > 0.55 and k < 0.85
		var T := Transform2D(0.0, Vector2(dir, 1), 0.0, e)
		Paint.ellipse(cv, e, r * 0.9, r * 0.5, -0.2 * dir, Game.INK)
		cv.draw_colored_polygon(PackedVector2Array([T * Vector2(-r * 0.7, 0), T * Vector2(-r * 1.5, r * 0.35), T * Vector2(-r * 1.4, -r * 0.1)]), Game.INK)
		if fly:
			var fl := sin(tt * 16.0)
			cv.draw_colored_polygon(PackedVector2Array([T * Vector2(-r * 0.3, -r * 0.1), T * Vector2(-r, -r * 0.2 - r * 1.4 * cos(fl)), T * Vector2(r * 0.5, -r * 0.2)]), Game.INK)
		cv.draw_circle(T * Vector2(r * 0.78, -r * 0.45), r * 0.33, Game.INK)
		cv.draw_colored_polygon(PackedVector2Array([T * Vector2(r, -r * 0.57), T * Vector2(r * 1.32, -r * 0.4), T * Vector2(r * 1.3, -r * 0.23), T * Vector2(r * 1.04, -r * 0.35)]), Game.INK)
	if p["seen"].has(4) or done:
		cv.draw_rect(Rect2(0, 0, W, H), Color(Game.FOG, 0.35 if done else 0.22))


func _p_trolley(tt: float, p: Dictionary) -> void:
	_ground(H * 0.88)
	var r := H * 0.06
	var y0 := H * 0.74
	var y1 := H * 0.46
	var fx := W * 0.34
	Paint.polyline(cv, PackedVector2Array([Vector2(0, y0), Vector2(W, y0)]), Game.INK, 2.5, false)
	Paint.polyline(cv, PackedVector2Array([Vector2(fx, y0), Vector2(fx + W * 0.12, y1), Vector2(W, y1)]), Game.INK, 2.5, false)
	var k := fmod(tt, 5.0) / 5.0
	var flip := int(tt / 5.0) % 2 == 1
	var d := k * 1.3
	var x := d * W
	var y := y0
	var a := 0.0
	if d * W >= fx and flip:
		var uu := minf(1.0, (d * W - fx) / (W * 0.12))
		y = lerpf(y0, y1, uu)
		a = atan2(y1 - y0, W * 0.12) if uu < 1.0 else 0.0
	var vol: bool = p["seen"].has(4)
	if not (not flip and x > W * 0.76):
		for i in (3 if vol else 5):
			_fig(W * 0.82 + (i - (1.0 if vol else 2.0)) * r * 0.85, y0, r * 2.0)
	if not (flip and x > W * 0.76):
		_fig(W * 0.82, y1, r * 2.0)
	if vol:
		_tag(W * 0.82, y0 - r * 2.6, "撞我！")
	var T := Transform2D(a, Vector2(x, y))
	cv.draw_colored_polygon(PackedVector2Array([T * Vector2(-r * 1.7, -r * 1.9), T * Vector2(r * 1.7, -r * 1.9), T * Vector2(r * 1.7, -r * 0.3), T * Vector2(-r * 1.7, -r * 0.3)]), Game.INK)
	for i in 3:
		var o := Vector2(-r * 1.35 + i * r * 0.95, -r * 1.6)
		cv.draw_colored_polygon(PackedVector2Array([T * o, T * (o + Vector2(r * 0.6, 0)), T * (o + Vector2(r * 0.6, r * 0.5)), T * (o + Vector2(0, r * 0.5))]), Game.BONE)
	for wx in [-r, r]:
		cv.draw_circle(T * Vector2(wx, -r * 0.2), r * 0.3, Game.INK)
	var lx := W * 0.22
	var ly := H * 0.88
	var la := 0.6 if flip else -0.6
	cv.draw_rect(Rect2(lx - r * 0.9, ly - r * 0.6, r * 1.8, r * 0.6), Game.INK)
	Paint.line(cv, Vector2(lx, ly - r * 0.5), Vector2(lx + sin(la) * r * 2.2, ly - r * 0.5 - cos(la) * r * 2.2), Game.INK, r * 0.28)
	if p["done"]:
		cv.draw_dashed_line(Vector2(lx + r, ly - r * 0.3), Vector2(fx - r * 0.5, ly - r * 0.3), Game.INK, 1.0, 3.0)
		_tag((lx + fx) / 2 + r, ly - r * 0.6, "没接上")
