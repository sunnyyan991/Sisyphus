class_name Paint
## Drawing helpers for the black-figure style. Every function draws onto the given CanvasItem.


static func line(cv: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float, round_caps := true) -> void:
	cv.draw_line(a, b, col, w, true)
	if round_caps and w > 2.5:
		cv.draw_circle(a, w * 0.5, col)
		cv.draw_circle(b, w * 0.5, col)


static func polyline(cv: CanvasItem, pts: PackedVector2Array, col: Color, w: float, round_joints := true) -> void:
	if pts.size() < 2:
		return
	cv.draw_polyline(pts, col, w, true)
	if round_joints and w > 2.5:
		for p in pts:
			cv.draw_circle(p, w * 0.5, col)


## A two-segment limb from a to b, bent at the middle.
static func limb(cv: CanvasItem, a: Vector2, b: Vector2, bend: Vector2, col: Color, w: float) -> void:
	var m := (a + b) * 0.5 + bend
	polyline(cv, PackedVector2Array([a, m, b]), col, w)


static func ellipse_pts(c: Vector2, rx: float, ry: float, rot := 0.0, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func ellipse(cv: CanvasItem, c: Vector2, rx: float, ry: float, rot: float, col: Color) -> void:
	cv.draw_colored_polygon(ellipse_pts(c, rx, ry, rot), col)


static func arc(cv: CanvasItem, c: Vector2, r: float, a0: float, a1: float, col: Color, w: float) -> void:
	cv.draw_arc(c, r, a0, a1, 24, col, w, true)


static func quad_pts(p0: Vector2, p1: Vector2, p2: Vector2, n := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		pts.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return pts


static func cubic_pts(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, n := 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		pts.append(p0.bezier_interpolate(p1, p2, p3, float(i) / n))
	return pts


static func text_width(font: Font, s: String, size: int) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Draws text with its baseline centred vertically on pos.y. align: -1 left, 0 centre, 1 right.
static func text(cv: CanvasItem, font: Font, pos: Vector2, s: String, size: int, col: Color, align := -1, outline := 0, outline_col := Color.BLACK) -> void:
	var w := text_width(font, s, size)
	var x := pos.x
	if align == 0:
		x -= w * 0.5
	elif align == 1:
		x -= w
	var y := pos.y + (font.get_ascent(size) - font.get_descent(size)) * 0.5
	if outline > 0:
		cv.draw_string_outline(font, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, outline_col)
	cv.draw_string(font, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## The Greek key band along the top of a painted panel.
static func meander(cv: CanvasItem, width: float, y: float, h: float, col: Color) -> void:
	var lw := maxf(2.0, h * 0.14)
	var x := 0.0
	while x < width + h:
		polyline(cv, PackedVector2Array([
			Vector2(x, y + h), Vector2(x, y), Vector2(x + h * 0.8, y), Vector2(x + h * 0.8, y + h * 0.62),
			Vector2(x + h * 0.38, y + h * 0.62), Vector2(x + h * 0.38, y + h * 0.32)]), col, lw, false)
		x += h
	cv.draw_line(Vector2(0, y + h), Vector2(width, y + h), col, lw)


static var _radial_cache := {}


## A smooth radial gradient filling the rect, brightest at centre (given as a fraction of size).
static func radial_bg(cv: CanvasItem, size: Vector2, centre: Vector2, inner: Color, outer: Color) -> void:
	var key := "%s-%s" % [inner.to_html(), outer.to_html()]
	if not _radial_cache.has(key):
		var g := Gradient.new()
		g.set_color(0, inner)
		g.set_color(1, outer)
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 256
		tex.height = 256
		_radial_cache[key] = tex
	var r := size.length() * 0.8
	cv.draw_rect(Rect2(Vector2.ZERO, size), outer)
	cv.draw_texture_rect(_radial_cache[key], Rect2(centre - Vector2(r, r), Vector2(r, r) * 2.0), false)
