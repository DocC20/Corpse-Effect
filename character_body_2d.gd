extends CharacterBody2D

const BODYPAD = preload("res://bodypad.gd")
const CLOAK_ORANGE = preload("res://assets/player/cloak_orange.png")
const CLOAK_BLUE = preload("res://assets/player/cloak_blue.png")

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
const DASH_SPEED = 240.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.25

const FRAME = 40
const ART_SCALE = 0.5
const COLS = 8
const ROW_IDLE = 0
const ROW_RUN = 1
const ROW_AIR = 2
const ROW_ARMS = 3

const DUST_COLORS := {
	"grass": Color(0.82, 0.88, 0.62),
	"leaves": Color(0.85, 0.7, 0.45),
	"gravel": Color(0.72, 0.7, 0.68),
	"stone": Color(0.6, 0.58, 0.68),
	"sneaker": Color(0.55, 0.75, 0.9),
	"mud": Color(0.45, 0.55, 0.4),
}

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
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_dir := 1.0
var can_dash := true
var ghost_timer := 0.0
var anim_time := 0.0
var anim_row := ROW_IDLE
var last_step_col := -1
var base_scale := Vector2.ONE * ART_SCALE
var step_count := 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("jump", [KEY_W, KEY_SPACE, KEY_UP])
	_bind("die", [KEY_R])
	_bind("dash", [KEY_SHIFT, KEY_K, KEY_J])
	add_to_group("player")
	collision_layer = LAYER_PLAYER
	collision_mask = LAYER_WORLD | LAYER_PADS
	if Game.level_index(get_tree().current_scene.scene_file_path) > Game.DASH_LEVEL:
		Game.has_dash = true
	sprite.hframes = COLS
	sprite.vframes = 5
	sprite.offset = Vector2(0, -FRAME / 2.0)
	sprite.position.y = FEET
	sprite.scale = base_scale
	_apply_cloak()
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


func _apply_cloak() -> void:
	sprite.texture = CLOAK_BLUE if Game.has_dash else CLOAK_ORANGE


func unlock_dash() -> void:
	Game.has_dash = true
	Game.save_game()
	Game.settings_changed.emit()
	_apply_cloak()
	sprite.modulate = Color(2.2, 2.6, 3.0)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)
	_squash(Vector2(0.6, 1.4))
	_burst(Color(0.55, 0.85, 1.0))
	_shake(3.0)


func _squash(v: Vector2) -> void:
	sprite.scale = base_scale * v


func _process(delta: float) -> void:
	sprite.scale = sprite.scale.lerp(base_scale, 1.0 - exp(-14.0 * delta))
	var lean := clampf(velocity.x / SPEED, -1.0, 1.0) * 0.09
	if not is_on_floor():
		lean *= 0.5
	if dash_time > 0.0:
		lean = 0.0
	sprite.rotation = lerpf(sprite.rotation, lean, 1.0 - exp(-12.0 * delta))
	if not dead:
		_animate(delta)


func _animate(delta: float) -> void:
	var row := ROW_IDLE
	if dash_time > 0.0 or not is_on_floor():
		row = ROW_AIR
	elif absf(velocity.x) > 12.0:
		row = ROW_RUN
	if row != anim_row:
		anim_row = row
		anim_time = 0.0
		last_step_col = -1
	anim_time += delta
	var col := 0
	match row:
		ROW_IDLE:
			col = int(anim_time * 6.0) % 4
		ROW_RUN:
			col = int(anim_time * 13.0 * clampf(absf(velocity.x) / SPEED, 0.6, 1.3)) % 8
			if (col == 1 or col == 5) and col != last_step_col:
				_footstep()
			last_step_col = col
		_:
			col = 0
	sprite.frame = row * COLS + col


func _surface() -> String:
	var atm := get_tree().get_first_node_in_group("atmosphere")
	if atm and atm.has_method("surface_at"):
		return atm.surface_at(global_position.x)
	return "grass"


func _footstep() -> void:
	var surface := _surface()
	Game.sfx("step_" + surface, 0.12, 0.32)
	step_count += 1
	if is_on_floor() and step_count % 3 == 0:
		_dust(3, Vector2(-signf(velocity.x), -0.4), 12.0)


func _dust(amount: int, dir: Vector2, speed: float) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.45
	p.explosiveness = 0.95
	p.direction = dir if dir != Vector2.ZERO else Vector2.UP
	p.spread = 50.0 if dir != Vector2.ZERO else 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, -6)
	p.damping_min = 20.0
	p.damping_max = 40.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = DUST_COLORS.get(_surface(), Color(0.8, 0.8, 0.8))
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.7))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	p.z_index = 1
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0, FEET - 1.0)
	p.emitting = true
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)


func _physics_process(delta: float) -> void:
	if dead:
		return

	if Input.is_action_just_pressed("die"):
		die(true, true)
		return

	dash_cooldown -= delta
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		if dash_time <= 0.0:
			can_dash = true
	else:
		coyote_timer -= delta
		if dash_time <= 0.0:
			velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump"):
		buffer_timer = JUMP_BUFFER
	else:
		buffer_timer -= delta

	if dash_time <= 0.0 and buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		buffer_timer = 0.0
		coyote_timer = 0.0
		_squash(Vector2(0.8, 1.2))
		Game.sfx("jump", 0.08, 0.3)
		_dust(5, Vector2.UP, 14.0)

	if Input.is_action_just_released("jump") and velocity.y < 0.0 and velocity.y > JUMP_VELOCITY:
		velocity.y *= JUMP_CUT

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0 and dash_time <= 0.0:
		sprite.flip_h = direction < 0.0

	if Game.has_dash and Input.is_action_just_pressed("dash") and can_dash and dash_cooldown <= 0.0 and dash_time <= 0.0:
		_start_dash(direction)

	if dash_time > 0.0:
		dash_time -= delta
		velocity = Vector2(dash_dir * DASH_SPEED, 0.0)
		ghost_timer -= delta
		if ghost_timer <= 0.0:
			ghost_timer = 0.03
			_ghost()
	elif direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
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
			can_dash = true
			dash_time = 0.0
			other.squish()
			_squash(Vector2(0.7, 1.35))
			_shake(2.0)
			Game.sfx("jump", 0.05, 0.45, 1.35)
			_dust(8, Vector2.ZERO, 22.0)
			bounced = true
			break

	if not bounced and is_on_floor() and not was_on_floor:
		var impact := clampf(fall_speed / 400.0, 0.0, 1.0)
		_squash(Vector2(1.0 + 0.3 * impact, 1.0 - 0.25 * impact))
		if impact > 0.25:
			Game.sfx("land", 0.08, 0.15 + 0.35 * impact)
			_dust(int(4 + impact * 6), Vector2.ZERO, 10.0 + impact * 18.0)
		if impact > 0.85:
			_shake(1.2)
		_footstep()
	was_on_floor = is_on_floor()

	if global_position.y > FALL_LIMIT:
		die(false)


func _start_dash(direction: float) -> void:
	dash_dir = direction if direction != 0.0 else (-1.0 if sprite.flip_h else 1.0)
	sprite.flip_h = dash_dir < 0.0
	dash_time = DASH_TIME
	dash_cooldown = DASH_COOLDOWN
	can_dash = false
	ghost_timer = 0.0
	buffer_timer = 0.0
	_squash(Vector2(1.35, 0.75))
	_shake(1.0)
	_dust(6, Vector2(-dash_dir, 0), 26.0)
	Game.sfx("dash", 0.06, 0.55)


func _ghost() -> void:
	var g := Sprite2D.new()
	g.texture = sprite.texture
	g.hframes = sprite.hframes
	g.vframes = sprite.vframes
	g.frame = sprite.frame
	g.flip_h = sprite.flip_h
	g.offset = sprite.offset
	g.scale = sprite.scale
	g.modulate = Color(0.55, 0.85, 1.0, 0.55)
	g.z_index = -1
	get_parent().add_child(g)
	g.global_position = sprite.global_position
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 0.0, 0.25)
	t.tween_callback(g.queue_free)


func _frame_texture() -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = sprite.texture
	a.region = Rect2(sprite.frame_coords.x * FRAME, sprite.frame_coords.y * FRAME, FRAME, FRAME)
	return a


func die(leave_body := true, forced := false, impaled := false) -> void:
	if dead:
		return
	if not forced and Time.get_ticks_msec() - respawn_time < 250:
		return
	dead = true
	dash_time = 0.0
	deaths += 1
	total_deaths += 1
	Game.total_deaths += 1
	_update_label()
	velocity = Vector2.ZERO
	Game.sfx("land", 0.05, 0.55, 0.7)

	if impaled:
		var sink := create_tween().set_parallel(true)
		sink.tween_property(sprite, "position:y", FEET + 5.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		sink.tween_property(sprite, "scale", base_scale * Vector2(1.35, 0.55), 0.12)
		sink.tween_property(sprite, "modulate", Color(1.0, 0.45, 0.4), 0.12)
		await sink.finished
		await get_tree().create_timer(0.08).timeout

	_burst(Color(0.75, 0.85, 1.0, 0.9))
	_shake(3.0)

	if leave_body:
		var pad := CharacterBody2D.new()
		pad.set_script(BODYPAD)
		pad.texture = _frame_texture()
		pad.art_scale = ART_SCALE
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
	can_dash = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	respawn_time = Time.get_ticks_msec()
	$CollisionShape2D.set_deferred("disabled", false)
	visible = true
	sprite.position.y = FEET
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.rotation = 0.0
	_squash(Vector2(0.4, 1.4))
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


func _burst(color: Color) -> void:
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
	p.color = color
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
