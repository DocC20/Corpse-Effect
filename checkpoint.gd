extends Area2D

const TREE = preload("res://assets/country/tree.png")
const STONES = preload("res://assets/brown_cave/fire_stones.png")
const MUSHROOM = preload("res://assets/plants/mushroom.png")
const CAULDRON = preload("res://assets/hollow_echo/cauldron.png")

const COLORS := {
	"plains": Color(0.6, 0.9, 0.4),
	"withered": Color(0.95, 0.7, 0.35),
	"highland": Color(0.6, 0.9, 0.4),
	"grassrock": Color(0.6, 0.9, 0.4),
	"hills": Color(1.0, 0.6, 0.25),
	"cave": Color(0.45, 0.95, 1.0),
	"ruins": Color(1.0, 0.55, 0.75),
	"moss": Color(0.55, 0.95, 1.0),
}

var active := false
var style := "plains"
var visual: Node2D
var art: Node2D
var light: PointLight2D
var sparkle: CPUParticles2D
var flames: CPUParticles2D
var smoke: CPUParticles2D
var time := 0.0
var kind := "tree"
var top_y := -12.0


func _ready() -> void:
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	var rect := get_node_or_null("ColorRect")
	if rect:
		rect.visible = false
	time = randf() * 10.0
	_build.call_deferred()


func _ramp(colors: Array, offsets: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	return g


func _particles(amount: int, life: float, pos: Vector2, extents: Vector2, vel: Vector2, grav: Vector2, size: Vector2, ramp: Gradient) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = life
	p.position = pos
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.direction = Vector2.UP
	p.spread = 18.0
	p.initial_velocity_min = vel.x
	p.initial_velocity_max = vel.y
	p.gravity = grav
	p.scale_amount_min = size.x
	p.scale_amount_max = size.y
	p.color_ramp = ramp
	return p


func _build() -> void:
	var atm := get_tree().get_first_node_in_group("atmosphere")
	var mat: Material = null
	var tex: Texture2D = Atmosphere.light_texture()
	if atm:
		style = atm.style_at(global_position.x)
		mat = atm.style_mat
		tex = Atmosphere.light_texture_for(atm.realism)

	visual = Node2D.new()
	visual.position = Vector2(0, 16)
	visual.z_index = -8
	add_child(visual)

	light = PointLight2D.new()
	light.texture = tex
	light.energy = 0.15
	light.color = COLORS.get(style, Color(1, 0.8, 0.5))

	match style:
		"plains", "withered", "highland", "grassrock":
			kind = "tree"
			var tree := Sprite2D.new()
			tree.texture = TREE
			tree.centered = false
			var sc := Atmosphere.TREE_SCALE if style != "grassrock" else 1.0
			tree.scale = Vector2.ONE * sc
			tree.position = Vector2(-TREE.get_width() / 2.0, -TREE.get_height()) * sc
			tree.material = mat
			art = tree
			light.color = Color(1.0, 0.85, 0.5)
			light.texture_scale = 1.4
			light.position = Vector2(0, -60 * sc / Atmosphere.TREE_SCALE)
			top_y = -55.0 * sc / Atmosphere.TREE_SCALE
		"moss":
			kind = "flower"
			var rng := RandomNumberGenerator.new()
			rng.seed = int(global_position.x)
			var holder := Node2D.new()
			if atm:
				var flower: AnimatedSprite2D = atm.make_plant("glow_flower", Vector2.ZERO, 0.7, rng)
				flower.z_index = 0
				holder.add_child(flower)
			art = holder
			light.texture_scale = 0.8
			light.position = Vector2(-6, -38)
			top_y = -36.0
		"cave":
			kind = "mushroom"
			var m := Sprite2D.new()
			m.texture = MUSHROOM
			m.scale = Vector2.ONE * 0.3
			m.offset = Vector2(0, -MUSHROOM.get_height() / 2.0)
			m.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			art = m
			light.texture_scale = 0.8
			light.position = Vector2(0, -10)
			top_y = -12.0
		"ruins":
			kind = "cauldron"
			var c := Sprite2D.new()
			c.texture = CAULDRON
			c.scale = Vector2.ONE * 0.5
			c.offset = Vector2(0, -CAULDRON.get_height() / 2.0)
			c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			art = c
			light.texture_scale = 0.8
			light.position = Vector2(0, -14)
			top_y = -14.0
			smoke = _particles(6, 2.0, Vector2(0, -14), Vector2(5, 1), Vector2(3, 7), Vector2(1, -4), Vector2(1.0, 2.0), _ramp([Color(1, 0.6, 0.8, 0.0), Color(1, 0.65, 0.85, 0.5), Color(1, 0.7, 0.9, 0.0)], [0.0, 0.3, 1.0]))
		_:
			kind = "fire"
			var stones := Sprite2D.new()
			stones.texture = STONES
			stones.scale = Vector2.ONE * 0.16
			stones.offset = Vector2(0, -STONES.get_height() / 2.0)
			stones.position = Vector2(0, 1)
			stones.modulate = Color(0.75, 0.68, 0.65)
			stones.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			art = stones
			light.texture_scale = 1.0
			light.position = Vector2(0, -6)
			top_y = -6.0
			smoke = _particles(5, 2.4, Vector2(0, -3), Vector2(3, 1), Vector2(3, 8), Vector2(2, -3), Vector2(1.0, 2.5), _ramp([Color(0.6, 0.6, 0.62, 0.0), Color(0.55, 0.55, 0.6, 0.45), Color(0.5, 0.5, 0.55, 0.0)], [0.0, 0.3, 1.0]))
			flames = _particles(16, 0.65, Vector2(0, -2), Vector2(4, 1), Vector2(10, 20), Vector2(0, -12), Vector2(1.5, 3.0), _ramp([Color(1.0, 0.95, 0.6, 1.0), Color(1.0, 0.6, 0.2, 0.9), Color(0.85, 0.2, 0.1, 0.6), Color(0.4, 0.1, 0.1, 0.0)], [0.0, 0.3, 0.65, 1.0]))
			flames.emitting = false
			flames.z_index = 1
	visual.add_child(art)
	if smoke:
		visual.add_child(smoke)
	if flames:
		visual.add_child(flames)
	visual.add_child(light)
	if kind != "tree" and kind != "fire":
		visual.modulate = Color(0.6, 0.6, 0.68)

	sparkle = _particles(6, 1.6, Vector2(0, top_y), Vector2(14 if kind == "tree" else 5, 10 if kind == "tree" else 6), Vector2(1, 4), Vector2(0, -8), Vector2(1, 1), _ramp([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)], [0.0, 0.4, 1.0]))
	sparkle.spread = 180.0
	sparkle.color = light.color
	if kind == "fire":
		sparkle.gravity = Vector2(0, -30)
		sparkle.color = Color(1.0, 0.75, 0.3)
		sparkle.emission_rect_extents = Vector2(3, 2)
	sparkle.emitting = false
	visual.add_child(sparkle)


func _process(delta: float) -> void:
	time += delta
	if art == null:
		return
	match kind:
		"tree":
			(art as Sprite2D).skew = sin(time * 0.9) * 0.025
		"fire":
			if active:
				light.energy = 0.85 + randf() * 0.3
				light.texture_scale = 1.0 + sin(time * 13.0) * 0.05
			else:
				light.energy = 0.05
		_:
			if active:
				light.energy = 0.85 + sin(time * 3.0) * 0.1
			else:
				light.energy = 0.12 + sin(time * 1.5) * 0.05
			if kind == "mushroom":
				art.scale = Vector2(0.3 + sin(time * 2.0) * 0.006, 0.3 - sin(time * 2.0) * 0.006)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	body.spawn_point = global_position
	if active or visual == null:
		return
	active = true
	Game.sfx("checkpoint")
	var t := create_tween().set_parallel(true)
	t.tween_property(visual, "modulate", Color.WHITE, 0.4)
	if kind != "fire":
		t.tween_property(light, "energy", 0.95, 0.6).set_trans(Tween.TRANS_SINE)
	visual.scale = Vector2(1.08, 0.9)
	t.tween_property(visual, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if kind != "fire":
		var base := (art as CanvasItem).modulate
		(art as CanvasItem).modulate = base * Color(2.2, 2.2, 2.2)
		t.tween_property(art, "modulate", base, 0.7)
	if flames:
		flames.emitting = true
	if smoke and kind == "fire":
		smoke.amount = 8
	_ring()
	_burst()
	sparkle.emitting = true


func _ring() -> void:
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var ring := Sprite2D.new()
	ring.texture = Atmosphere.light_texture()
	ring.material = add
	ring.modulate = light.color * Color(1, 1, 1, 0.8)
	ring.position = Vector2(0, top_y)
	ring.scale = Vector2.ONE * 0.05
	visual.add_child(ring)
	var t := ring.create_tween().set_parallel(true)
	t.tween_property(ring, "scale", Vector2.ONE * (0.9 if kind == "tree" else 0.5), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(ring, "modulate:a", 0.0, 0.6)
	t.chain().tween_callback(ring.queue_free)


func _burst() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = 20
	p.lifetime = 1.0
	p.explosiveness = 0.9
	p.direction = Vector2.UP
	p.spread = 80.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 55.0
	p.gravity = Vector2(0, 40)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = COLORS.get(style, Color(0.6, 0.9, 1.0))
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	p.position = Vector2(0, top_y)
	visual.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)
