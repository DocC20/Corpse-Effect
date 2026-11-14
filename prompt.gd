extends Area2D

const SERIF = preload("res://fonts/Lora-Variable.ttf")
const SERIF_ITALIC = preload("res://fonts/Lora-Italic-Variable.ttf")

@export_multiline var text := ""
@export_multiline var alt_text := ""
@export var alt_after_deaths := 1
@export var dismiss_x := -1.0
@export var label_pos := Vector2.ZERO
@export var italic := true
@export var font_size := 6

var label: Label
var shown := false
var dismissed := false
var using_alt := false
var base_y := 0.0
var time := 0.0
var tween: Tween


func _ready() -> void:
	collision_mask = 2
	label = Label.new()
	var ls := LabelSettings.new()
	ls.font = SERIF_ITALIC if italic else SERIF
	ls.font_size = font_size
	ls.font_color = Color(0.95, 0.95, 1.0)
	ls.outline_size = 2
	ls.outline_color = Color(0.05, 0.06, 0.12, 0.55)
	ls.shadow_color = Color(0, 0, 0, 0.5)
	ls.shadow_offset = Vector2(0.5, 0.5)
	label.label_settings = ls
	text = Game.controls_text(text)
	alt_text = Game.controls_text(alt_text)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(200, 30)
	label.modulate.a = 0.0
	label.visible_ratio = 0.0
	body_entered.connect(_on_body_entered)
	_attach.call_deferred()


func _attach() -> void:
	var layer := get_tree().get_first_node_in_group("text_layer")
	if layer:
		layer.add_child(label)
	else:
		add_child(label)
	label.global_position = label_pos - Vector2(100, 0)
	base_y = label.position.y


func _process(delta: float) -> void:
	time += delta
	if not shown:
		return
	if not (tween and tween.is_running()):
		label.position.y = lerpf(label.position.y, base_y + sin(time * 1.6) * 0.8, 1.0 - exp(-8.0 * delta))

	var p := get_tree().get_first_node_in_group("player")
	if p == null or p.dead:
		return
	if dismiss_x >= 0.0 and p.global_position.x > dismiss_x:
		_hide()
		return
	if alt_text != "" and not using_alt and p.deaths >= alt_after_deaths:
		_swap(alt_text)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not shown and not dismissed and label.is_inside_tree():
		_show()


func _show() -> void:
	shown = true
	if tween:
		tween.kill()
	label.position.y = base_y + 4.0
	label.visible_ratio = 0.0
	tween = create_tween().set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "position:y", base_y, 0.8).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "visible_ratio", 1.0, max(0.4, label.text.length() * 0.03))


func _swap(new_text: String) -> void:
	using_alt = true
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(label, "visible_ratio", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): label.text = new_text)
	tween.tween_property(label, "visible_ratio", 1.0, max(0.4, new_text.length() * 0.03))


func _hide() -> void:
	shown = false
	dismissed = true
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "position:y", base_y - 3.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
