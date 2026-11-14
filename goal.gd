extends Area2D

@export_file("*.tscn") var next_scene := ""
@export var final := false

const PLAYER = preload("res://character_body_2d.gd")

var done := false
var waiting := false
var wisp: Node2D
var time := 0.0


func _ready() -> void:
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	for n in ["Pole", "Flag"]:
		var c := get_node_or_null(n)
		if c:
			c.visible = false
	_build_wisp()


func _build_wisp() -> void:
	wisp = Node2D.new()
	add_child(wisp)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for spec in [[0.22, Color(1.0, 0.75, 0.35, 0.55)], [0.1, Color(1.0, 0.92, 0.7, 1.0)]]:
		var orb := Sprite2D.new()
		orb.texture = Atmosphere.light_texture()
		orb.scale = Vector2.ONE * spec[0]
		orb.modulate = spec[1]
		orb.material = add
		wisp.add_child(orb)
	var p := CPUParticles2D.new()
	p.amount = 14
	p.lifetime = 1.4
	p.direction = Vector2.UP
	p.spread = 25.0
	p.gravity = Vector2(0, -12)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 10.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 4.0
	p.color = Color(1.0, 0.85, 0.5)
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	wisp.add_child(p)


func _process(delta: float) -> void:
	time += delta
	if wisp and not done:
		wisp.position.y = sin(time * 2.0) * 2.0 - 2.0
		wisp.scale = Vector2.ONE * (1.0 + sin(time * 3.3) * 0.06)
	if waiting and Input.is_action_just_pressed("die"):
		waiting = false
		await _fade()
		Game.load_scene("res://menu.tscn")


func _on_body_entered(body: Node) -> void:
	if done or not body.is_in_group("player"):
		return
	done = true
	Game.sfx("reward", 0.0)
	var t0 := create_tween()
	t0.tween_property(wisp, "scale", Vector2.ONE * 2.2, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var msg := get_tree().get_first_node_in_group("msg_label") as Label
	if msg:
		if final:
			msg.text = "The light."
		else:
			msg.text = "You bounced back.\nDeaths: %d" % body.deaths
		msg.pivot_offset = msg.size / 2.0
		msg.modulate.a = 0.0
		msg.scale = Vector2(0.85, 0.85)
		msg.visible_ratio = 0.0
		var t := create_tween().set_parallel(true)
		t.tween_property(msg, "modulate:a", 1.0, 0.6)
		t.tween_property(msg, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(msg, "visible_ratio", 1.0, 0.9)
	if final:
		body.dead = true
		var rise := create_tween().set_parallel(true)
		rise.tween_property(body, "global_position:y", body.global_position.y - 40.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		rise.tween_property(body, "modulate:a", 0.0, 2.2)
		await get_tree().create_timer(2.4).timeout
		await _fade()
		Game.finish_game()
		return
	if next_scene != "":
		Game.reach_level(next_scene)
	await get_tree().create_timer(2.2).timeout
	var atm := get_tree().get_first_node_in_group("atmosphere")
	if atm:
		Atmosphere.carried_mood = atm.mood
	await _fade()
	if next_scene != "" and ResourceLoader.exists(next_scene):
		Game.load_scene(next_scene)
	else:
		Game.load_scene(get_tree().current_scene.scene_file_path)


func _fade() -> void:
	var ui := get_tree().get_first_node_in_group("shaker")
	if ui and ui.has_method("fade_out"):
		await ui.fade_out()
