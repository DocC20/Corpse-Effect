extends Node

signal settings_changed

const SAVE_PATH := "user://save.cfg"
const LEVELS := [
	"res://main.tscn",
	"res://level2.tscn",
	"res://level3.tscn",
	"res://level4.tscn",
	"res://level5.tscn",
	"res://level6.tscn",
	"res://level7.tscn",
	"res://level8.tscn",
	"res://level9.tscn",
	"res://level10.tscn",
]
const ENDING := "res://ending.tscn"
const DASH_LEVEL := 5
const LEVEL_NAMES := [
	"The Meadow",
	"Withered Fields",
	"The Highland",
	"Mountain Path",
	"The Cliffs",
	"Windy Ridge",
	"A Door in the Mountain",
	"The Deep",
	"Sunken Halls",
	"The Mossy Dark",
]
const TIPS := [
	"Every fall leaves a step behind.",
	"Press R to let go on purpose.",
	"Your past selves can be stacked.",
	"Hold jump to jump higher.",
	"Esc pauses the game.",
	"Checkpoints remember you.",
	"Dashing resets when you land or bounce.",
	"Bounce first, then dash.",
]

const MUSIC_CALM = preload("res://assets/audio/music_calm.mp3")
const MUSIC_DARK = preload("res://assets/audio/music_dark.mp3")
const SFX := {
	"checkpoint": preload("res://assets/audio/sfx_checkpoint.wav"),
	"reward": preload("res://assets/audio/sfx_reward.wav"),
	"step_grass": preload("res://assets/audio/step_grass.ogg"),
	"step_leaves": preload("res://assets/audio/step_leaves.ogg"),
	"step_gravel": preload("res://assets/audio/step_gravel.ogg"),
	"step_dirt": preload("res://assets/audio/step_dirt.ogg"),
	"step_stone": preload("res://assets/audio/step_stone.ogg"),
	"step_mud": preload("res://assets/audio/step_mud.ogg"),
	"step_puddle": preload("res://assets/audio/step_puddle.ogg"),
	"jump": preload("res://assets/audio/jump.ogg"),
	"land": preload("res://assets/audio/land.ogg"),
	"scuff": preload("res://assets/audio/scuff.ogg"),
	"step_sneaker": preload("res://assets/audio/step_sneaker.wav"),
	"dash": preload("res://assets/audio/sfx_dash.mp3"),
	"spell": preload("res://assets/audio/sfx_spell.mp3"),
}
const TEXT_BLOCK = preload("res://assets/psx/text_block.png")
const SERIF = preload("res://fonts/Lora-Variable.ttf")
const SERIF_ITALIC = preload("res://fonts/Lora-Italic-Variable.ttf")
const PANEL = preload("res://assets/kenney/ui/panel.png")
const UI_SCRIPT = preload("res://ui.gd")

var music_volume := 0.7
var sfx_volume := 0.8
var fullscreen := false
var shake_enabled := true
var touch_mode := "auto"

var furthest_level := 0
var total_deaths := 0
var has_save := false
var has_dash := false
var finished := false

var calm_player: AudioStreamPlayer
var dark_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_index := 0
var dark_mix := 0.0

var loading := false
var load_layer: CanvasLayer
var load_bar: ColorRect
var load_tip: Label

const BAR_WIDTH := 180.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_save()
	_setup_audio()
	_apply_window.call_deferred()


static func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


static func controls_text(text: String) -> String:
	if not is_mobile():
		return text
	var swaps := [
		["    F11 fullscreen", ""],
		["A / D   move        W   jump", "<  >   move        ^   jump"],
		["A / D move    W jump    R let go    Esc pause", "<  > move    ^ jump    R let go    II pause"],
		["Press R.", "Tap R."],
		["Shift or K to dash.", "Tap >> to dash."],
	]
	for pair in swaps:
		text = text.replace(pair[0], pair[1])
	return text


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.physical_keycode == KEY_F11 or (k.physical_keycode == KEY_ENTER and k.alt_pressed):
			fullscreen = not fullscreen
			_apply_window()
			save_game()
			get_viewport().set_input_as_handled()


func _setup_audio() -> void:
	var calm_stream := MUSIC_CALM.duplicate() as AudioStreamMP3
	calm_stream.loop = true
	var dark_stream := MUSIC_DARK.duplicate() as AudioStreamMP3
	dark_stream.loop = true
	calm_player = AudioStreamPlayer.new()
	calm_player.stream = calm_stream
	add_child(calm_player)
	dark_player = AudioStreamPlayer.new()
	dark_player.stream = dark_stream
	add_child(dark_player)
	calm_player.volume_db = -80.0
	dark_player.volume_db = -80.0
	calm_player.play()
	dark_player.play()
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)


func _process(delta: float) -> void:
	var atm := get_tree().get_first_node_in_group("atmosphere")
	var mood: float = atm.mood if atm else 0.0
	var target := smoothstep(0.25, 0.7, mood)
	dark_mix = lerpf(dark_mix, target, 1.0 - exp(-0.8 * delta))
	calm_player.volume_db = linear_to_db(maxf(0.0001, (1.0 - dark_mix) * music_volume * 0.8))
	dark_player.volume_db = linear_to_db(maxf(0.0001, dark_mix * music_volume * 0.9))


func sfx(key: String, pitch_jitter := 0.05, volume := 1.0, pitch := 1.0) -> void:
	if not SFX.has(key):
		return
	var p := sfx_players[sfx_index]
	sfx_index = (sfx_index + 1) % sfx_players.size()
	p.stream = SFX[key]
	p.volume_db = linear_to_db(maxf(0.0001, sfx_volume * volume))
	p.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	p.play()


func level_index(path: String) -> int:
	return LEVELS.find(path)


func reach_level(path: String) -> void:
	var i := level_index(path)
	if i > furthest_level:
		furthest_level = i
	has_save = true
	save_game()


func new_game() -> void:
	furthest_level = 0
	total_deaths = 0
	has_dash = false
	finished = false
	has_save = true
	save_game()
	load_scene(LEVELS[0])


func start_level(i: int) -> void:
	i = clampi(i, 0, LEVELS.size() - 1)
	has_dash = has_dash or i > DASH_LEVEL
	load_scene(LEVELS[i])


func continue_game() -> void:
	var i := clampi(furthest_level, 0, LEVELS.size() - 1)
	has_dash = has_dash or i > DASH_LEVEL
	load_scene(LEVELS[i])


func finish_game() -> void:
	finished = true
	has_save = true
	save_game()
	load_scene(ENDING)


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "furthest_level", furthest_level)
	cfg.set_value("progress", "total_deaths", total_deaths)
	cfg.set_value("progress", "has_save", has_save)
	cfg.set_value("progress", "has_dash", has_dash)
	cfg.set_value("progress", "finished", finished)
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.set_value("settings", "shake", shake_enabled)
	cfg.set_value("settings", "touch", touch_mode)
	cfg.save(SAVE_PATH)


func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	furthest_level = cfg.get_value("progress", "furthest_level", 0)
	total_deaths = cfg.get_value("progress", "total_deaths", 0)
	has_save = cfg.get_value("progress", "has_save", false)
	has_dash = cfg.get_value("progress", "has_dash", false)
	finished = cfg.get_value("progress", "finished", false)
	music_volume = cfg.get_value("settings", "music_volume", music_volume)
	sfx_volume = cfg.get_value("settings", "sfx_volume", sfx_volume)
	fullscreen = cfg.get_value("settings", "fullscreen", fullscreen)
	shake_enabled = cfg.get_value("settings", "shake", shake_enabled)
	touch_mode = cfg.get_value("settings", "touch", touch_mode)


func _apply_window() -> void:
	if OS.has_feature("web") or is_mobile():
		return
	var win := get_window()
	if fullscreen:
		win.mode = Window.MODE_FULLSCREEN
	else:
		win.mode = Window.MODE_WINDOWED
		var screen := DisplayServer.window_get_current_screen()
		var usable := DisplayServer.screen_get_usable_rect(screen)
		var size := Vector2i(1280, 720)
		if usable.size.x >= 1920 and usable.size.y >= 1080:
			size = Vector2i(1600, 900)
		win.size = size
		win.position = usable.position + (usable.size - size) / 2


func load_scene(path: String) -> void:
	if loading:
		return
	loading = true
	_show_loading()
	var start := Time.get_ticks_msec()
	var packed: PackedScene = null
	if OS.has_feature("web"):
		load_bar.size.x = BAR_WIDTH * 0.5
		await get_tree().create_timer(0.3).timeout
		packed = load(path)
	else:
		ResourceLoader.load_threaded_request(path)
		while true:
			var progress := []
			var status := ResourceLoader.load_threaded_get_status(path, progress)
			if progress.size() > 0:
				load_bar.size.x = BAR_WIDTH * float(progress[0])
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				packed = ResourceLoader.load_threaded_get(path)
				break
			if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				break
			await get_tree().process_frame
	load_bar.size.x = BAR_WIDTH
	var wait := 0.9 - (Time.get_ticks_msec() - start) / 1000.0
	if wait > 0.0:
		await get_tree().create_timer(wait).timeout
	get_tree().paused = false
	if packed:
		get_tree().change_scene_to_packed(packed)
	else:
		get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var t := create_tween()
	t.tween_property(load_layer.get_child(0), "modulate:a", 0.0, 0.4)
	await t.finished
	load_layer.queue_free()
	load_layer = null
	loading = false


func _show_loading() -> void:
	load_layer = CanvasLayer.new()
	load_layer.layer = 40
	add_child(load_layer)
	var root := Control.new()
	root.size = Vector2(320, 180)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	load_layer.add_child(root)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.size = Vector2(320, 180)
	root.add_child(bg)

	var box := TextureRect.new()
	box.texture = TEXT_BLOCK
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.stretch_mode = TextureRect.STRETCH_SCALE
	box.size = Vector2(230, 64)
	box.position = Vector2(45, 58)
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(box)

	var title := Label.new()
	title.label_settings = _label_settings(SERIF, 10, Color(0.9, 0.92, 1.0))
	title.text = "Loading..."
	title.position = Vector2(60, 64)
	title.size = Vector2(200, 14)
	root.add_child(title)

	load_tip = Label.new()
	load_tip.label_settings = _label_settings(SERIF_ITALIC, 6, Color(0.75, 0.78, 0.9))
	load_tip.text = TIPS[randi() % TIPS.size()]
	load_tip.position = Vector2(60, 82)
	load_tip.size = Vector2(200, 12)
	root.add_child(load_tip)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.1, 0.12, 0.2)
	bar_bg.position = Vector2(70, 102)
	bar_bg.size = Vector2(BAR_WIDTH, 4)
	root.add_child(bar_bg)

	load_bar = ColorRect.new()
	load_bar.color = Color(0.7, 0.78, 1.0)
	load_bar.position = bar_bg.position
	load_bar.size = Vector2(0, 4)
	root.add_child(load_bar)


func _label_settings(font: Font, size: int, color: Color) -> LabelSettings:
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = color
	ls.shadow_color = Color(0, 0, 0, 0.6)
	ls.shadow_offset = Vector2(0.5, 0.5)
	return ls


func build_settings(parent: Node, d: float, on_back: Callable) -> Control:
	var root := Control.new()
	root.size = Vector2(320, 180)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(root)

	var dim := ColorRect.new()
	dim.size = Vector2(320, 180)
	dim.color = Color(0, 0, 0, 0.45)
	root.add_child(dim)

	var panel := NinePatchRect.new()
	panel.texture = PANEL
	panel.patch_margin_left = 16
	panel.patch_margin_right = 16
	panel.patch_margin_top = 16
	panel.patch_margin_bottom = 16
	panel.position = Vector2(70, 18)
	panel.size = Vector2(180, 146)
	panel.modulate = Color(1.0, 0.95, 0.8).lerp(Color(0.11, 0.07, 0.09), d)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if d < 0.5 else CanvasItem.TEXTURE_FILTER_LINEAR
	root.add_child(panel)

	var text_col := Color(0.35, 0.2, 0.1).lerp(Color(0.85, 0.75, 0.72), d)
	var title := Label.new()
	title.label_settings = _label_settings(SERIF, 11, text_col)
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(70, 24)
	title.size = Vector2(180, 14)
	root.add_child(title)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.position = Vector2(88, 42)
	box.size = Vector2(144, 110)
	root.add_child(box)

	var on_music := func(v: float) -> void:
		music_volume = v
		save_game()
	var on_sfx := func(v: float) -> void:
		sfx_volume = v
		sfx("checkpoint", 0.0)
		save_game()
	box.add_child(_slider_row("Music", music_volume, d, text_col, on_music))
	box.add_child(_slider_row("Sounds", sfx_volume, d, text_col, on_sfx))

	var fs := UI_SCRIPT.make_button(_onoff("Fullscreen", fullscreen), d, SERIF)
	fs.custom_minimum_size = Vector2(144, 14)
	var on_fs := func() -> void:
		fullscreen = not fullscreen
		fs.text = _onoff("Fullscreen", fullscreen)
		_apply_window()
		save_game()
	fs.pressed.connect(on_fs)
	fs.disabled = OS.has_feature("web")
	box.add_child(fs)

	var sh := UI_SCRIPT.make_button(_onoff("Screen shake", shake_enabled), d, SERIF)
	sh.custom_minimum_size = Vector2(144, 14)
	var on_sh := func() -> void:
		shake_enabled = not shake_enabled
		sh.text = _onoff("Screen shake", shake_enabled)
		save_game()
	sh.pressed.connect(on_sh)
	box.add_child(sh)

	var tb := UI_SCRIPT.make_button("Touch buttons: " + touch_mode.capitalize(), d, SERIF)
	tb.custom_minimum_size = Vector2(144, 14)
	var on_tb := func() -> void:
		var order := ["auto", "on", "off"]
		touch_mode = order[(order.find(touch_mode) + 1) % order.size()]
		tb.text = "Touch buttons: " + touch_mode.capitalize()
		save_game()
		settings_changed.emit()
	tb.pressed.connect(on_tb)
	box.add_child(tb)

	var back := UI_SCRIPT.make_button("Back", d, SERIF)
	back.custom_minimum_size = Vector2(144, 14)
	var on_close := func() -> void:
		root.queue_free()
		on_back.call()
	back.pressed.connect(on_close)
	box.add_child(back)
	back.grab_focus.call_deferred()
	return root


func _onoff(label: String, value: bool) -> String:
	return label + (": On" if value else ": Off")


func _slider_row(label: String, value: float, d: float, col: Color, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(144, 12)
	var l := Label.new()
	l.label_settings = _label_settings(SERIF, 7, col)
	l.text = label
	l.custom_minimum_size = Vector2(40, 12)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(100, 12)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.modulate = Color(1.0, 0.85, 0.5).lerp(Color(0.8, 0.3, 0.3), d)
	s.value_changed.connect(on_change)
	row.add_child(s)
	return row
