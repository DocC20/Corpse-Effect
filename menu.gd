extends Node2D

const SERIF = preload("res://fonts/Lora-Variable.ttf")
const SERIF_ITALIC = preload("res://fonts/Lora-Italic-Variable.ttf")
const UI_SCRIPT = preload("res://ui.gd")
const PLAYER = preload("res://character_body_2d.gd")

var title: Label
var time := 0.0
var busy := false


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

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	box.position = Vector2(118, 82)
	box.size = Vector2(84, 50)
	layer.add_child(box)

	var play := UI_SCRIPT.make_button("Play", 0.0, SERIF)
	play.pressed.connect(_play)
	box.add_child(play)
	if not OS.has_feature("web"):
		var quit := UI_SCRIPT.make_button("Quit", 0.0, SERIF)
		quit.pressed.connect(_quit)
		box.add_child(quit)

	var hint := Label.new()
	var hs := LabelSettings.new()
	hs.font = SERIF
	hs.font_size = 5
	hs.font_color = Color(1, 1, 1)
	hs.outline_size = 2
	hs.outline_color = Color(0.2, 0.15, 0.1, 0.8)
	hint.label_settings = hs
	hint.text = "A / D move    W jump    R let go    Esc pause"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 166)
	hint.size = Vector2(320, 10)
	layer.add_child(hint)

	title.scale = Vector2(0.2, 0.2)
	create_tween().tween_property(title, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	play.grab_focus.call_deferred()


func _process(delta: float) -> void:
	time += delta
	title.rotation = sin(time * 1.5) * 0.03


func _play() -> void:
	if busy:
		return
	busy = true
	PLAYER.total_deaths = 0
	Atmosphere.carried_mood = -1.0
	var ui := get_tree().get_first_node_in_group("shaker")
	if ui and ui.has_method("fade_out"):
		await ui.fade_out()
	get_tree().change_scene_to_file("res://main.tscn")


func _quit() -> void:
	get_tree().quit()
