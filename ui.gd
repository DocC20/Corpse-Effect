extends Node

const SERIF = preload("res://fonts/Lora-Variable.ttf")
const SERIF_ITALIC = preload("res://fonts/Lora-Italic-Variable.ttf")
const PANEL = preload("res://assets/kenney/ui/panel.png")
const PANEL_BORDER = preload("res://assets/kenney/ui/panel_border.png")
const BUTTON = preload("res://assets/kenney/ui/button.png")

@export var allow_pause := true

var camera: Camera2D
var trauma := 0.0
var fade_rect: ColorRect
var pause_layer: CanvasLayer
var pause_root: Control
var pause_buttons: Array[Button] = []
var dread := 0.0
var time := 0.0
var touch_layer: CanvasLayer


func _ready() -> void:
	add_to_group("shaker")
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	camera = Camera2D.new()
	camera.position = Vector2(160, 90)
	add_child(camera)
	camera.make_current()
	_style("death_label", 5, Color(0.8, 0.83, 0.92))
	_style("msg_label", 12, Color(1.0, 0.85, 0.55))

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 30
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.size = Vector2(320, 180)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)
	create_tween().tween_property(fade_rect, "color:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)

	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
		var esc := InputEventKey.new()
		esc.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", esc)
	if allow_pause:
		_build_touch()


static func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()


func _build_touch() -> void:
	touch_layer = CanvasLayer.new()
	touch_layer.layer = 20
	add_child(touch_layer)
	for spec in [["move_left", "<", Vector2(6, 132), 0.85], ["move_right", ">", Vector2(48, 132), 0.85], ["jump", "^", Vector2(272, 132), 0.85], ["die", "R", Vector2(236, 144), 0.6], ["pause", "II", Vector2(296, 4), 0.42]]:
		var b := TouchScreenButton.new()
		b.texture_normal = BUTTON
		b.action = spec[0]
		b.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
		b.position = spec[2]
		b.scale = Vector2.ONE * spec[3]
		b.modulate = Color(1, 1, 1, 0.45)
		var shape := RectangleShape2D.new()
		shape.size = Vector2(48, 48)
		b.shape = shape
		b.shape_centered = true
		var l := Label.new()
		var ls := LabelSettings.new()
		ls.font = SERIF
		ls.font_size = 22
		ls.font_color = Color(0.3, 0.2, 0.1)
		l.label_settings = ls
		l.text = spec[1]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = Vector2(48, 48)
		b.add_child(l)
		touch_layer.add_child(b)


func fade_out() -> void:
	var t := create_tween()
	t.tween_property(fade_rect, "color:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	await t.finished


func _process(delta: float) -> void:
	time += delta
	trauma = maxf(trauma - delta * 10.0, 0.0)
	if not get_tree().paused:
		var cam := get_viewport().get_camera_2d()
		if cam:
			cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * trauma
	if pause_root and pause_root.visible and dread > 0.35:
		var flick := 1.0 - dread * 0.25 * (1.0 if randf() < 0.04 else 0.0)
		pause_root.modulate = Color(flick, flick, flick, pause_root.modulate.a)
		pause_root.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * dread * 0.6


func _unhandled_input(event: InputEvent) -> void:
	if not allow_pause:
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		if get_tree().paused:
			_resume()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()


func shake(amount: float) -> void:
	trauma = maxf(trauma, amount)


func _style(group: String, size: int, color: Color) -> void:
	var l := get_tree().get_first_node_in_group(group) as Label
	if l == null:
		return
	var ls := LabelSettings.new()
	ls.font = SERIF
	ls.font_size = size
	ls.font_color = color
	ls.shadow_color = Color(0, 0, 0, 0.75)
	ls.shadow_offset = Vector2(0.5, 0.5)
	ls.shadow_size = 1
	l.label_settings = ls


static func make_button(text: String, d: float, font: Font) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(84, 16)
	var fill := Color(1.0, 0.86, 0.45).lerp(Color(0.16, 0.08, 0.09), d)
	var hover := Color(1.0, 0.95, 0.65).lerp(Color(0.38, 0.08, 0.1), d)
	var text_col := Color(0.35, 0.2, 0.1).lerp(Color(0.85, 0.75, 0.72), d)
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxTexture.new()
		sb.texture = BUTTON
		sb.texture_margin_left = 16
		sb.texture_margin_right = 16
		sb.texture_margin_top = 16
		sb.texture_margin_bottom = 16
		sb.modulate_color = hover if state != "normal" else fill
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 8)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, text_col)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if d < 0.5 else CanvasItem.TEXTURE_FILTER_LINEAR
	return b


func _open_pause() -> void:
	var atm := get_tree().get_first_node_in_group("atmosphere")
	dread = atm.dread() if atm and atm.has_method("dread") else 0.0
	if pause_layer:
		pause_layer.queue_free()
	_build_pause()
	get_tree().paused = true
	if touch_layer:
		touch_layer.visible = false
	pause_root.modulate.a = 0.0
	var t := create_tween()
	if dread < 0.4:
		pause_root.scale = Vector2(0.6, 0.6)
		t.set_parallel(true)
		t.tween_property(pause_root, "modulate:a", 1.0, 0.15)
		t.tween_property(pause_root, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		t.tween_property(pause_root, "modulate:a", 1.0, lerpf(0.3, 0.9, dread)).set_trans(Tween.TRANS_SINE)
	if pause_buttons.size() > 0:
		pause_buttons[0].grab_focus()


func _resume() -> void:
	get_tree().paused = false
	if touch_layer:
		touch_layer.visible = true
	if pause_layer:
		pause_layer.queue_free()
		pause_layer = null
		pause_root = null


func _build_pause() -> void:
	pause_buttons.clear()
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 25
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)

	var dim := ColorRect.new()
	dim.size = Vector2(320, 180)
	dim.color = Color(0.25, 0.45, 0.75, 0.35).lerp(Color(0.05, 0.0, 0.01, 0.8), dread)
	pause_layer.add_child(dim)

	pause_root = Control.new()
	pause_root.size = Vector2(320, 180)
	pause_root.pivot_offset = Vector2(160, 90)
	pause_layer.add_child(pause_root)

	var w := 132.0
	var h := 104.0
	var panel := NinePatchRect.new()
	panel.texture = PANEL
	panel.patch_margin_left = 16
	panel.patch_margin_right = 16
	panel.patch_margin_top = 16
	panel.patch_margin_bottom = 16
	panel.position = Vector2(160 - w / 2.0, 90 - h / 2.0)
	panel.size = Vector2(w, h)
	panel.modulate = Color(1.0, 0.95, 0.8).lerp(Color(0.11, 0.07, 0.09), dread)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if dread < 0.5 else CanvasItem.TEXTURE_FILTER_LINEAR
	pause_root.add_child(panel)

	var border := NinePatchRect.new()
	border.texture = PANEL_BORDER
	border.patch_margin_left = 16
	border.patch_margin_right = 16
	border.patch_margin_top = 16
	border.patch_margin_bottom = 16
	border.position = panel.position - Vector2(4, 4)
	border.size = panel.size + Vector2(8, 8)
	border.modulate = Color(0.55, 0.35, 0.15).lerp(Color(0.5, 0.06, 0.08), dread)
	border.texture_filter = panel.texture_filter
	pause_root.add_child(border)

	var title := Label.new()
	var ls := LabelSettings.new()
	ls.font = SERIF if dread < 0.5 else SERIF_ITALIC
	ls.font_size = 12
	ls.font_color = Color(0.4, 0.22, 0.1).lerp(Color(0.85, 0.2, 0.22), dread)
	ls.outline_size = 2 if dread < 0.5 else 0
	ls.outline_color = Color(1.0, 0.98, 0.9)
	ls.shadow_color = Color(0, 0, 0, dread * 0.8)
	ls.shadow_offset = Vector2(0.5, 0.5)
	title.label_settings = ls
	title.text = _pause_title()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(panel.position.x, panel.position.y + 8)
	title.size = Vector2(w, 18)
	pause_root.add_child(title)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.position = Vector2(160 - 42, panel.position.y + 34)
	box.size = Vector2(84, 60)
	pause_root.add_child(box)

	var font: Font = SERIF if dread < 0.5 else SERIF_ITALIC
	for spec in [["Resume", "_resume"], ["Restart level", "_restart"], ["Main menu", "_to_menu"]]:
		var b := make_button(spec[0], dread, font)
		b.pressed.connect(Callable(self, spec[1]))
		box.add_child(b)
		pause_buttons.append(b)


func _pause_title() -> String:
	if dread < 0.25:
		return "Paused!"
	if dread < 0.5:
		return "Paused"
	if dread < 0.75:
		return "Rest a moment"
	return "Still here?"


func _restart() -> void:
	get_tree().paused = false
	await fade_out()
	get_tree().reload_current_scene()


func _to_menu() -> void:
	get_tree().paused = false
	await fade_out()
	get_tree().change_scene_to_file("res://menu.tscn")
