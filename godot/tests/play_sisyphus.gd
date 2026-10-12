extends Node
## Automated player for 第一集. Env: STYLE=late|early|top, CH=start chapter, SHOTS=dir for screenshots.

var ep
var t := 0.0
var style := "late"
var shots := ""
var last_si := -1
var shot_i := 0
var said: Array[String] = []
var finale_kicks := []
var prev_st := ""


func _ready() -> void:
	style = OS.get_environment("STYLE") if OS.get_environment("STYLE") != "" else "late"
	shots = OS.get_environment("SHOTS")
	Game.start_chapter = int(OS.get_environment("CH")) if OS.get_environment("CH") != "" else 1
	Game.sound_on = false
	Engine.time_scale = 3.0
	ep = load("res://scenes/sisyphus.tscn").instantiate()
	add_child(ep)


func _shot(tag: String) -> void:
	if shots == "":
		return
	await RenderingServer.frame_post_draw
	shot_i += 1
	get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [shots, shot_i, tag])


func _process(dt: float) -> void:
	t += dt
	if ep.finished or t > 600.0:
		await get_tree().create_timer(1.0).timeout
		_shot("end")
		await get_tree().create_timer(0.3).timeout
		print("RESULT style=%s finished=%s kicks=%d score=%d let_top=%d habit=%.2f" % [style, ep.finished, ep.kicks, ep.score, ep.beh["let_top"], ep.habit])
		for s in said:
			print("  H: ", s)
		print("  finale kicks: ", finale_kicks)
		get_tree().quit()
		set_process(false)
		return
	var s: String = ep.step.get("t", "")
	if ep.si != last_si:
		last_si = ep.si
		if s == "say" and ep.step["who"] == "H":
			var tx = ep.step["text"]
			if tx is Callable:
				said.append(tx.call())
		if s in ["play", "strike", "finale", "chapter"]:
			_shot(s)
	if s == "finale" and prev_st == "fpush" and ep.st == "roll":
		finale_kicks.append(snappedf(ep.f, 0.01))
		_shot("finale_kick")
	prev_st = ep.st
	match s:
		"say":
			if ep.typing:
				ep.finish_typing()
			else:
				ep.tap(null)
		"chapter":
			if ep.chap_t > 0.6:
				ep.tap(null)
		"play":
			if ep.st == "push":
				var target := 0.9
				if style == "early":
					target = 0.3
				elif style == "top":
					target = 2.0 if ep.ri % 2 == 0 else 0.88
				if ep.f >= target:
					ep.tap(null)
					if ep.kicks == 4:
						_shot("kick")
		"strike":
			ep.tap(null)
		"finale":
			if ep.st == "fpush" and fmod(t, 0.15) < dt:
				ep.tap(null)
