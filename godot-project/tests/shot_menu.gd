extends Node
## Renders the main menu, with fake progress, and saves screenshots.

func _ready() -> void:
	var shots := OS.get_environment("SHOTS")
	Game.progress = {"sisyphus": {"seen": [1, 2, 3, 4, 5, 6], "done": true}, "prometheus": {"seen": [1, 2, 3, 4], "done": false}, "trolley": {"seen": [1, 2, 3, 4], "done": false}}
	if OS.get_environment("FRESH") != "":
		Game.progress = {}
	Game.menu_sel = int(OS.get_environment("SEL")) if OS.get_environment("SEL") != "" else 0
	var m = load("res://scenes/menu.tscn").instantiate()
	add_child(m)
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots + "/menu.png")
	get_tree().quit()
