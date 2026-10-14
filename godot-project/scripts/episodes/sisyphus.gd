extends EpisodeBase
## 第一集：西西弗斯再来一次（岗位：踹石神）

# ---------- geometry (recomputed from the stage size every frame) ----------
var gW := 0.0
var gH := 0.0
var yb := 0.0
var yt := 0.0
var x0 := 0.0
var x1 := 0.0
var gL := 1.0
var ux := 1.0
var uy := 0.0
var R := 12.0

# ---------- play state ----------
var st := "idle"          # push | roll | idle | strike | fpush
var f := 0.02             # boulder position along the slope, 0 = foot, 1 = summit
var vel := 0.0
var fs := 0.0             # Sisyphus's feet position along the slope
var timer := 0.0
var walk := 0.0
var walking := false
var stopped := false
var landed := false
var push_time := 5.6
var score := 0
var kicks := 0
var combo := 0
var despair := 15.0
var show_meter := false
var zen := false
var face := false
var sign_up := false
var book := {}
var finale := false
var burst_t := 0.0
var burst_checked := false
var kick_t := 0.0
var kick_from := "sky"
var kick_pt := Vector2.ZERO
var squash := 0.0
var wob := 0.0
var ri := 0
var left := 0
var lines := {}
var strike_t := 0.0
var strike_taps := 0
var strike_end := 0.0
var walk_decay := 0.0
var rb_t := 0.0
var habit := 0.9
var beh := {"hs": [], "let_top": 0, "strike_kicks": 0}

# ---------- HUD ----------
var kicks_lbl: Label
var score_lbl: Label
var meter_box: VBoxContainer
var mood_lbl: Label
var meter_bar: Control


func setup() -> void:
	ep_id = "sisyphus"
	ep_title = "西西弗斯再来一次"
	ep_subtitle = "诸神的差事 · 第一集"
	credit = "灵感来自希腊神话与加缪《西西弗斯神话》。"
	who = {"H": ["赫尔墨斯", "冥界人事部"], "S": ["西西弗斯", "受罚者"], "N": ["", ""]}


func build_hud() -> void:
	kicks_lbl = add_stat("踹了")
	score_lbl = add_stat("绩效")
	meter_box = VBoxContainer.new()
	meter_box.custom_minimum_size = Vector2(220, 0)
	meter_box.add_theme_constant_override("separation", 3)
	var top := HBoxContainer.new()
	var l := _label("绝望指数（KPI）", Game.sans, 11, Color(Game.INK, 0.75))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(l)
	mood_lbl = _label("心态很好", Game.serif, 13, Game.INK)
	top.add_child(mood_lbl)
	meter_box.add_child(top)
	meter_bar = Control.new()
	meter_bar.custom_minimum_size = Vector2(220, 14)
	meter_bar.draw.connect(_draw_meter)
	meter_box.add_child(meter_bar)
	var ends := HBoxContainer.new()
	var e0 := _label("0", Game.sans, 10, Color(Game.INK, 0.75))
	e0.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ends.add_child(e0)
	ends.add_child(_label("宙斯满意", Game.sans, 10, Color(Game.INK, 0.75)))
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(40, 0)
	ends.add_child(pad)
	meter_box.add_child(ends)
	meter_box.modulate.a = 0.0
	hud_box.add_child(meter_box)


func _draw_meter() -> void:
	var s := meter_bar.size
	var r := Rect2(0, 2, s.x, 10)
	meter_bar.draw_rect(r, Game.LIGHT)
	meter_bar.draw_rect(r, Game.INK, false, 2.0)
	meter_bar.draw_line(Vector2(s.x * 0.7, -3), Vector2(s.x * 0.7, 17), Game.INK, 2.0)
	var c := Vector2(s.x * despair / 100.0, 7)
	var d := PackedVector2Array([c + Vector2(0, -8), c + Vector2(8, 0), c + Vector2(0, 8), c + Vector2(-8, 0)])
	meter_bar.draw_colored_polygon(d, Game.BONE)
	var d2 := PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0)])
	meter_bar.draw_colored_polygon(d2, Game.INK)


func on_hud() -> void:
	kicks_lbl.text = str(kicks)
	score_lbl.text = str(score)
	meter_box.modulate.a = 1.0 if show_meter else 0.0
	var d := despair
	if zen:
		mood_lbl.text = "他很幸福" if d < 1.0 else "正在变幸福"
	elif d < 20.0:
		mood_lbl.text = "心态很好"
	elif d < 45.0:
		mood_lbl.text = "有点烦"
	elif d < 70.0:
		mood_lbl.text = "很沮丧"
	else:
		mood_lbl.text = "达标了"
	meter_bar.queue_redraw()


# ---------- the script ----------
func build_script() -> Array:
	return [
		{"t": "chapter", "n": "第一章", "title": "入职"},
		{"t": "say", "who": "H", "text": "恭喜你通过奥林匹斯公务员考试。"},
		{"t": "say", "who": "H", "text": "我是赫尔墨斯。冥界人事部、快递部、引魂部，都是我。"},
		{"t": "say", "who": "H", "text": "你的岗位是：踹石神。"},
		{"t": "say", "who": "H", "text": "下面那位叫西西弗斯。骗过死神，惹毛了宙斯，判的是无期。"},
		{"t": "say", "who": "H", "text": "他负责把石头推上山。你负责在他快到的时候，一脚踹下去。"},
		{"t": "say", "who": "H", "text": "点屏幕就是一脚。上一任踹了三千年，上周刚退休。去吧。"},
		{"t": "play", "rounds": 2, "hint": "点屏幕踹石头。等他快到山顶再踹。",
		 "lines": {"start": ["……新来的？", "嘿咻。"], "kicked": ["脚法不错。", "上一任比你温柔。"]}},

		{"t": "chapter", "n": "第二章", "title": "绩效"},
		{"t": "say", "who": "H", "text": "宙斯看了你的第一份周报。"},
		{"t": "say", "who": "H", "text": "他说“还行”。在奥林匹斯，“还行”的意思是重写。"},
		{"t": "do", "fn": func(): show_meter = true; on_hud()},
		{"t": "say", "who": "H", "text": "从今天起考核绝望指数，右上角那条。石头离山顶越近再踹，他越绝望。"},
		{"t": "say", "who": "H", "text": "他下山的路上会自己想开一点。所以，别给他太多时间。"},
		{"t": "say", "who": "S", "text": "你们神也有考核？"},
		{"t": "say", "who": "S", "text": "……那你们挺惨的。"},
		{"t": "play", "rounds": 3, "hint": "越接近山顶再踹，绝望指数涨得越多。",
		 "lines": {"start": ["你们有年假吗？", "绩效分几档？", "我当国王的时候，也给人打过绩效。"], "kicked": ["这脚算 A 还是 B？", "加油，争取评优。", "我帮你记着数呢。"]}},

		{"t": "chapter", "n": "第三章", "title": "石头先生"},
		{"t": "say", "who": "H", "text": "宙斯看了你的第二份周报。"},
		{"t": "say", "who": "H", "text": _review_ch3},
		{"t": "say", "who": "N", "text": "这段时间，西西弗斯在石头上画了一张脸。"},
		{"t": "do", "fn": func(): face = true; burst(center(f), 8); Game.sfx("pop")},
		{"t": "say", "who": "S", "text": "介绍一下，这是石头先生。"},
		{"t": "say", "who": "S", "text": "我们认识很多年了。踹它的时候，请轻一点。"},
		{"t": "play", "rounds": 3, "hint": "踹石头先生。",
		 "lines": {"start": ["石头先生，我们走。", "它今天心情不错。", "它说它想看看山顶。"], "kicked": ["石头先生！！", "它说它没事。", "它说你鞋带开了。"]}},

		{"t": "chapter", "n": "第四章", "title": "罢工"},
		{"t": "say", "who": "S", "text": "我和隔壁的坦塔罗斯商量过了。"},
		{"t": "say", "who": "S", "text": "我们成立了冥界受罚者工会。"},
		{"t": "say", "who": "S", "text": "从现在开始，罢工。"},
		{"t": "strike", "hint": "他坐下了。你可以踹踹看。"},
		{"t": "say", "who": "H", "text": "……"},
		{"t": "say", "who": "H", "text": "罢工申请已收到，已转交投诉处理部。"},
		{"t": "say", "who": "H", "text": "预计处理时长：永恒。"},
		{"t": "do", "fn": func(): st = "idle"; sign_up = false},
		{"t": "say", "who": "S", "text": "……那我先推着，等结果。"},
		{"t": "play", "rounds": 2, "hint": "工作照常。",
		 "lines": {"start": ["仲裁还没回音。", "工会刚开完会。"], "kicked": ["工会会记住这一脚的。", "我要申请仲裁。"]}},

		{"t": "chapter", "n": "第五章", "title": "一本书"},
		{"t": "say", "who": "N", "text": "天上掉下来一本书。"},
		{"t": "do", "fn": func(): book = {"x": maxf(R * 0.8, pt(fs)["p"].x - R * 0.9), "y": -30.0, "vy": 0.0, "landed": false}},
		{"t": "wait", "d": 1.6},
		{"t": "say", "who": "S", "text": "《西西弗斯神话》？写我的？"},
		{"t": "say", "who": "S", "text": "作者是个法国人。最后一句是……"},
		{"t": "say", "who": "S", "text": "“人们必须想象西西弗斯是幸福的。”"},
		{"t": "say", "who": "S", "text": "……"},
		{"t": "say", "who": "S", "text": "人家都这么写了，我总不能让读者失望。"},
		{"t": "do", "fn": func(): zen = true; Game.sfx("zen"); on_hud()},
		{"t": "play", "rounds": 3, "hint": "踹吧。",
		 "lines": {"start": ["今天天气真好～", "嘿咻～", "石头先生，再来一趟！"], "kicked": ["谢谢！", "好脚！", "再来再来！"]}},

		{"t": "chapter", "n": "第六章", "title": "调岗"},
		{"t": "say", "who": "H", "text": "宙斯看了这个月的报表。"},
		{"t": "say", "who": "H", "text": "绝望指数：零。"},
		{"t": "say", "who": "H", "text": "他把杯子摔了。金的。"},
		{"t": "say", "who": "H", "text": _review_ch6},
		{"t": "say", "who": "H", "text": "鉴于你的业绩，你被调岗了。新岗位：推石神。"},
		{"t": "do", "fn": func():
			finale = true; f = 0.02; fs = f - off(); st = "idle"; vel = 0.0
			burst(pt(fs)["p"] - Vector2(0, R), 10); Game.sfx("pop")},
		{"t": "say", "who": "S", "text": "别担心，踹石神的岗位我已经申请到了。"},
		{"t": "say", "who": "S", "text": "我会比上一任温柔的。"},
		{"t": "finale", "rounds": 3, "hint": "现在轮到你了。连点屏幕，把石头推上去。",
		 "lines": {"kicked": ["新来的？", "脚法还行吧？", "我给自己打 A。"]}},
		{"t": "end"},
	]


# Zeus reacts to how you actually played, at the two review beats that already exist.
func _review_ch3() -> String:
	var hs: Array = beh["hs"]
	var avg := 0.0
	var early := 0
	for h in hs:
		avg += h
		if h < 0.35:
			early += 1
	if hs.size() > 0:
		avg /= hs.size()
	if beh["let_top"] > 0:
		return "他问为什么有一次让他推上去了。我说那是压力测试。"
	if hs.size() > 0 and early >= hs.size() / 2.0:
		return "他说你踹得太早了。这叫没耐心，不叫惩罚。"
	if avg > 0.8:
		return "他说你踹得很准。准到他有点担心你。"
	return "他说“还行”的时候，语气缓和了一点。" if despair >= 55.0 else "他说，再这样就调你去看守坦塔罗斯的葡萄。"


func _review_ch6() -> String:
	var hs: Array = beh["hs"]
	var late := hs.filter(func(h): return h > 0.85).size()
	var early := hs.filter(func(h): return h < 0.35).size()
	if beh["let_top"] >= 2:
		return "他还注意到，你放他登顶了 %d 次。他说你这是在培养他。" % beh["let_top"]
	if hs.size() > 0 and late >= hs.size() * 0.6:
		return "不过他承认，你每一脚都踹在离山顶一步的地方。手艺不错，适合去推。"
	if hs.size() > 0 and early >= hs.size() * 0.6:
		return "他说你每次都踹得太早，西西弗斯连绝望的机会都没有。"
	if beh["strike_kicks"] >= 3:
		return "他还特别提到：罢工期间，你踹了三脚工会财产。"
	return "他说你干得不好也不坏，这是最难处理的那种。"


# ---------- state ----------
func reset_state() -> void:
	geo()
	st = "idle"; f = 0.02; vel = 0.0; fs = f - off(); timer = 0.0; walk = 0.0
	walking = false; stopped = false; landed = false; push_time = 5.6
	score = 0; kicks = 0; combo = 0; despair = 15.0; show_meter = false; zen = false
	face = false; sign_up = false; book = {}; finale = false; burst_t = 0.0; burst_checked = false
	kick_t = 0.0; kick_from = "sky"; squash = 0.0; wob = 0.0; ri = 0; left = 0; lines = {}
	strike_t = 0.0; strike_taps = 0; strike_end = 0.0; walk_decay = 0.0; rb_t = 0.0; habit = 0.9
	beh = {"hs": [], "let_top": 0, "strike_kicks": 0}


func skip_fix(_target: int, rounds: int) -> void:
	if not book.is_empty():
		book["y"] = yb
		book["landed"] = true
	push_time = maxf(2.4, 5.6 * pow(0.95, rounds))


func add_despair(d: float) -> void:
	despair = clampf(despair + d, 0.0, 100.0)


# ---------- geometry ----------
func geo() -> void:
	gW = stage.size.x
	gH = stage.size.y
	var bd := band()
	yb = gH - bd * 1.6 - gH * 0.08
	yt = maxf(bd * 2.6 + gH * 0.12, gH * 0.3)
	R = unit()
	x0 = maxf(gW * 0.15, R * 5.6)
	x1 = gW * 0.8
	var dx := x1 - x0
	var dy := yb - yt
	gL = maxf(1.0, sqrt(dx * dx + dy * dy))
	ux = dx / gL
	uy = -dy / gL


func pt(t: float) -> Dictionary:
	var s := t * gL
	if s <= 0.0:
		return {"p": Vector2(x0 + s, yb), "u": Vector2(1, 0)}
	if s >= gL:
		return {"p": Vector2(x1 + (s - gL), yt), "u": Vector2(1, 0)}
	return {"p": Vector2(x0 + ux * s, yb + uy * s), "u": Vector2(ux, uy)}


func center(t: float) -> Vector2:
	var q := pt(t)
	var u: Vector2 = q["u"]
	return q["p"] + Vector2(u.y * R, -u.x * R)


func off() -> float:
	return R * 3.0 / gL


func fmin() -> float:
	return minf(0.0, -(x0 - R * 4.4) / gL)


# ---------- steps ----------
func custom_step(s: Dictionary) -> bool:
	match s["t"]:
		"play":
			set_hint(s["hint"]); left = s["rounds"]; ri = 0; lines = s["lines"]; combo = 0
			start_push()
		"strike":
			set_hint(s["hint"]); st = "strike"; sign_up = true; strike_t = 0.0; strike_taps = 0; strike_end = 0.0
			say("S", "罢工中。", 2.2)
		"finale":
			set_hint(s["hint"]); left = s["rounds"]; ri = 0; lines = s["lines"]; learn_habit(); st = "fpush"
		_:
			return false
	return true


func end_texts() -> Dictionary:
	return {"text": "你在踹石神任上踹了 %d 脚，绩效 %d。现在，你也有了一块自己的石头。" % [kicks, score],
		"quote": "我们必须想象诸神也是幸福的。"}


func next_episode() -> String:
	return "prometheus"


# ---------- actions ----------
func start_push() -> void:
	st = "push"; burst_checked = false
	push_time = maxf(2.4, push_time * 0.95)
	if lines.has("start"):
		var a: Array = lines["start"]
		say("S", a[ri % a.size()], 1.5)


func kick() -> void:
	if st != "push":
		return
	var h := maxf(0.0, f)
	st = "roll"; vel = -(0.55 + 0.55 * h); timer = 0.0; kick_t = 0.38; kick_from = "sky"
	shake = 0.22; squash = 1.0; stopped = false; landed = false; walk_decay = 0.0
	var c := center(f)
	burst(c, 10)
	Game.sfx("kick")
	kicks += 1
	beh["hs"].append(h)
	var pts := 0
	var label := ""
	var d := 0.0
	if h < 0.35 and not zen:
		pts = 1 if h < 0.2 else int(round(h * h * 100))
		combo = 0
		label = ("太早了" if h < 0.2 else "还行") + "  +%d" % pts
		d = -4
		say("S", ["这么急？", "我还没出汗呢。", "你是不是手滑了？"].pick_random())
	else:
		pts = maxi(1, int(round(h * h * 100)))
		if h > 0.85:
			combo += 1
			pts *= 1 + combo
			label = "近在咫尺 ×%d  +%d" % [1 + combo, pts]
		else:
			combo = 0
			label = ("希望破灭" if h > 0.6 else "还行") + "  +%d" % pts
		d = round(16 * h * h * (1 + 0.25 * maxi(0, combo - 1)))
		var k: Array = lines["kicked"]
		say("S", k[ri % k.size()])
	if zen:
		d = 0
	score += pts
	popup(c - Vector2(0, R * 1.4), label, 1.3, h > 0.85)
	if show_meter:
		add_despair(d)
		popup(c - Vector2(0, R * 0.4), "绝望 %s%d" % ["+" if d >= 0 else "−", absi(int(d))], 1.3, false, true, d > 0)
	on_hud()


func sis_kick() -> void:
	var c := center(f)
	st = "roll"; vel = -1.0; timer = 0.0; kick_t = 0.38; kick_from = "sis"
	kick_pt = c + Vector2(R * 0.55, -R * 0.7)
	shake = 0.2; squash = 1.0; stopped = false; landed = false
	burst(c, 10)
	Game.sfx("kick")
	var k: Array = lines["kicked"]
	say("S", habit_line() if ri == 0 else k[ri % k.size()], 2.0)
	if ri == 0 and beh["hs"].size() > 0:
		popup(c - Vector2(0, R * 2.2), "他用的是你的踹法", 1.8, false, true)


## Letting him reach the top is a valid (if cruel) way to play: it rolls back and still counts as a round.
func rollback() -> void:
	beh["let_top"] += 1
	f = 0.02; fs = f - off(); flash = 0.6; combo = 0; st = "idle"
	popup(Vector2(gW / 2, gH * 0.45), "检测到违规登顶 · 已回滚", 1.8, true)
	say("S", "又回滚？" if beh["let_top"] > 1 else "啊？？", 1.4)
	Game.sfx("pop")
	if show_meter and not zen:
		add_despair(6)
		on_hud()
	rb_t = 1.4


## The habit he learned from you: the median height of your kicks.
func learn_habit() -> void:
	var hs: Array = beh["hs"].filter(func(h): return h > 0.0)
	hs.sort()
	habit = clampf(hs[hs.size() / 2], 0.45, 0.9) if hs.size() > 0 else 0.9


func habit_line() -> String:
	if beh["hs"].is_empty():
		return "新来的？"
	if habit < 0.6:
		return "你以前就是这么早踹我的。"
	if habit >= 0.85:
		return "差一步再踹。跟你学的。"
	return "我学的是你的节奏。"


func round_done() -> void:
	ri += 1
	left -= 1
	if step["t"] == "play":
		if left > 0:
			start_push()
		else:
			st = "idle"
			next()
	elif step["t"] == "finale":
		if left > 0:
			st = "fpush"
		else:
			st = "idle"
			next()


func strike_tap() -> void:
	if kick_t > 0.0 or strike_end > 0.0:
		return
	kick_t = 0.38; kick_from = "sky"; wob = 0.5; shake = 0.12
	Game.sfx("kick")
	strike_taps += 1
	beh["strike_kicks"] = strike_taps
	burst(center(f), 6)
	say("S", ["它已经在山脚了。", "再踹也还是山脚。", "你踹的是工会财产。"][mini(strike_taps - 1, 2)], 1.6)
	if strike_taps >= 3:
		strike_end = 1.6


func custom_tap(s: Dictionary, _pos) -> void:
	match s["t"]:
		"play":
			kick()
		"strike":
			strike_tap()
		"finale":
			if st == "fpush":
				f = minf(0.93, f + 0.055)
				walk += 1.1
				Game.sfx("step")


# ---------- update ----------
func custom_update(dt: float) -> void:
	geo()
	if rb_t > 0.0:
		rb_t -= dt
		if rb_t <= 0.0:
			round_done()
	if step.get("t", "") == "strike":
		strike_t += dt
		if strike_end > 0.0:
			strike_end -= dt
			if strike_end <= 0.0:
				next()
		elif strike_t > 9.0:
			next()
	if not book.is_empty() and not book["landed"]:
		book["vy"] += 900.0 * dt
		book["y"] += book["vy"] * dt
		if book["y"] >= yb:
			book["y"] = yb
			book["landed"] = true
			burst(Vector2(book["x"], yb), 10)
			shake = 0.12
			Game.sfx("land")
			say("S", "？", 1.2)
	if zen and despair > 0.0:
		despair = maxf(0.0, despair - 30.0 * dt)
		on_hud()

	if st == "push":
		var sp := 1.0 / push_time * (0.85 + 0.3 * f)
		if burst_t > 0.0:
			sp *= 2.3
			burst_t -= dt
		f += sp * dt
		fs = f - off()
		walk += dt * (5.0 + sp * 30.0)
		if not burst_checked and f > 0.42:
			burst_checked = true
			if kicks >= 5 and not zen and randf() < 0.35:
				burst_t = 0.6
				say("S", "冲啊！", 1.0)
		if f >= 1.0:
			rollback()
	elif st == "fpush":
		f = maxf(0.02, f - 0.035 * dt)
		fs = f - off()
		if f >= habit:
			sis_kick()
	elif st == "roll":
		var was_up := f > 0.0
		if f > 0.0:
			vel -= 2.0 * dt
		else:
			vel *= pow(0.12, dt)
			if absf(vel) < 0.02:
				vel = 0.0
				stopped = true
		f += vel * dt
		if was_up and f <= 0.0 and not landed:
			landed = true
			burst(center(0.0) + Vector2(0, R), 14)
			shake = 0.18
			Game.sfx("land")
		if f < fmin():
			f = fmin()
			vel = -vel * 0.3
		timer += dt
		squash = maxf(0.0, squash - dt * 1.4)
		if timer > (0.5 if ri > 0 else 0.85):
			var target := f - off()
			if fs > target + 0.001:
				fs = maxf(target, fs - (0.8 if ri > 0 else 0.42) * dt)
				walk += dt * 10.0
				walking = true
				if show_meter and not zen and not finale:
					add_despair(-1.8 * dt)
					walk_decay += 1.8 * dt
					on_hud()
			else:
				walking = false
				if stopped:
					if walk_decay >= 1.0 and heads.has("S"):
						popup(heads["S"] - Vector2(0, R * 1.2), "下山想开了 −%d" % roundi(walk_decay), 1.2, false, true)
						walk_decay = 0.0
					round_done()
	kick_t = maxf(0.0, kick_t - dt)
	wob = maxf(0.0, wob - dt)


# ---------- drawing ----------
func draw_scene(cv: CanvasItem) -> void:
	geo()
	_scene(cv)
	_book(cv)
	_actors(cv)
	_boulder(cv)
	_foot(cv)
	xf_reset(cv)
	# the multiplier line on the slope
	if step.get("t", "") == "play" and st == "push" and show_meter and not zen:
		var q: Vector2 = pt(0.85)["p"]
		var tip := q + Vector2(uy * R * 3.2, -ux * R * 3.2)
		cv.draw_dashed_line(q, tip, Game.INK, 1.5, 4.0)
		Paint.text(cv, Game.serif, q + Vector2(uy * R * 3.8, -ux * R * 3.8), "倍率线", int(maxf(11.0, R * 0.45)), Game.INK, 0)


func _scene(cv: CanvasItem) -> void:
	var bd := band()
	Paint.radial_bg(cv, Vector2(gW, gH), Vector2(gW * 0.6, gH * 0.3), Game.LIGHT, Game.CLAY)
	Paint.meander(cv, gW, bd * 0.5, bd, Game.INK)
	var hill := PackedVector2Array([Vector2(-5, gH), Vector2(-5, yb), Vector2(x0, yb), Vector2(x1, yt), Vector2(gW + 5, yt), Vector2(gW + 5, gH)])
	cv.draw_colored_polygon(hill, Game.DEEP)
	# incised strata
	for k in range(1, 7):
		var d := k * R * 0.9
		Paint.polyline(cv, PackedVector2Array([Vector2(-5, yb + d), Vector2(x0 + d * 0.4, yb + d), Vector2(x1 + d * 0.4, yt + d), Vector2(gW + 5, yt + d)]), Game.CLAY, 1.5, false)
	Paint.polyline(cv, PackedVector2Array([Vector2(-5, yb), Vector2(x0, yb), Vector2(x1, yt), Vector2(gW + 5, yt)]), Game.INK, 4.0)
	# the column at the summit
	var cx := x1 + (gW - x1) * 0.62
	var cw := minf(R * 0.9, (gW - x1) * 0.25)
	var ch := R * 3.2
	cv.draw_rect(Rect2(cx - cw * 0.5, yt - ch, cw, ch), Game.INK)
	cv.draw_rect(Rect2(cx - cw * 0.9, yt - ch - cw * 0.35, cw * 1.8, cw * 0.35), Game.INK)
	cv.draw_rect(Rect2(cx - cw * 0.8, yt - cw * 0.25, cw * 1.6, cw * 0.25), Game.INK)
	for i in [-1, 0, 1]:
		cv.draw_line(Vector2(cx + i * cw * 0.22, yt - ch + 3), Vector2(cx + i * cw * 0.22, yt - cw * 0.3), Game.CLAY, 1.0)
	_sprig(cv, x0 * 0.3, yb)
	cv.draw_rect(Rect2(0, gH - bd * 1.1, gW, bd * 1.1), Game.INK)
	cv.draw_line(Vector2(0, gH - bd * 0.7), Vector2(gW, gH - bd * 0.7), Game.CLAY, 1.5)


func _sprig(cv: CanvasItem, x: float, y: float) -> void:
	Paint.polyline(cv, Paint.quad_pts(Vector2(x, y), Vector2(x + 4, y - R * 1.2), Vector2(x - 2, y - R * 2)), Game.INK, 2.0, false)
	for i in range(1, 5):
		var t := i / 5.0
		var px := x + sin(t * 3) * 3
		var py := y - R * 2 * t
		Paint.ellipse(cv, Vector2(px + (6 if i % 2 else -6), py), 5, 2, -0.5 if i % 2 else 0.5, Game.INK)


func _book(cv: CanvasItem) -> void:
	if book.is_empty():
		return
	var w := R * 1.1
	var h := R * 0.32
	xf(cv, Vector2(book["x"], book["y"]), 0.0 if book["landed"] else phase * 6.0)
	cv.draw_rect(Rect2(-w / 2, -h, w, h), Game.INK)
	cv.draw_rect(Rect2(-w / 2 + 2, -h + 2, w - 4, h * 0.35), Game.BONE)
	xf_reset(cv)


func _boulder(cv: CanvasItem) -> void:
	var c := center(f)
	var ang := f * gL / R
	var wx := sin(wob * 40.0) * wob * 6.0 if wob > 0.0 else 0.0
	xf(cv, c + Vector2(wx, 0), ang)
	cv.draw_circle(Vector2.ZERO, R, Game.INK)
	if face:
		cv.draw_circle(Vector2(-R * 0.32, -R * 0.2), R * 0.1, Game.BONE)
		cv.draw_circle(Vector2(R * 0.32, -R * 0.2), R * 0.1, Game.BONE)
		if st == "roll" and timer < 1.2:
			cv.draw_polyline(Paint.ellipse_pts(Vector2(0, R * 0.3), R * 0.18, R * 0.22), Game.BONE, 2.0, true)
		else:
			Paint.arc(cv, Vector2(0, R * 0.08), R * 0.42, 0.35, PI - 0.35, Game.BONE, 2.0)
	else:
		Paint.arc(cv, Vector2.ZERO, R * 0.62, 0.2, 2.6, Game.CLAY, 1.6)
		Paint.arc(cv, Vector2(R * 0.12, -R * 0.05), R * 0.32, 3.0, 5.4, Game.CLAY, 1.6)
		cv.draw_line(Vector2(-R * 0.7, -R * 0.35), Vector2(-R * 0.45, -R * 0.55), Game.CLAY, 1.6)
	xf_reset(cv)


## A black-figure body. o: pose push|stand|walk|sit|kick, face, arms side|head|behind|swing,
## beard, wreath, mood smile|frown|flat, sweat, notes, sign, target, squash. Returns the head position.
func _figure(cv: CanvasItem, o: Dictionary) -> Vector2:
	var F: Vector2 = o["F"]["p"]
	var u: Vector2 = o["F"]["u"]
	var h := R * 2.7
	var lw := h * 0.07
	var sw := sin(o.get("walk", 0.0))
	var fc: float = o.get("face", 1)
	var hip: Vector2
	var sh: Vector2
	var head: Vector2
	var hands: Array
	var feet: Array
	var bends: Array
	var pose: String = o.get("pose", "stand")
	if pose == "push":
		var b := center(f)
		var hand := Vector2(b.x - u.x * R * 0.92, b.y - u.y * R * 0.92 - R * 0.1)
		hip = Vector2(F.x - u.x * h * 0.15, F.y - u.y * h * 0.15 - h * 0.42)
		var dv := (hand - hip).normalized()
		sh = hip + dv * h * 0.32
		head = sh + dv * h * 0.11 - Vector2(0, h * 0.07)
		hands = [hand, Vector2(hand.x + u.x * 2, hand.y + R * 0.25)]
		var stp := h * 0.16
		feet = [F + u * stp * sw, F - u * stp * sw - u * h * 0.08]
		var kb := Vector2(u.x * h * 0.07, -h * 0.03)
		bends = [kb, kb]
		fc = 1
	elif pose == "sit":
		hip = Vector2(F.x, F.y - h * 0.16)
		sh = Vector2(hip.x - h * 0.02, hip.y - h * 0.32)
		head = Vector2(sh.x + h * 0.02, sh.y - h * 0.13)
		feet = [Vector2(F.x + h * 0.3, F.y), Vector2(F.x + h * 0.25, F.y)]
		bends = [Vector2(0, -h * 0.17), Vector2(0, -h * 0.15)]
		var sg := Vector2(sh.x + h * 0.15, sh.y - h * 0.02)
		hands = [sg, Vector2(hip.x + h * 0.17, hip.y - h * 0.15)]
		fc = 1
		if o.get("sign", false):
			Paint.line(cv, Vector2(sg.x, sg.y + h * 0.15), Vector2(sg.x, sg.y - h * 0.42), Game.INK, h * 0.035)
			var bw := h * 0.5
			var bh := h * 0.24
			var br := Rect2(sg.x - bw / 2, sg.y - h * 0.42 - bh, bw, bh)
			cv.draw_rect(br, Game.BONE)
			cv.draw_rect(br, Game.INK, false, 2.0)
			Paint.text(cv, Game.serif_black, br.get_center(), "罢工", int(maxf(10.0, bh * 0.62)), Game.INK, 0)
	elif pose == "kick":
		fc = -1
		hip = Vector2(F.x, F.y - h * 0.45)
		sh = Vector2(hip.x + h * 0.07, hip.y - h * 0.3)
		head = Vector2(sh.x + h * 0.01, sh.y - h * 0.13)
		feet = [Vector2(F.x + h * 0.04, F.y), o["target"]]
		bends = [Vector2(h * 0.03, 0), Vector2(h * 0.02, -h * 0.06)]
		hands = [Vector2(sh.x + h * 0.22, sh.y - h * 0.12), Vector2(sh.x - h * 0.08, sh.y - h * 0.24)]
	else:
		var walking_ := pose == "walk"
		var bob := absf(sw) * h * 0.02 if walking_ else 0.0
		hip = Vector2(F.x, F.y - h * 0.45 - bob)
		sh = Vector2(hip.x, hip.y - h * 0.32)
		head = Vector2(sh.x + fc * h * 0.02, sh.y - h * 0.13)
		var stp := h * 0.15 * sw if walking_ else h * 0.07
		feet = [F + u * stp, F - u * stp]
		var kb := Vector2(fc * h * 0.04, 0)
		bends = [kb, kb]
		match o.get("arms", "side"):
			"head":
				hands = [Vector2(sh.x - h * 0.12, sh.y - h * 0.22), Vector2(head.x + h * 0.02, head.y + h * 0.02)]
			"behind":
				hands = [Vector2(sh.x - fc * h * 0.1, head.y + h * 0.03), Vector2(sh.x + fc * h * 0.16 * sw, sh.y + h * 0.28)]
			"swing":
				hands = [Vector2(sh.x + fc * h * 0.14 * sw, sh.y + h * 0.3), Vector2(sh.x - fc * h * 0.14 * sw, sh.y + h * 0.3)]
			_:
				var bb := sin(phase * 1.5) * h * 0.01
				hands = [Vector2(sh.x - h * 0.15, sh.y + h * 0.27 + bb), Vector2(sh.x + h * 0.15, sh.y + h * 0.27 - bb)]
	# squash (when the boulder flattens him) scales about the feet
	var sq: float = o.get("squash", 0.0)
	var S_ := Vector2.ONE
	if sq > 0.0:
		var k := 1.0 - 0.72 * minf(1.0, sq * 1.3)
		S_ = Vector2(1.0 + 0.4 * (1.0 - k), k)
	var T := func(p: Vector2) -> Vector2: return F + (p - F) * S_
	for i in feet.size():
		Paint.limb(cv, T.call(hip), T.call(feet[i]), bends[i] * S_, Game.INK, lw)
	Paint.line(cv, T.call(hip), T.call(sh), Game.INK, h * 0.12)
	cv.draw_line(T.call(hip + Vector2(-h * 0.05, -h * 0.03)), T.call(hip + Vector2(h * 0.05, -h * 0.06)), Game.CLAY, 1.2)
	for hd in hands:
		Paint.limb(cv, T.call(sh), T.call(hd), Vector2(0, h * 0.04) * S_, Game.INK, lw)
	head = T.call(head)
	cv.draw_circle(head, h * 0.085, Game.INK)
	if o.get("beard", true):
		cv.draw_colored_polygon(PackedVector2Array([head + Vector2(fc * h * 0.02, h * 0.04), head + Vector2(fc * h * 0.1, h * 0.12), head + Vector2(fc * h * 0.08, h * 0.02)]), Game.INK)
	cv.draw_circle(head + Vector2(fc * h * 0.04, -h * 0.015), maxf(1.0, h * 0.012), Game.CLAY)
	var m := head + Vector2(fc * h * 0.045, h * 0.035)
	var mr := h * 0.025
	var mw := maxf(1.0, h * 0.012)
	match o.get("mood", "flat"):
		"smile":
			Paint.arc(cv, m - Vector2(0, mr * 0.6), mr, 0.3, PI - 0.3, Game.CLAY, mw)
		"frown":
			Paint.arc(cv, m + Vector2(0, mr * 0.9), mr, PI + 0.4, TAU - 0.4, Game.CLAY, mw)
		_:
			cv.draw_line(m - Vector2(mr * 0.8, 0), m + Vector2(mr * 0.8, 0), Game.CLAY, mw)
	if o.get("wreath", false):
		for i in 5:
			var a := PI * (1.1 + i * 0.2)
			Paint.ellipse(cv, head + Vector2(cos(a), sin(a)) * h * 0.09, h * 0.035, h * 0.015, a + PI / 2, Game.BONE)
	if o.get("sweat", false):
		var t := fmod(phase * 2.0, 1.0)
		Paint.ellipse(cv, head + Vector2(-fc * h * 0.1, -h * 0.04 + t * h * 0.15), 1.6, 2.6, 0.0, Color(Game.BONE, 1.0 - t))
	if o.get("notes", false):
		for i in 2:
			var t := fmod(phase * 0.8 + i * 0.5, 1.0)
			Paint.text(cv, Game.serif, head + Vector2(fc * h * (0.14 + t * 0.15), -h * (0.05 + t * 0.3)), "♫" if i else "♪", int(maxf(11.0, h * 0.16)), Color(Game.INK, 1.0 - t))
	return head


func _mood() -> String:
	if zen:
		return "smile"
	if despair >= 60.0 and show_meter:
		return "frown"
	return "flat"


func _actors(cv: CanvasItem) -> void:
	if finale:
		var pushing := st == "fpush"
		_figure(cv, {"F": pt(fs), "pose": "push" if pushing else ("walk" if walking else "stand"), "face": -1 if walking else 1,
			"walk": walk, "arms": "swing" if walking else "head", "beard": false, "wreath": true,
			"mood": "frown" if pushing and f > 0.6 else "flat", "sweat": pushing and f > 0.5, "squash": squash if st == "roll" else 0.0})
		var kicking := kick_t > 0.08 and kick_from == "sis"
		heads["S"] = _figure(cv, {"F": {"p": Vector2(x1 + R * 1.1, yt), "u": Vector2(1, 0)}, "pose": "kick" if kicking else "stand",
			"face": -1, "target": kick_pt, "arms": "side", "mood": "smile", "notes": not kicking and st != "fpush"})
		return
	var o := {}
	if st == "push":
		o = {"pose": "push", "sweat": f > 0.6 and not zen}
	elif st == "strike":
		o = {"pose": "sit", "sign": sign_up}
	elif st == "roll":
		if walking:
			o = {"pose": "walk", "face": -1, "arms": "behind" if zen else "swing", "notes": zen}
		else:
			o = {"pose": "stand", "arms": "side" if zen else "head", "squash": squash}
	else:
		o = {"pose": "stand", "arms": "side", "notes": zen}
	o["F"] = pt(fs)
	o["walk"] = walk
	o["mood"] = _mood()
	heads["S"] = _figure(cv, o)


func _foot(cv: CanvasItem) -> void:
	if kick_t <= 0.0 or kick_from != "sky":
		return
	var t := 1.0 - kick_t / 0.38
	var reach := t / 0.35 if t < 0.35 else (1.0 if t < 0.6 else 1.0 - (t - 0.6) / 0.4)
	var c := center(maxf(f, 0.0))
	var tip := c + Vector2(R * 1.15, -R * 0.35)
	var far := tip + Vector2(R * 5, -R * 6)
	var e := 1.0 - pow(1.0 - reach, 3)
	var p := far.lerp(tip, e)
	Paint.line(cv, p + Vector2(R * 7, -R * 8), p + Vector2(R * 0.6, -R * 0.8), Game.INK, R * 0.8)
	Paint.ellipse(cv, p, R * 0.95, R * 0.42, -0.75, Game.INK)
	for i in 3:
		cv.draw_line(p + Vector2(R * (0.5 + i * 0.5), -R * (0.5 + i * 0.6) - R * 0.3), p + Vector2(R * (0.9 + i * 0.5), -R * (0.1 + i * 0.6) - R * 0.3), Game.CLAY, 1.5)
	if t < 0.45:
		for i in 5:
			var a := PI * 0.9 + i * 0.25
			cv.draw_line(c + Vector2(cos(a), sin(a)) * R * 1.4, c + Vector2(cos(a), sin(a)) * R * 2.1, Game.INK, 2.0)
