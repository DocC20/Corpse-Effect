extends Area2D

const ITEM = preload("res://assets/hollow_echo/crystal_item.png")

var orb: Node2D
var time := 0.0
var taken := false


func _ready() -> void:
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	orb = Node2D.new()
	add_child(orb)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var halo := Sprite2D.new()
	halo.texture = Atmosphere.light_texture()
	halo.scale = Vector2.ONE * 0.22
	halo.modulate = Color(0.45, 0.8, 1.0, 0.6)
	halo.material = add
	orb.add_child(halo)
	var gem := Sprite2D.new()
	gem.texture = ITEM
	orb.add_child(gem)
	var light := PointLight2D.new()
	light.texture = Atmosphere.light_texture()
	light.color = Color(0.45, 0.8, 1.0)
	light.texture_scale = 0.9
	light.energy = 0.9
	orb.add_child(light)
	var p := CPUParticles2D.new()
	p.amount = 12
	p.lifetime = 1.2
	p.direction = Vector2.UP
	p.spread = 40.0
	p.gravity = Vector2(0, -10)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 8.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 5.0
	p.color = Color(0.6, 0.9, 1.0)
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	orb.add_child(p)
	if Game.has_dash:
		taken = true
		orb.visible = false


func _process(delta: float) -> void:
	time += delta
	if orb and not taken:
		orb.position.y = sin(time * 2.4) * 2.0
		orb.rotation = sin(time * 1.3) * 0.15


func _on_body_entered(body: Node) -> void:
	if taken or not body.is_in_group("player"):
		return
	taken = true
	Game.sfx("spell", 0.0, 0.8)
	if body.has_method("unlock_dash"):
		body.unlock_dash()
	var t := create_tween().set_parallel(true)
	t.tween_property(orb, "scale", Vector2.ONE * 3.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(orb, "modulate:a", 0.0, 0.6)
	var msg := get_tree().get_first_node_in_group("msg_label") as Label
	if msg:
		msg.text = Game.controls_text("A spark of the deep.\nShift or K to dash.")
		msg.modulate.a = 0.0
		msg.visible_ratio = 1.0
		var mt := create_tween()
		mt.tween_property(msg, "modulate:a", 1.0, 0.6)
		mt.tween_interval(2.6)
		mt.tween_property(msg, "modulate:a", 0.0, 1.0)
