class_name EpisodeBase
extends Control
## Shared frame for every episode: HUD, painted stage, dialogue scroll, chapter cards,
## end card, and a step-by-step script runner. Episodes subclass this and fill in the hooks.

# ---------- set by subclasses ----------
var ep_id := ""
var ep_title := ""
var ep_subtitle := ""
var credit := ""
var who := {}            # "H": ["赫尔墨斯", "冥界人事部"], "N": ["", ""] ...
var script_steps: Array = []

# ---------- runner state ----------
var si := -1
var step: Dictionary = {}
var chapters_idx: Array[int] = []
var chap_t := 0.0
var wait_t := 0.0
var typing := false
var tw := 0.0
var full_text := ""
var finished := false

# ---------- shared stage effects ----------
var phase := 0.0
var shake := 0.0
var flash := 0.0
var bubble := {}         # {"who":..,"t":..,"life":..}
var popups: Array = []
var dust: Array = []
var heads := {}          # speaker -> Vector2 anchor for speech bubbles

# ---------- UI nodes ----------
var stage: Control
var bg_layer: CachedLayer   # static backdrop, rendered once into a texture
var fx_layer: Control   # everything that moves, redrawn every frame
var hud_box: HBoxContainer
var chap_value: Label
var who_label: Label
var text_label: Label
var more_label: Label
var dlg_panel: PanelContainer
var chap_card: Control
var chap_n: Label
var chap_t_label: Label
var end_card: Control
var end_text: Label
var end_quote: Label
var end_verdict: Label
var next_btn: Button
var sound_btn: Button
var opts_box: HFlowContainer

const REDUCE_MOTION := false


func _ready() -> void:
	setup()
	_build_ui()
	script_steps = build_script()
	for i in script_steps.size():
		if script_steps[i]["t"] == "chapter":
			chapters_idx.append(i)
	start_at(Game.start_chapter)


# ===== hooks for subclasses =====
func setup() -> void: pass
func build_script() -> Array: return []
func build_hud() -> void: pass
func reset_state() -> void: pass
func skip_fix(_target: int, _rounds: int) -> void: pass
func custom_step(_s: Dictionary) -> bool: return false
func custom_tap(_s: Dictionary, _pos) -> void: pass
func custom_key(_e: InputEventKey) -> bool: return false
func custom_update(_dt: float) -> void: pass
func draw_backdrop(_cv: CanvasItem) -> void: pass
func draw_scene(_cv: CanvasItem) -> void: pass
func draw_front(_cv: CanvasItem) -> void: pass
func end_texts() -> Dictionary: return {"text": "", "quote": "", "verdict": ""}
func next_episode() -> String: return ""


# ===== UI =====
func _label(txt: String, font: Font, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _box_style(bg: Color, border: Color, bw: int, pad: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_content_margin_all(pad)
	return sb


func _button(txt: String, filled: bool) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", Game.serif)
	b.add_theme_font_size_override("font_size", 16)
	var normal := _box_style(Game.CLAY if filled else Color(0, 0, 0, 0), Game.BONE, 2, 10)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	var hover := normal.duplicate()
	hover.bg_color = Game.GOLD
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_color_override("font_color", Game.INK if filled else Game.BONE)
	b.add_theme_color_override("font_hover_color", Game.INK)
	b.add_theme_color_override("font_pressed_color", Game.INK)
	return b


func add_stat(title: String) -> Label:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.add_child(_label(title, Game.sans, 11, Color(Game.INK, 0.75)))
	var val := _label("0", Game.serif_black, 22, Game.INK)
	v.add_child(val)
	hud_box.add_child(v)
	return val


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16 if side in ["left", "right"] else 12)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	# header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	col.add_child(header)
	var tbox := VBoxContainer.new()
	tbox.add_theme_constant_override("separation", 2)
	tbox.add_child(_label(ep_title, Game.serif_black, 30, Game.INK))
	tbox.add_child(_label(ep_subtitle, Game.sans, 12, Color(Game.INK, 0.75)))
	header.add_child(tbox)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	hud_box = HBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 20)
	hud_box.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(hud_box)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 0)
	cv.add_child(_label("章节", Game.sans, 11, Color(Game.INK, 0.75)))
	chap_value = _label("序", Game.serif_black, 17, Game.INK)
	cv.add_child(chap_value)
	hud_box.add_child(cv)
	build_hud()

	# stage
	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", _box_style(Game.INK, Game.INK, 0, 3))
	col.add_child(frame)
	stage = Control.new()
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.add_child(stage)
	stage.gui_input.connect(_on_stage_input)
	bg_layer = CachedLayer.new()
	bg_layer.paint.connect(func(c): draw_backdrop(c))
	stage.add_child(bg_layer)
	fx_layer = Control.new()
	fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.draw.connect(_on_stage_draw)
	stage.add_child(fx_layer)
	_build_cards()

	# dialogue scroll
	dlg_panel = PanelContainer.new()
	dlg_panel.custom_minimum_size = Vector2(0, 92)
	var dsb := _box_style(Game.INK, Game.BONE, 2, 14)
	dsb.content_margin_left = 20
	dsb.content_margin_right = 20
	dsb.expand_margin_left = 0
	dlg_panel.add_theme_stylebox_override("panel", dsb)
	dlg_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dlg_panel.gui_input.connect(_on_dlg_input)
	col.add_child(dlg_panel)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	dv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg_panel.add_child(dv)
	who_label = _label("", Game.serif, 13, Game.GOLD)
	who_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dv.add_child(who_label)
	text_label = _label("", Game.serif, 18, Game.BONE)
	text_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dv.add_child(text_label)
	opts_box = HFlowContainer.new()
	opts_box.add_theme_constant_override("h_separation", 8)
	opts_box.visible = false
	dv.add_child(opts_box)
	more_label = _label("▼", Game.sans, 12, Game.GOLD)
	more_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	more_label.position -= Vector2(14, 8)
	more_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg_panel.add_child(more_label)
	more_label.top_level = false

	# foot
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 14)
	col.add_child(foot)
	var back := Button.new()
	back.text = "← 主界面"
	back.flat = true
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_color_override("font_color", Game.INK)
	back.add_theme_font_override("font", Game.serif)
	back.pressed.connect(func(): Game.to_menu())
	foot.add_child(back)
	var cr := _label(credit, Game.sans, 12, Color(Game.INK, 0.85))
	cr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(cr)
	sound_btn = Button.new()
	sound_btn.focus_mode = Control.FOCUS_NONE
	sound_btn.add_theme_color_override("font_color", Game.INK)
	sound_btn.add_theme_stylebox_override("normal", _box_style(Color(0, 0, 0, 0), Game.INK, 2, 6))
	sound_btn.add_theme_stylebox_override("hover", _box_style(Game.LIGHT, Game.INK, 2, 6))
	sound_btn.pressed.connect(func():
		Game.set_sound(not Game.sound_on)
		_sync_sound())
	foot.add_child(sound_btn)
	_sync_sound()


func _sync_sound() -> void:
	sound_btn.text = "声音：" + ("开" if Game.sound_on else "关")


func _build_cards() -> void:
	# chapter card
	chap_card = VBoxContainer.new()
	chap_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chap_card.alignment = BoxContainer.ALIGNMENT_CENTER
	chap_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chap_n = _label("", Game.serif, 15, Game.BONE)
	chap_n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chap_t_label = _label("", Game.serif_black, 68, Game.BONE)
	chap_t_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chap_t_label.add_theme_color_override("font_shadow_color", Game.INK)
	chap_t_label.add_theme_constant_override("shadow_offset_y", 3)
	chap_t_label.add_theme_constant_override("shadow_offset_x", 0)
	chap_card.add_child(chap_n)
	chap_card.add_child(chap_t_label)
	chap_card.visible = false
	stage.add_child(chap_card)

	# end card
	end_card = CenterContainer.new()
	end_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_card.visible = false
	var dim := ColorRect.new()
	dim.color = Color(Game.INK, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.add_child(dim)
	dim.visible = false
	dim.name = "Dim"
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 0)
	card.add_theme_stylebox_override("panel", _box_style(Game.INK, Game.BONE, 2, 22))
	end_card.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	card.add_child(v)
	v.add_child(_label("完", Game.serif_black, 26, Game.BONE))
	end_verdict = _label("", Game.serif_black, 22, Game.GOLD)
	v.add_child(end_verdict)
	end_text = _label("", Game.sans, 14, Game.BONE)
	end_text.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	end_text.custom_minimum_size = Vector2(356, 0)
	v.add_child(end_text)
	end_quote = _label("", Game.serif, 14, Color(Game.BONE, 0.85))
	end_quote.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	end_quote.custom_minimum_size = Vector2(356, 0)
	v.add_child(end_quote)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var again := _button("从头再来", true)
	again.pressed.connect(func(): start_at(1))
	row.add_child(again)
	next_btn = _button("下一份差事", false)
	next_btn.pressed.connect(func(): Game.play_episode(next_episode(), 1))
	row.add_child(next_btn)
	var home := _button("回到主界面", false)
	home.pressed.connect(func(): Game.to_menu())
	row.add_child(home)
	stage.add_child(end_card)


# ===== dialogue =====
func set_hint(s: String) -> void:
	who_label.text = ""
	text_label.text = s
	text_label.visible_characters = -1
	text_label.add_theme_font_override("font", Game.sans)
	text_label.add_theme_font_size_override("font_size", 14)
	text_label.add_theme_color_override("font_color", Color(Game.BONE, 0.7))
	more_label.visible = false
	opts_box.visible = false
	typing = false


func show_line(speaker: String, s: String) -> void:
	var w: Array = who.get(speaker, ["", ""])
	who_label.text = w[0] + ("  " + w[1] if w[0] != "" else "")
	text_label.add_theme_font_override("font", Game.serif)
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.add_theme_color_override("font_color", Color(Game.BONE, 0.85 if speaker == "N" else 1.0))
	full_text = s
	text_label.text = s
	text_label.visible_characters = 0
	tw = 0.0
	typing = true
	more_label.visible = false
	opts_box.visible = false


func finish_typing() -> void:
	typing = false
	text_label.visible_characters = -1
	more_label.visible = step.get("t", "") != "choice"
	if step.get("t", "") == "choice":
		opts_box.visible = true


# ===== effects =====
func say(speaker: String, t: String, life := 1.8) -> void:
	bubble = {"who": speaker, "t": t, "life": life}


func popup(pos: Vector2, t: String, life := 1.3, hot := false, small := false, good := false) -> void:
	popups.append({"p": pos, "t": t, "life": life, "hot": hot, "small": small, "good": good})


func burst(pos: Vector2, n: int) -> void:
	for i in n:
		var a := -PI * randf()
		var sp := 40.0 + randf() * 120.0
		dust.append({"p": pos, "v": Vector2(cos(a), sin(a)) * sp, "life": 0.5 + randf() * 0.4, "r": 1.5 + randf() * 3.0})


# ===== runner =====
func start_at(n: int) -> void:
	end_card.visible = false
	stage.get_node("Dim").visible = false
	finished = false
	popups.clear()
	dust.clear()
	bubble = {}
	reset_state()
	if chapters_idx.is_empty():
		return
	var target: int = chapters_idx[clampi(n - 1, 0, chapters_idx.size() - 1)]
	var rounds := 0
	for i in target:
		var s: Dictionary = script_steps[i]
		if s["t"] == "do":
			s["fn"].call()
		rounds += int(s.get("rounds", 0))
	skip_fix(target, rounds)
	popups.clear()
	dust.clear()
	bubble = {}
	go(target)


func go(i: int) -> void:
	si = i
	step = script_steps[i]
	chap_card.visible = false
	match step["t"]:
		"chapter":
			chap_n.text = step["n"]
			chap_t_label.text = step["title"]
			chap_card.visible = true
			chap_value.text = step["n"] + " · " + step["title"]
			chap_t = 0.0
			set_hint("")
			Game.sfx("gong")
			Game.mark_seen(ep_id, chapters_idx.find(i) + 1)
			popups.clear()
			bubble = {}
		"say":
			var tx = step["text"]
			show_line(step["who"], tx.call() if tx is Callable else tx)
		"do":
			step["fn"].call()
			go(i + 1)
			return
		"wait":
			wait_t = step["d"]
			set_hint("")
		"end":
			finished = true
			set_hint("")
			Game.mark_done(ep_id)
			var t := end_texts()
			end_text.text = t.get("text", "")
			end_quote.text = t.get("quote", "")
			end_verdict.text = t.get("verdict", "")
			end_verdict.visible = end_verdict.text != ""
			var nx := next_episode()
			next_btn.visible = nx != "" and Game.episode(nx).get("scene", "") != ""
			get_tree().create_timer(0.6).timeout.connect(func():
				stage.get_node("Dim").visible = true
				end_card.visible = true)
		_:
			if not custom_step(step):
				push_warning("unknown step " + str(step["t"]))
	on_hud()


func next() -> void:
	go(si + 1)


func on_hud() -> void: pass


func tap(pos) -> void:
	if finished:
		return
	var t: String = step.get("t", "")
	if t == "say":
		if typing:
			finish_typing()
		else:
			Game.sfx("tick")
			next()
	elif t == "chapter":
		if chap_t > 0.5:
			next()
	else:
		custom_tap(step, pos)


func _on_stage_input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		tap(e.position)
	elif e is InputEventScreenTouch and e.pressed:
		tap(e.position)


func _on_dlg_input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
		tap(null)


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed or e.echo:
		return
	if finished:
		return
	if custom_key(e):
		get_viewport().set_input_as_handled()
		return
	if e.keycode == KEY_SPACE or e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER:
		tap(null)
		get_viewport().set_input_as_handled()


func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	phase += dt
	var t: String = step.get("t", "")
	if t == "chapter":
		chap_t += dt
		if chap_t > 2.2:
			next()
	elif t == "wait":
		wait_t -= dt
		if wait_t <= 0.0:
			next()
	if typing:
		tw += dt * 34.0
		var n := int(tw)
		text_label.visible_characters = n
		if n >= full_text.length():
			finish_typing()
	custom_update(dt)
	if not bubble.is_empty():
		bubble["life"] -= dt
		if bubble["life"] <= 0.0:
			bubble = {}
	shake = maxf(0.0, shake - dt)
	flash = maxf(0.0, flash - dt)
	for p in popups:
		p["life"] -= dt
		p["p"].y -= 30.0 * dt
	popups = popups.filter(func(p): return p["life"] > 0.0)
	for d in dust:
		d["life"] -= dt
		d["p"] += d["v"] * dt
		d["v"].y += 220.0 * dt
	dust = dust.filter(func(d): return d["life"] > 0.0)
	# screen shake moves the two layers instead of re-drawing the backdrop
	var off := Vector2.ZERO
	if shake > 0.0:
		var k := shake * 30.0
		off = Vector2((randf() - 0.5) * k, (randf() - 0.5) * k)
	bg_layer.position = off
	fx_layer.position = off
	fx_layer.queue_redraw()


## Ask for the static backdrop to be repainted (when something in it changes).
func redraw_backdrop() -> void:
	bg_layer.refresh()


# ===== drawing =====
var shake_off := Vector2.ZERO


## Set a local transform for the next draw calls, on top of the screen shake.
func xf(cv: CanvasItem, pos: Vector2, rot := 0.0, scl := Vector2.ONE) -> void:
	cv.draw_set_transform(shake_off + pos, rot, scl)


func xf_reset(cv: CanvasItem) -> void:
	cv.draw_set_transform(shake_off, 0.0, Vector2.ONE)


func _on_stage_draw() -> void:
	var cv := fx_layer
	var size := stage.size
	shake_off = Vector2.ZERO
	xf_reset(cv)
	heads.clear()
	draw_scene(cv)
	xf_reset(cv)
	for d in dust:
		cv.draw_circle(d["p"], d["r"], Color(Game.INK, minf(1.0, d["life"] * 2.0)))
	for p in popups:
		var R := unit()
		var fs := int(maxf(11.0 if p["small"] else 13.0, R * (0.75 if p["hot"] else (0.45 if p["small"] else 0.6))))
		var w := Paint.text_width(Game.serif_black, p["t"], fs) * 0.5 + 8.0
		var x := clampf(p["p"].x, w, size.x - w)
		var col: Color = Game.GOLD if p["hot"] else (Game.GOLD if (p["small"] and p["good"]) else Game.BONE)
		col.a = minf(1.0, p["life"] * 2.0)
		Paint.text(cv, Game.serif_black, Vector2(x, p["p"].y), p["t"], fs, col, 0, 6 if p["small"] else 8, Color(Game.INK, col.a))
	draw_front(cv)
	_draw_bubble(cv, size)
	if flash > 0.0:
		cv.draw_rect(Rect2(Vector2.ZERO, size), Color(Game.BONE, flash * 0.8))
	cv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The base unit for sizes on the stage; episodes override.
func unit() -> float:
	return maxf(12.0, minf(stage.size.x * 0.042, stage.size.y * 0.07))


func band() -> float:
	return maxf(10.0, minf(22.0, stage.size.y * 0.05))


func _draw_bubble(cv: CanvasItem, size: Vector2) -> void:
	if bubble.is_empty() or not heads.has(bubble["who"]):
		return
	var hd: Vector2 = heads[bubble["who"]]
	var R := unit()
	var fs := int(clampf(R * 0.6, 13.0, 17.0))
	var tw_ := Paint.text_width(Game.serif, bubble["t"], fs)
	var pw := tw_ + fs * 1.2
	var ph := fs * 2.0
	var x := clampf(hd.x - pw * 0.35, 6.0, size.x - pw - 6.0)
	var y := maxf(band() * 2.0 + 4.0, hd.y - R * 1.1 - ph)
	var a := minf(1.0, bubble["life"] * 4.0)
	var tx := clampf(hd.x - 4.0, x + 8.0, x + pw - 18.0)
	var tip := Vector2(hd.x + 2.0, hd.y - R * 0.35)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Game.BONE, a)
	sb.border_color = Color(Game.INK, a)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	cv.draw_colored_polygon(PackedVector2Array([Vector2(tx - 1, y + ph - 2), Vector2(tx + 11, y + ph - 2), tip]), Color(Game.INK, a))
	cv.draw_style_box(sb, Rect2(x, y, pw, ph))
	cv.draw_colored_polygon(PackedVector2Array([Vector2(tx + 1, y + ph - 3), Vector2(tx + 9, y + ph - 3), tip + Vector2(0, -3)]), Color(Game.BONE, a))
	Paint.text(cv, Game.serif, Vector2(x + fs * 0.6, y + ph * 0.5), bubble["t"], fs, Color(Game.INK, a))
