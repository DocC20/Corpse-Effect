extends CharacterBody2D

const BODYPAD = preload("res://bodypad.gd")

const SPEED = 90.0
const ACCEL = 900.0
const FRICTION = 1100.0
const JUMP_VELOCITY = -250.0
const BOUNCE_VELOCITY = -380.0
const JUMP_CUT = 0.45
const COYOTE_TIME = 0.1
const JUMP_BUFFER = 0.1
const RESPAWN_DELAY = 0.45
const FALL_LIMIT = 260.0
const FEET = 16.0
const MAX_PADS = 15

const LAYER_WORLD = 1
const LAYER_PLAYER = 2
const LAYER_PADS = 4

static var total_deaths := 0

var coyote_timer := 0.0
var buffer_timer := 0.0
var spawn_point := Vector2.ZERO
var dead := false
var deaths := 0
var was_on_floor := true
var fall_speed := 0.0
var respawn_time := -10000

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("jump", [KEY_W, KEY_SPACE, KEY_UP])
	_bind("die", [KEY_R])
	add_to_group("player")
	collision_layer = LAYER_PLAYER
	collision_mask = LAYER_WORLD | LAYER_PADS
	sprite.offset.y = -FEET
	sprite.position.y = FEET
	spawn_point = global_position
	_update_label()


func _bind(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _process(delta: float) -> void:
	sprite.scale = sprite.scale.lerp(Vector2.ONE, 1.0 - exp(-14.0 * delta))
	var lean := clampf(velocity.x / SPEED, -1.0, 1.0) * 0.09
	if not is_on_floor():
		lean *= 0.5
	sprite.rotation = lerpf(sprite.rotation, lean, 1.0 - exp(-12.0 * delta))


func _physics_process(delta: float) -> void:
	if dead:
		return

	if Input.is_action_just_pressed("die"):
		die(true, true)
		return

	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump"):
		buffer_timer = JUMP_BUFFER
	else:
		buffer_timer -= delta

	if buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		buffer_timer = 0.0
		coyote_timer = 0.0
		sprite.scale = Vector2(0.8, 1.2)

	if Input.is_action_just_released("jump") and velocity.y < 0.0 and velocity.y > JUMP_VELOCITY:
		velocity.y *= JUMP_CUT

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	fall_speed = velocity.y
	move_and_slide()

	var bounced := false
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var other := c.get_collider()
		if other is Node and other.is_in_group("bodypad") and c.get_normal().y < -0.7:
			velocity.y = BOUNCE_VELOCITY
			coyote_timer = 0.0
			other.squish()
			sprite.scale = Vector2(0.7, 1.35)
			_shake(2.0)
			bounced = true
			break

	if not bounced and is_on_floor() and not was_on_floor:
		var impact := clampf(fall_speed / 400.0, 0.0, 1.0)
		sprite.scale = Vector2(1.0 + 0.3 * impact, 1.0 - 0.25 * impact)
	was_on_floor = is_on_floor()

	if global_position.y > FALL_LIMIT:
		die(false)


func die(leave_body := true, forced := false, impaled := false) -> void:
	if dead:
		return
	if not forced and Time.get_ticks_msec() - respawn_time < 250:
		return
	dead = true
	deaths += 1
	total_deaths += 1
	_update_label()
	velocity = Vector2.ZERO

	if impaled:
		var sink := create_tween().set_parallel(true)
		sink.tween_property(sprite, "position:y", FEET + 5.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		sink.tween_property(sprite, "scale", Vector2(1.35, 0.55), 0.12)
		sink.tween_property(sprite, "modulate", Color(1.0, 0.45, 0.4), 0.12)
		await sink.finished
		await get_tree().create_timer(0.08).timeout

	_burst()
	_shake(3.0)

	if leave_body:
		var pad := CharacterBody2D.new()
		pad.set_script(BODYPAD)
		pad.texture = sprite.texture
		pad.flip = sprite.flip_h
		pad.embedded = impaled
		get_parent().add_child(pad)
		pad.global_position = global_position + Vector2(0, FEET - 3.0)
		_limit_pads()

	visible = false
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)

	await get_tree().create_timer(RESPAWN_DELAY).timeout

	global_position = _safe_spawn()
	velocity = Vector2.ZERO
	was_on_floor = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	respawn_time = Time.get_ticks_msec()
	$CollisionShape2D.set_deferred("disabled", false)
	visible = true
	sprite.position.y = FEET
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.rotation = 0.0
	sprite.scale = Vector2(0.4, 1.4)
	sprite.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(sprite, "modulate:a", 1.0, 0.25)
	dead = false


func _safe_spawn() -> Vector2:
	var pos := spawn_point
	for pad in get_tree().get_nodes_in_group("bodypad"):
		if abs(pad.global_position.x - spawn_point.x) < 14.0:
			var top: float = pad.global_position.y - 3.0
			pos.y = minf(pos.y, top - FEET - 0.5)
	return pos


func _limit_pads() -> void:
	var pads := get_tree().get_nodes_in_group("bodypad")
	if pads.size() > MAX_PADS:
		pads[0].vanish()


func _burst() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = 16
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.gravity = Vector2(0, 220)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(0.75, 0.85, 1.0, 0.9)
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0, FEET * 0.5)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _shake(amount: float) -> void:
	var ui := get_tree().get_first_node_in_group("shaker")
	if ui:
		ui.shake(amount)


func _update_label() -> void:
	var label := get_tree().get_first_node_in_group("death_label")
	if label:
		label.text = "DEATHS: %d" % deaths
