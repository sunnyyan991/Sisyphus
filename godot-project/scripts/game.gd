extends Node
## Global state: palette, fonts, episode list, saved progress, sound.

const CLAY := Color("#c96a32")
const DEEP := Color("#ad5527")
const LIGHT := Color("#dc8a52")
const INK := Color("#1b1410")
const BONE := Color("#f3e2c7")
const GOLD := Color("#e8b04f")
const ROCK := Color("#9e4b23")
const FAR := Color("#bd6230")
const FOG := Color("#e9c9a6")

const EPISODES := [
	{"id": "sisyphus", "no": "一", "title": "西西弗斯再来一次", "job": "踹石神",
	 "scene": "res://scenes/sisyphus.tscn",
	 "blurb": "他把石头推上山，你在他快到山顶的时候一脚踹下去。宙斯开始考核绝望指数，石头上多了一张脸，工会也成立了。",
	 "chapters": [["第一章", "入职"], ["第二章", "绩效"], ["第三章", "石头先生"], ["第四章", "罢工"], ["第五章", "一本书"], ["第六章", "调岗"]]},
	{"id": "prometheus", "no": "二", "title": "普罗米修斯，四种说法", "job": "啄肝鹰（外包）",
	 "scene": "",
	 "blurb": "宙斯的鹰辞职了，你穿上中号的鹰制服顶班。关于这份工作有四种说法，他坚持认为那是一件事的四个阶段。",
	 "chapters": [["序章", "轮岗"], ["传说之一", "锁链"], ["传说之二", "岩石"], ["传说之三", "遗忘"], ["传说之四", "疲倦"], ["尾声", "山"]]},
	{"id": "trolley", "no": "三", "title": "电车又来了", "job": "扳道工",
	 "scene": "",
	 "blurb": "你被借调到哲学部。电车开过来，你来扳道岔。每一章的工作方式都不一样：拉杆、谈判、解道岔谜题，最后亲自开车。",
	 "chapters": [["序章", "调岗"], ["第一章", "标准版"], ["第二章", "天桥"], ["第三章", "论文"], ["第四章", "多轨漂移"], ["第五章", "环线"]]},
	{"id": "tbd", "no": "四", "title": "待定", "job": "岗位空缺", "scene": "", "locked": true,
	 "blurb": "这只罐子还是空的。赫尔墨斯还在找下一个岗位。", "chapters": []},
]

const SAVE_PATH := "user://progress.json"

var serif: FontVariation
var serif_black: FontVariation
var sans: FontVariation
var progress := {}
var sound_on := true
var start_chapter := 1
var menu_sel := 0

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _sfx_cache := {}


func _ready() -> void:
	var serif_file: FontFile = load("res://fonts/serif.ttf")
	var sans_file: FontFile = load("res://fonts/sans.ttf")
	serif = _weight(serif_file, 700)
	serif_black = _weight(serif_file, 900)
	sans = _weight(sans_file, 400)
	var theme := Theme.new()
	theme.default_font = sans
	theme.default_font_size = 16
	get_tree().root.theme = theme
	RenderingServer.set_default_clear_color(CLAY)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_load()


func _weight(f: FontFile, w: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = f
	var ts := TextServerManager.get_primary_interface()
	v.variation_opentype = {ts.name_to_tag("wght"): w}
	return v


# ---------- progress ----------
func ep_progress(id: String) -> Dictionary:
	var p: Dictionary = progress.get(id, {})
	return {"seen": p.get("seen", []), "done": p.get("done", false)}


func mark_seen(id: String, n: int) -> void:
	var p: Dictionary = progress.get(id, {"seen": [], "done": false})
	var seen: Array = p.get("seen", [])
	if not seen.has(n):
		seen.append(n)
	p["seen"] = seen
	progress[id] = p
	_save()


func mark_done(id: String) -> void:
	var p: Dictionary = progress.get(id, {"seen": [], "done": false})
	p["done"] = true
	progress[id] = p
	_save()


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"progress": progress, "sound": sound_on, "menu_sel": menu_sel}))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	progress = d.get("progress", {})
	# JSON numbers come back as floats; chapter numbers are ints
	for id in progress:
		var seen: Array = progress[id].get("seen", [])
		progress[id]["seen"] = seen.map(func(x): return int(x))
	sound_on = d.get("sound", true)
	menu_sel = int(d.get("menu_sel", 0))


func set_sound(on: bool) -> void:
	sound_on = on
	_save()


func set_menu_sel(i: int) -> void:
	menu_sel = i
	_save()


# ---------- navigation ----------
func play_episode(id: String, chapter: int) -> void:
	for e in EPISODES:
		if e["id"] == id and e["scene"] != "":
			start_chapter = chapter
			get_tree().change_scene_to_file(e["scene"])
			return


func to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func episode(id: String) -> Dictionary:
	for e in EPISODES:
		if e["id"] == id:
			return e
	return {}


# ---------- sound: small synthesized cues, generated once and cached ----------
const SFX := {
	"kick": ["triangle", [180.0], 0.0, 0.35, 0.22, 45.0],
	"land": ["sine", [70.0], 0.0, 0.4, 0.35, 30.0],
	"zen": ["sine", [392.0, 494.0, 587.0, 784.0], 0.22, 0.12, 1.1, 0.0],
	"gong": ["sine", [110.0], 0.0, 0.22, 1.4, 98.0],
	"pop": ["square", [520.0, 780.0], 0.06, 0.06, 0.16, 0.0],
	"tick": ["triangle", [880.0], 0.0, 0.04, 0.05, 0.0],
	"step": ["triangle", [140.0], 0.0, 0.12, 0.08, 0.0],
}


func sfx(kind: String) -> void:
	if not sound_on or not SFX.has(kind):
		return
	if not _sfx_cache.has(kind):
		var a: Array = SFX[kind]
		_sfx_cache[kind] = _tone(a[0], a[1], a[2], a[3], a[4], a[5])
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = _sfx_cache[kind]
	p.play()


func _tone(kind: String, freqs: Array, step: float, vol: float, length: float, sweep_to: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(length * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / rate
		var idx := 0
		if step > 0.0:
			idx = mini(int(t / step), freqs.size() - 1)
		var f: float = freqs[idx]
		if sweep_to > 0.0:
			f = f * pow(sweep_to / f, minf(1.0, t / (length * 0.85)))
		phase += f / rate
		var ph := fmod(phase, 1.0)
		var x := 0.0
		match kind:
			"sine":
				x = sin(TAU * phase)
			"square":
				x = 1.0 if ph < 0.5 else -1.0
			"triangle":
				x = 4.0 * absf(ph - 0.5) - 1.0
			_:
				x = 2.0 * ph - 1.0
		var env := vol * pow(0.001 / vol, t / length)
		data.encode_s16(i * 2, int(clampf(x * env, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w
