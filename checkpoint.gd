extends Area2D

const TREE = preload("res://assets/country/tree.png")
const CRYSTAL = preload("res://assets/caverns/checkpoint_crystal.png")
const RUIN_CRYSTAL = preload("res://assets/hollow_echo/crystal.png")

const COLORS := {
	"plains": Color(0.6, 0.9, 0.4),
	"withered": Color(0.95, 0.7, 0.35),
	"highland": Color(0.6, 0.9, 0.4),
	"grassrock": Color(1.0, 0.75, 0.4),
	"hills": Color(1.0, 0.75, 0.4),
	"cave": Color(1.0, 0.55, 0.85),
	"ruins": Color(0.5, 0.9, 1.0),
	"moss": Color(0.55, 0.95, 1.0),
}

var active := false
var style := "plains"
var visual: Node2D
var art: Node2D
var light: PointLight2D
var sparkle: CPUParticles2D
var time := 0.0
var tree_like := false
var top_y := -12.0
var art_base_y := 0.0


func _ready() -> void:
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	var rect := get_node_or_null("ColorRect")
	if rect:
		rect.visible = false
	time = randf() * 10.0
	_build.call_deferred()


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
		"plains", "withered", "highland":
			tree_like = true
			var tree := Sprite2D.new()
			tree.texture = TREE
			tree.centered = false
			tree.scale = Vector2.ONE * Atmosphere.TREE_SCALE
			tree.position = Vector2(-TREE.get_width() / 2.0, -TREE.get_height()) * Atmosphere.TREE_SCALE
			tree.material = mat
			art = tree
			light.color = Color(1.0, 0.85, 0.5)
			light.texture_scale = 1.4
			light.position = Vector2(0, -66)
			top_y = -60.0
		"moss":
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
			var crystal := Sprite2D.new()
			crystal.texture = CRYSTAL
			crystal.scale = Vector2(2, 2)
			crystal.position = Vector2(0, -7)
			art = crystal
			light.texture_scale = 0.7
			light.position = Vector2(0, -8)
		_:
			var rc := Sprite2D.new()
			rc.texture = RUIN_CRYSTAL
			rc.offset = Vector2(0, -RUIN_CRYSTAL.get_height() / 2.0)
			rc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if style != "ruins":
				rc.modulate = Color(1.0, 0.72, 0.42)
			art = rc
			light.texture_scale = 0.8
			light.position = Vector2(0, -14)
			top_y = -16.0
	visual.add_child(art)
	art_base_y = art.position.y
	visual.add_child(light)
	if not tree_like:
		visual.modulate = Color(0.6, 0.6, 0.68)

	sparkle = CPUParticles2D.new()
	sparkle.amount = 6
	sparkle.lifetime = 1.6
	sparkle.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkle.emission_rect_extents = Vector2(14 if tree_like else 5, 10 if tree_like else 6)
	sparkle.position = Vector2(0, top_y)
	sparkle.gravity = Vector2(0, -8)
	sparkle.initial_velocity_min = 1.0
	sparkle.initial_velocity_max = 4.0
	sparkle.spread = 180.0
	sparkle.color = light.color
	var sf := Gradient.new()
	sf.set_color(0, Color(1, 1, 1, 0))
	sf.add_point(0.4, Color(1, 1, 1, 1))
	sf.set_color(sf.get_point_count() - 1, Color(1, 1, 1, 0))
	sparkle.color_ramp = sf
	sparkle.emitting = false
	visual.add_child(sparkle)


func _process(delta: float) -> void:
	time += delta
	if art == null:
		return
	if tree_like:
		(art as Sprite2D).skew = sin(time * 0.9) * 0.025
	else:
		art.position.y = art_base_y + sin(time * 2.2) * (1.0 if active else 0.4)
		if not active:
			light.energy = 0.12 + sin(time * 1.5) * 0.05
		else:
			light.energy = 0.85 + sin(time * 3.0) * 0.1


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	body.spawn_point = global_position
	if active or visual == null:
		return
	active = true
	Game.sfx("checkpoint")
	var t := create_tween().set_parallel(true)
	t.tween_property(light, "energy", 0.95, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(visual, "modulate", Color.WHITE, 0.4)
	visual.scale = Vector2(1.08, 0.9)
	t.tween_property(visual, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if art is CanvasItem:
		var base := (art as CanvasItem).modulate
		(art as CanvasItem).modulate = base * Color(2.2, 2.2, 2.2)
		t.tween_property(art, "modulate", base, 0.7)
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
	t.tween_property(ring, "scale", Vector2.ONE * (0.9 if tree_like else 0.5), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
