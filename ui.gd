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
var hud_root: Control
var hud_deaths: Label
var hud_bodies: Label
var hud_dash: TextureRect
var hud_tier := 0
var level_no := 0
var hud_jitter := 0.0


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
		Game.settings_changed.connect(_rebuild_touch)
		_build_hud.call_deferred()


static func is_mobile() -> bool:
	return Game.is_mobile()


func _rebuild_touch() -> void:
	if touch_layer:
		touch_layer.queue_free()
		touch_layer = null
	_build_touch()
	if touch_layer:
		touch_layer.visible = not get_tree().paused


func _build_touch() -> void:
	if Game.touch_mode == "off" or (Game.touch_mode == "auto" and not Game.is_mobile()):
		return
	touch_layer = CanvasLayer.new()
	touch_layer.layer = 20
	add_child(touch_layer)
	var specs := [["move_left", "<", Vector2(6, 132), 0.85], ["move_right", ">", Vector2(48, 132), 0.85], ["jump", "^", Vector2(272, 132), 0.85], ["die", "R", Vector2(236, 144), 0.6], ["pause", "II", Vector2(4, 4), 0.42]]
	if Game.has_dash:
		specs.append(["dash", ">>", Vector2(236, 112), 0.6])
	for spec in specs:
		var b := TouchScreenButton.new()
		b.texture_normal = BUTTON
		b.action = spec[0]
		b.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
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
	_update_hud(delta)
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
	if not Game.shake_enabled:
		return
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
	var h := 122.0
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
	for spec in [["Resume", "_resume"], ["Restart level", "_restart"], ["Settings", "_open_settings"], ["Main menu", "_to_menu"]]:
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


func _open_settings() -> void:
	pause_root.visible = false
	var on_back := func() -> void:
		pause_root.visible = true
		if pause_buttons.size() > 2:
			pause_buttons[2].grab_focus()
	Game.build_settings(pause_layer, dread, on_back)


func _restart() -> void:
	await fade_out()
	Game.load_scene(get_tree().current_scene.scene_file_path)


func _to_menu() -> void:
	await fade_out()
	Game.load_scene("res://menu.tscn")


static func roman(n: int) -> String:
	var vals := [10, 9, 5, 4, 1]
	var syms := ["X", "IX", "V", "IV", "I"]
	var out := ""
	for i in vals.size():
		while n >= vals[i]:
			out += syms[i]
			n -= vals[i]
	return out


func _hud_label(text: String, italic: bool, size: int, color: Color, pos: Vector2, w: float, align := HORIZONTAL_ALIGNMENT_RIGHT) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font = SERIF_ITALIC if italic else SERIF
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 2
	ls.outline_color = Color(0.05, 0.06, 0.12, 0.55)
	ls.shadow_color = Color(0, 0, 0, 0.5)
	ls.shadow_offset = Vector2(0.5, 0.5)
	l.label_settings = ls
	l.text = text
	l.position = pos
	l.size = Vector2(w, size + 4)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _fade_line(pos: Vector2, w: float, color: Color, both_sides := false) -> TextureRect:
	var g := Gradient.new()
	if both_sides:
		g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		g.colors = PackedColorArray([Color(color, 0.0), color, Color(color, 0.0)])
	else:
		g.set_color(0, Color(color, 0.0))
		g.set_color(1, color)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 64
	tex.height = 1
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = pos
	r.size = Vector2(w, 0.5)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _diamond(pos: Vector2, color: Color) -> Polygon2D:
	var d := Polygon2D.new()
	d.polygon = PackedVector2Array([Vector2(0, -1.5), Vector2(1.5, 0), Vector2(0, 1.5), Vector2(-1.5, 0)])
	d.color = color
	d.position = pos
	return d


func _build_hud() -> void:
	level_no = Game.level_index(get_tree().current_scene.scene_file_path) + 1
	if level_no <= 0:
		return
	var old := get_tree().get_first_node_in_group("death_label") as CanvasItem
	if old:
		old.visible = false
	hud_tier = 1 if level_no <= 2 else (2 if level_no <= 5 else (3 if level_no <= 8 else 4))
	var d := clampf((level_no - 1) / 9.0, 0.0, 1.0)
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	hud_root = Control.new()
	hud_root.size = Vector2(320, 180)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_root)
	var name_text: String = Game.LEVEL_NAMES[level_no - 1]
	var text_col := Color(0.95, 0.95, 1.0)
	var accent := Color(1.0, 0.85, 0.55)
	if hud_tier >= 3:
		accent = Color(0.7, 0.82, 1.0)
	if hud_tier >= 4:
		text_col = Color(1.0, 0.9, 0.88)
		accent = Color(0.95, 0.5, 0.48)
	match hud_tier:
		1:
			hud_deaths = _hud_label("", true, 6, text_col, Vector2(196, 3), 120)
			hud_root.add_child(hud_deaths)
		2:
			hud_root.add_child(_hud_label(name_text, true, 5, accent, Vector2(196, 2), 120))
			hud_root.add_child(_fade_line(Vector2(256, 11.5), 60, Color(accent, 0.7)))
			hud_deaths = _hud_label("", true, 6, text_col, Vector2(196, 12), 120)
			hud_root.add_child(hud_deaths)
		_:
			var head := roman(level_no) + "   " + name_text
			hud_root.add_child(_hud_label(head, true, 5, accent, Vector2(176, 2), 140))
			hud_root.add_child(_fade_line(Vector2(226, 11.5), 88, Color(accent, 0.8), hud_tier >= 4))
			hud_root.add_child(_diamond(Vector2(314.5, 11.75), accent))
			if hud_tier >= 4:
				hud_root.add_child(_diamond(Vector2(226, 11.75), accent))
			hud_deaths = _hud_label("", true, 6, text_col, Vector2(196, 12), 120)
			hud_root.add_child(hud_deaths)
			hud_bodies = _hud_label("", true, 5, Color(1.0, 0.72, 0.5), Vector2(196, 20), 120)
			hud_root.add_child(hud_bodies)
			hud_dash = TextureRect.new()
			hud_dash.texture = preload("res://assets/hollow_echo/crystal_item.png")
			hud_dash.position = Vector2(302, 29)
			hud_dash.size = Vector2(12, 12)
			hud_dash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			hud_dash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hud_dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hud_dash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			hud_root.add_child(hud_dash)
	hud_deaths.pivot_offset = Vector2(120, 5)
	_show_title(d, name_text, accent)


var shown_deaths := -1


func _update_hud(delta: float) -> void:
	if hud_deaths == null:
		return
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		return
	var deaths: int = p.deaths
	if deaths != shown_deaths:
		if shown_deaths >= 0:
			hud_deaths.scale = Vector2(1.35, 1.35)
			create_tween().tween_property(hud_deaths, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		shown_deaths = deaths
		hud_deaths.text = ("Fallen  %d" if hud_tier >= 4 else "Deaths  %d") % deaths
	if hud_bodies:
		var n := get_tree().get_nodes_in_group("bodypad").size()
		hud_bodies.text = ("left behind  %d" if hud_tier >= 4 else "bodies  %d / 15") % n
	if hud_dash:
		hud_dash.visible = Game.has_dash
		var dash_ready: bool = p.can_dash and p.dash_time <= 0.0
		var target := Color(1, 1, 1, 1) if dash_ready else Color(0.4, 0.45, 0.6, 0.5)
		hud_dash.modulate = hud_dash.modulate.lerp(target, 1.0 - exp(-12.0 * delta))
		hud_dash.position.y = 29.0 + (sin(time * 3.0) * 0.8 if dash_ready else 0.0)
	if hud_tier >= 4 and hud_root:
		hud_jitter -= delta
		if hud_jitter <= 0.0:
			hud_jitter = randf_range(0.08, 0.5)
			hud_root.position = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) if randf() < 0.25 else Vector2.ZERO
			hud_root.modulate.a = 0.7 if randf() < 0.04 else 1.0


func _show_title(d: float, name_text: String, accent: Color) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var root := Control.new()
	root.size = Vector2(320, 180)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.modulate.a = 0.0
	layer.add_child(root)
	var col := Color(0.95, 0.95, 1.0)
	var top_text := "Level %d" % level_no
	if hud_tier >= 3:
		top_text = roman(level_no)
	var top := _hud_label(top_text, false, 7 if hud_tier < 3 else 9, accent, Vector2(0, 24), 320, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(top)
	var title := _hud_label(name_text, true, 12, col, Vector2(0, 36), 320, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(title)
	var line := _fade_line(Vector2(160, 56), 0, Color(accent, 0.9), true)
	root.add_child(line)
	if hud_tier >= 3:
		root.add_child(_diamond(Vector2(160, 56.25), accent))
	var t := create_tween()
	t.tween_interval(0.7)
	t.tween_property(root, "modulate:a", 1.0, 0.8 + d * 0.6).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(line, "size:x", 140.0, 1.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(line, "position:x", 90.0, 1.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(title, "position:y", 34.0, 1.6).set_trans(Tween.TRANS_SINE)
	t.tween_interval(1.6)
	t.tween_property(root, "modulate:a", 0.0, 0.9).set_trans(Tween.TRANS_SINE)
	t.tween_callback(layer.queue_free)
