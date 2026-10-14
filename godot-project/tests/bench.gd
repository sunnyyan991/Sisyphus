extends Node
## Measures frame time on the menu and in an episode. Env: WHAT=menu|episode
var t := 0.0
var frames := 0
var acc := 0.0
var draws := 0.0
var ep

func _ready() -> void:
	Game.sound_on = false
	if OS.get_environment("WHAT") == "episode":
		Game.start_chapter = 2
		ep = load("res://scenes/sisyphus.tscn").instantiate()
	else:
		ep = load("res://scenes/menu.tscn").instantiate()
	add_child(ep)

func _process(dt: float) -> void:
	t += dt
	if ep is EpisodeBase:
		var s: String = ep.step.get("t", "")
		if s == "say":
			if ep.typing: ep.finish_typing()
			else: ep.tap(null)
		elif s == "chapter" and ep.chap_t > 0.3:
			ep.tap(null)
	if t > 1.0:
		frames += 1
		acc += dt
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	if t > 6.0:
		print("BENCH %s fps=%.1f draw_calls=%.0f process_ms=%.2f" % [OS.get_environment("WHAT"), frames / acc, draws / frames, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
		get_tree().quit()
		set_process(false)
