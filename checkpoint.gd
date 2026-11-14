extends Area2D

const TREE = preload("res://assets/country/tree.png")
const ROCK_BLOCK = preload("res://assets/rocks/rock_block.png")
const ROCK_DARK = preload("res://assets/rocks/rock_dark.png")
const CRYSTAL = preload("res://assets/caverns/checkpoint_crystal.png")

var active := false
var style := "plains"
var visual: Node2D
var light: PointLight2D


func _ready() -> void:
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	var rect := get_node_or_null("ColorRect")
	if rect:
		rect.visible = false
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
	light.energy = 0.1

	match style:
		"plains", "withered", "highland":
			var tree := Sprite2D.new()
			tree.texture = TREE
			tree.centered = false
			tree.scale = Vector2.ONE * Atmosphere.TREE_SCALE
			tree.position = Vector2(-TREE.get_width() / 2.0, -TREE.get_height()) * Atmosphere.TREE_SCALE
			tree.material = mat
			visual.add_child(tree)
			light.color = Color(1.0, 0.85, 0.5)
			light.texture_scale = 1.4
			light.position = Vector2(0, -66)
		"cave":
			var crystal := Sprite2D.new()
			crystal.texture = CRYSTAL
			crystal.scale = Vector2(2, 2)
			crystal.position = Vector2(0, -7)
			visual.add_child(crystal)
			light.color = Color(1.0, 0.45, 0.78)
			light.texture_scale = 0.7
			light.position = Vector2(0, -8)
		_:
			var inner := TextureRect.new()
			inner.texture = ROCK_DARK
			inner.stretch_mode = TextureRect.STRETCH_TILE
			inner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			inner.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			inner.position = Vector2(-8, -13)
			inner.size = Vector2(16, 12)
			inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
			visual.add_child(inner)
			var stone := NinePatchRect.new()
			stone.texture = ROCK_BLOCK
			stone.region_rect = Rect2(0, 2, 96, 94)
			stone.draw_center = false
			stone.patch_margin_left = 6
			stone.patch_margin_right = 6
			stone.patch_margin_top = 6
			stone.patch_margin_bottom = 6
			stone.position = Vector2(-10, -15)
			stone.size = Vector2(20, 15)
			stone.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stone.material = mat
			visual.add_child(stone)
			light.color = Color(1.0, 0.8, 0.5)
			light.texture_scale = 0.6
			light.position = Vector2(0, -10)
	visual.add_child(light)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	body.spawn_point = global_position
	if active or visual == null:
		return
	active = true
	var t := create_tween().set_parallel(true)
	t.tween_property(light, "energy", 0.95, 0.6).set_trans(Tween.TRANS_SINE)
	visual.scale = Vector2(1.06, 0.92)
	t.tween_property(visual, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_burst()


func _burst() -> void:
	var colors := {
		"plains": Color(0.6, 0.9, 0.4),
		"withered": Color(0.9, 0.65, 0.3),
		"highland": Color(0.6, 0.9, 0.4),
		"cave": Color(1.0, 0.55, 0.85),
	}
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = 18
	p.lifetime = 1.0
	p.explosiveness = 0.9
	p.direction = Vector2.UP
	p.spread = 70.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 50.0
	p.gravity = Vector2(0, 40)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = colors.get(style, Color(0.6, 0.9, 1.0))
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	p.position = Vector2(0, -12 if style == "cave" or style == "hills" or style == "grassrock" else -60)
	visual.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)
