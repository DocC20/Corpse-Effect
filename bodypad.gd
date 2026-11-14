extends CharacterBody2D

const REST_SCALE = Vector2(1.0, 0.9)
const FLAT_SCALE = Vector2(1.35, 0.45)

var texture: Texture2D
var art_scale := 1.0
var flip := false
var embedded := false
var sprite: Node2D
var gone := false


func _ready() -> void:
	add_to_group("bodypad")
	collision_layer = 4
	collision_mask = 1 | 4

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 6)
	shape.shape = rect
	add_child(shape)

	sprite = Node2D.new()
	sprite.position.y = 2.0 if embedded else 0.0
	sprite.modulate = Color(1.0, 0.55, 0.25, 0.0)
	sprite.scale = Vector2(0.7, 1.4)
	add_child(sprite)

	var art := Sprite2D.new()
	art.texture = texture
	art.scale = Vector2.ONE * art_scale
	art.rotation = -PI / 2.0 if flip else PI / 2.0
	art.position = Vector2(-1.0 if flip else 1.0, -1.0)
	sprite.add_child(art)

	var light := PointLight2D.new()
	light.texture = Atmosphere.light_texture()
	light.color = Color(1.0, 0.6, 0.3)
	light.texture_scale = 0.45
	light.energy = 0.0
	light.add_to_group("pad_light")
	add_child(light)

	var t := create_tween().set_parallel(true)
	t.tween_property(sprite, "scale", REST_SCALE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "modulate:a", 1.0, 0.2)


func _physics_process(delta: float) -> void:
	velocity.x = 0.0
	var landed := is_on_floor()
	if not landed:
		velocity += get_gravity() * delta
	move_and_slide()
	if not landed and is_on_floor() and not gone:
		squish(0.6)


func squish(strength := 1.0) -> void:
	if gone:
		return
	sprite.scale = REST_SCALE.lerp(FLAT_SCALE, strength)
	var t := create_tween()
	t.tween_property(sprite, "scale", REST_SCALE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func vanish() -> void:
	if gone:
		return
	gone = true
	remove_from_group("bodypad")
	for c in get_children():
		if c is PointLight2D:
			c.remove_from_group("pad_light")
			create_tween().tween_property(c, "energy", 0.0, 0.4)
	collision_layer = 0
	var t := create_tween().set_parallel(true)
	t.tween_property(sprite, "modulate:a", 0.0, 0.4)
	t.tween_property(sprite, "scale", Vector2(0.2, 0.1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(queue_free)
