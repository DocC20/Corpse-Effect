extends Node2D

const SERIF = preload("res://fonts/Lora-Variable.ttf")
const SERIF_ITALIC = preload("res://fonts/Lora-Italic-Variable.ttf")
const UI_SCRIPT = preload("res://ui.gd")

var title: Label
var time := 0.0
var busy := false
var box: VBoxContainer
var ui_layer: CanvasLayer
var focus_button: Button


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	title = Label.new()
	var ls := LabelSettings.new()
	ls.font = SERIF
	ls.font_size = 26
	ls.font_color = Color(1.0, 0.9, 0.55)
	ls.outline_size = 5
	ls.outline_color = Color(0.36, 0.2, 0.1)
	ls.shadow_color = Color(0, 0, 0, 0.35)
	ls.shadow_offset = Vector2(1, 1.5)
	title.label_settings = ls
	title.text = "Corpse & Effect"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 22)
	title.size = Vector2(320, 36)
	title.pivot_offset = Vector2(160, 18)
	layer.add_child(title)

	var sub := Label.new()
	var ss := LabelSettings.new()
	ss.font = SERIF_ITALIC
	ss.font_size = 7
	ss.font_color = Color(0.3, 0.2, 0.12)
	ss.outline_size = 2
	ss.outline_color = Color(1.0, 0.97, 0.88)
	sub.label_settings = ss
	sub.text = "Every fall is a step up."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 58)
	sub.size = Vector2(320, 12)
	layer.add_child(sub)

	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.position = Vector2(112, 70)
	box.size = Vector2(84, 80)
	layer.add_child(box)
	ui_layer = layer

	var first: Button = null
	if Game.has_save:
		var cont := UI_SCRIPT.make_button("Continue (Level %d)" % (Game.furthest_level + 1), 0.0, SERIF)
		cont.custom_minimum_size = Vector2(96, 16)
		cont.pressed.connect(_continue)
		box.add_child(cont)
		first = cont
	var new_btn := UI_SCRIPT.make_button("New Game", 0.0, SERIF)
	new_btn.pressed.connect(_new_game)
	box.add_child(new_btn)
	if first == null:
		first = new_btn
	var levels := UI_SCRIPT.make_button("Levels", 0.0, SERIF)
	levels.pressed.connect(_levels)
	box.add_child(levels)
	var settings := UI_SCRIPT.make_button("Settings", 0.0, SERIF)
	settings.pressed.connect(_settings)
	box.add_child(settings)
	if not OS.has_feature("web"):
		var quit := UI_SCRIPT.make_button("Quit", 0.0, SERIF)
		quit.pressed.connect(_quit)
		box.add_child(quit)
	focus_button = first

	var hint := Label.new()
	var hs := LabelSettings.new()
	hs.font = SERIF
	hs.font_size = 5
	hs.font_color = Color(1, 1, 1)
	hs.outline_size = 2
	hs.outline_color = Color(0.2, 0.15, 0.1, 0.8)
	hint.label_settings = hs
	hint.text = Game.controls_text("A / D move    W jump    R let go    Esc pause    F11 fullscreen")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 166)
	hint.size = Vector2(320, 10)
	layer.add_child(hint)

	title.scale = Vector2(0.2, 0.2)
	create_tween().tween_property(title, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	first.grab_focus.call_deferred()


func _process(delta: float) -> void:
	time += delta
	title.rotation = sin(time * 1.5) * 0.03


func _start(action: Callable) -> void:
	if busy:
		return
	busy = true
	var ui := get_tree().get_first_node_in_group("shaker")
	if ui and ui.has_method("fade_out"):
		await ui.fade_out()
	action.call()


func _continue() -> void:
	_start(Game.continue_game)


func _new_game() -> void:
	if not Game.has_save:
		_start(Game.new_game)
		return
	box.visible = false
	var root := Control.new()
	root.size = Vector2(320, 180)
	ui_layer.add_child(root)
	var dim := ColorRect.new()
	dim.size = Vector2(320, 180)
	dim.color = Color(0, 0, 0, 0.45)
	root.add_child(dim)
	var panel := NinePatchRect.new()
	panel.texture = preload("res://assets/kenney/ui/panel.png")
	panel.patch_margin_left = 16
	panel.patch_margin_right = 16
	panel.patch_margin_top = 16
	panel.patch_margin_bottom = 16
	panel.position = Vector2(80, 54)
	panel.size = Vector2(160, 84)
	panel.modulate = Color(1.0, 0.95, 0.8)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(panel)
	var q := Label.new()
	var qs := LabelSettings.new()
	qs.font = SERIF
	qs.font_size = 8
	qs.font_color = Color(0.35, 0.2, 0.1)
	q.label_settings = qs
	q.text = "Start a new game?\nYour saved progress will be lost."
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.position = Vector2(80, 64)
	q.size = Vector2(160, 30)
	root.add_child(q)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.position = Vector2(104, 104)
	root.add_child(row)
	var yes := UI_SCRIPT.make_button("Yes", 0.0, SERIF)
	yes.custom_minimum_size = Vector2(52, 16)
	yes.pressed.connect(func() -> void: _start(Game.new_game))
	row.add_child(yes)
	var no := UI_SCRIPT.make_button("No", 0.0, SERIF)
	no.custom_minimum_size = Vector2(52, 16)
	var on_no := func() -> void:
		root.queue_free()
		box.visible = true
		focus_button.grab_focus()
	no.pressed.connect(on_no)
	row.add_child(no)
	no.grab_focus.call_deferred()


func _levels() -> void:
	box.visible = false
	var root := Control.new()
	root.size = Vector2(320, 180)
	ui_layer.add_child(root)
	var dim := ColorRect.new()
	dim.size = Vector2(320, 180)
	dim.color = Color(0, 0, 0, 0.45)
	root.add_child(dim)
	var panel := NinePatchRect.new()
	panel.texture = preload("res://assets/kenney/ui/panel.png")
	panel.patch_margin_left = 16
	panel.patch_margin_right = 16
	panel.patch_margin_top = 16
	panel.patch_margin_bottom = 16
	panel.position = Vector2(30, 36)
	panel.size = Vector2(260, 112)
	panel.modulate = Color(1.0, 0.95, 0.8)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(panel)
	var q := Label.new()
	var qs := LabelSettings.new()
	qs.font = SERIF
	qs.font_size = 9
	qs.font_color = Color(0.35, 0.2, 0.1)
	q.label_settings = qs
	q.text = "Choose a level"
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.position = Vector2(30, 46)
	q.size = Vector2(260, 14)
	root.add_child(q)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.position = Vector2(54, 64)
	root.add_child(grid)
	var center := func() -> void:
		grid.position.x = 160.0 - grid.size.x / 2.0
	center.call_deferred()
	var first: Button = null
	for i in Game.LEVELS.size():
		var b := UI_SCRIPT.make_button(str(i + 1), 0.0, SERIF)
		b.custom_minimum_size = Vector2(28, 16)
		b.tooltip_text = Game.LEVEL_NAMES[i]
		b.pressed.connect(_pick_level.bind(i))
		grid.add_child(b)
		if first == null:
			first = b
	var back := UI_SCRIPT.make_button("Back", 0.0, SERIF)
	back.custom_minimum_size = Vector2(60, 16)
	back.position = Vector2(130, 120)
	var on_back := func() -> void:
		root.queue_free()
		box.visible = true
		focus_button.grab_focus()
	back.pressed.connect(on_back)
	root.add_child(back)
	first.grab_focus.call_deferred()


func _pick_level(i: int) -> void:
	_start(Game.start_level.bind(i))


func _settings() -> void:
	box.visible = false
	var on_back := func() -> void:
		box.visible = true
		focus_button.grab_focus()
	Game.build_settings(ui_layer, 0.0, on_back)


func _quit() -> void:
	get_tree().quit()
