class_name Atmosphere
extends Node2D

@export var mood_start := 0.0
@export var mood_end := 0.55
@export var progress_from := 40.0
@export var progress_to := 300.0
@export var level_size := Vector2(320, 180)
@export_enum("plains", "withered", "highland", "grassrock", "hills", "cave") var ground_style := "plains"
@export_enum("none", "plains", "withered", "highland", "grassrock", "hills", "cave") var ground_style_b := "none"
@export var style_switch_x := -1.0
@export_range(0.0, 1.0) var realism := 0.0
@export_range(0.0, 1.0) var fx := 1.0
@export var level_number := 1
@export var trees: Array[Vector2] = []
@export var night_at_x := -1.0
@export var night_mood := 0.75
@export var night_message := "Night falls."

const BACK = preload("res://assets/country/back.png")
const FOREST = preload("res://assets/country/forest.png")
const GROUND_TOP = preload("res://assets/country/ground_top.png")
const GRASS_SHORT = preload("res://assets/country/grass_short.png")
const GROUND_PATH = preload("res://assets/country/ground_path.png")
const GROUND_FILL = preload("res://assets/country/ground_fill.png")
const TREE = preload("res://assets/country/tree.png")
const ROCK_BLOCK = preload("res://assets/rocks/rock_block.png")
const ROCK_DARK = preload("res://assets/rocks/rock_dark.png")
const MOON = preload("res://assets/rocks/moon.png")
const CAVE_BG = preload("res://assets/caverns/background.png")
const CAVE_WALLS = preload("res://assets/caverns/back-walls.png")
const CAVE_TOP = preload("res://assets/caverns/cave_top.png")
const CAVE_FILL = preload("res://assets/caverns/cave_fill.png")
const LIGHT_MASK = preload("res://assets/kenney/light/circle_b_noise.png")
const STYLIZE = preload("res://shaders/stylize.gdshader")
const HAZARD_ROOTS = preload("res://assets/rocks/hazard_roots.png")
const HAZARD_CRYSTALS = preload("res://assets/caverns/hazard_crystals.png")
const HAZARD_CRYSTALS_DOWN = preload("res://assets/caverns/hazard_crystals_down.png")

const SKY_TOP_HAPPY = Color(0.42, 0.7, 0.95)
const SKY_BOTTOM_HAPPY = Color(1.0, 0.88, 0.68)
const SKY_TOP_GLOOMY = Color(0.055, 0.078, 0.19)
const SKY_BOTTOM_GLOOMY = Color(0.17, 0.22, 0.4)
const MODULATE_HAPPY = Color(1, 1, 1)
const MODULATE_GLOOMY = Color(0.46, 0.52, 0.78)
const FOG_HAPPY = Color(1.0, 0.97, 0.9, 0.6)
const FOG_GLOOMY = Color(0.55, 0.6, 0.82, 1.0)

const HAZARD_TINT = {
	"plains": Color(0.62, 0.78, 0.5),
	"withered": Color(0.85, 0.72, 0.5),
	"grassrock": Color(0.75, 0.8, 0.6),
	"highland": Color(0.68, 0.78, 0.58),
	"hills": Color(1, 1, 1),
	"cave": Color(1, 1, 1),
}

const TREE_SCALE = 1.35

static var _light_tex: Texture2D
static var carried_mood := -1.0
static var _light_tex_stepped: Texture2D

var mood := 0.0
var sky_mat: ShaderMaterial
var fog_mats: Array[ShaderMaterial] = []
var vignette_mat: ShaderMaterial
var rays_mat: ShaderMaterial
var modulate_node: CanvasModulate
var drift: CPUParticles2D
var ash: CPUParticles2D
var lantern: PointLight2D
var goal_light: PointLight2D
var player: Node2D
var moon: Sprite2D
var style_mat: ShaderMaterial
var is_night := false
var mood_speed := 1.5
var applied_mood := -1.0
var low_end := false
var moon_halo: Sprite2D
var time := 0.0


static func light_texture() -> Texture2D:
	if _light_tex == null:
		var img := LIGHT_MASK.get_image()
		if img:
			img.convert(Image.FORMAT_RGBA8)
			img.resize(128, 128, Image.INTERPOLATE_BILINEAR)
			_light_tex = ImageTexture.create_from_image(img)
			var stepped := img.duplicate() as Image
			for y in stepped.get_height():
				for x in stepped.get_width():
					var c := stepped.get_pixel(x, y)
					c.a = floorf(c.a * 5.0 + 0.5) / 5.0
					stepped.set_pixel(x, y, c)
			_light_tex_stepped = ImageTexture.create_from_image(stepped)
		else:
			_light_tex = LIGHT_MASK
			_light_tex_stepped = LIGHT_MASK
	return _light_tex


static func light_texture_for(r: float) -> Texture2D:
	light_texture()
	return _light_tex_stepped if r < 0.5 else _light_tex


func style_at(x: float) -> String:
	if ground_style_b != "none" and ground_style_b != "" and style_switch_x >= 0.0 and x >= style_switch_x:
		return ground_style_b
	return ground_style


func dread() -> float:
	return clampf((level_number - 1) / 14.0 + smoothstep(0.55, 0.95, mood) * 0.15, 0.0, 1.0)


func _is_grassy(style: String) -> bool:
	return style == "plains" or style == "withered" or style == "highland"


func _has_cave() -> bool:
	return ground_style == "cave" or ground_style_b == "cave"


func _ready() -> void:
	add_to_group("atmosphere")
	low_end = OS.has_feature("mobile") or OS.has_feature("web")
	var root := get_parent()
	var cave := ground_style == "cave"
	add_to_group("atmosphere_root")

	var bg := root.get_node_or_null("Background")
	if bg:
		bg.visible = false

	style_mat = ShaderMaterial.new()
	style_mat.shader = STYLIZE
	style_mat.set_shader_parameter("levels", lerpf(6.0, 40.0, realism))
	style_mat.set_shader_parameter("saturation", lerpf(1.15, 1.0, realism))
	style_mat.set_shader_parameter("contrast", lerpf(0.88, 1.0, realism))
	style_mat.set_shader_parameter("lift", lerpf(0.04, 0.0, realism))
	style_mat.set_shader_parameter("wither", 0.65 if ground_style == "withered" else 0.0)

	var sky := ColorRect.new()
	sky.size = level_size
	sky.z_index = -100
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = preload("res://shaders/sky.gdshader")
	sky_mat.set_shader_parameter("bands", lerpf(45.0, 360.0, realism))
	sky.material = sky_mat
	root.add_child.call_deferred(sky)
	root.move_child.call_deferred(sky, 0)

	var rays := ColorRect.new()
	rays.size = level_size
	rays.z_index = -90
	rays_mat = ShaderMaterial.new()
	rays_mat.shader = preload("res://shaders/rays.gdshader")
	rays.material = rays_mat
	rays.visible = not cave
	root.add_child.call_deferred(rays)

	for spec in [[-80, 2.5, 0.012, 0.45], [15, 4.0, -0.02, 0.6]]:
		var fog := ColorRect.new()
		fog.size = level_size
		fog.z_index = spec[0]
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/fog.gdshader")
		m.set_shader_parameter("scale", spec[1] * level_size.x / 320.0)
		m.set_shader_parameter("speed", spec[2])
		m.set_shader_parameter("height", spec[3])
		m.set_shader_parameter("res", Vector2(160, 90).lerp(Vector2(640, 360), realism) * level_size / Vector2(320, 180))
		m.set_shader_parameter("steps", lerpf(6.0, 40.0, realism))
		m.set_shader_parameter("octaves", 2 if low_end else 4)
		fog.material = m
		fog_mats.append(m)
		root.add_child.call_deferred(fog)

	modulate_node = CanvasModulate.new()
	root.add_child.call_deferred(modulate_node)

	var vlayer := CanvasLayer.new()
	vlayer.layer = 2
	var vig := ColorRect.new()
	vig.size = Vector2(320, 180)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_mat = ShaderMaterial.new()
	vignette_mat.shader = preload("res://shaders/vignette.gdshader")
	vignette_mat.set_shader_parameter("grain", lerpf(0.06, 0.015, realism) * fx)
	vig.material = vignette_mat
	vlayer.add_child(vig)
	root.add_child.call_deferred(vlayer)

	match ground_style:
		"withered":
			drift = _make_particles(Color(0.78, 0.55, 0.3), Vector2(4, 10), 1.5)
		"cave":
			drift = _make_particles(Color(0.7, 0.62, 0.85), Vector2(0, -1), 1.0)
		_:
			drift = _make_particles(Color(1.0, 0.92, 0.6), Vector2(0, -3), 1.0)
	ash = _make_particles(Color(0.7, 0.75, 0.88), Vector2(0, 9), 1.5)

	var x_end := level_size.x + 32.0
	if ground_style == "cave" and (ground_style_b == "none" or ground_style_b == "" or style_switch_x < 0.0):
		_add_cave_backdrop(root, -32.0, x_end)
	elif _has_cave() and style_switch_x >= 0.0:
		if ground_style == "cave":
			_add_cave_backdrop(root, -32.0, style_switch_x)
			_add_backdrop(root, style_switch_x, x_end)
		else:
			_add_backdrop(root, -32.0, style_switch_x)
			_add_cave_backdrop(root, style_switch_x, x_end)
			_add_cave_mouth(root, style_switch_x)
	else:
		_add_backdrop(root, -32.0, x_end)

	for child in root.get_children():
		if child is StaticBody2D:
			var rect := child.get_node_or_null("ColorRect") as ColorRect
			if rect and not child.name.begins_with("Wall"):
				_skin_ground(child, rect, style_at(child.global_position.x))
			for sub in child.get_children():
				if sub is Polygon2D:
					_ceiling_hazard(sub as Polygon2D, style_at(child.global_position.x))
		elif child is Polygon2D:
			_restyle_spikes(child as Polygon2D)

	var goal := root.get_node_or_null("Goal")
	if goal:
		goal_light = _make_light(Color(1.0, 0.85, 0.5), 0.9)
		goal.add_child.call_deferred(goal_light)

	mood = mood_start
	if carried_mood >= 0.0:
		mood = carried_mood
	carried_mood = -1.0
	_apply(mood)


func _add_backdrop(root: Node, x0: float, x1: float) -> void:
	var back := TextureRect.new()
	back.texture = BACK
	back.stretch_mode = TextureRect.STRETCH_TILE
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	back.position = Vector2(x0, level_size.y - BACK.get_height())
	back.size = Vector2(x1 - x0, BACK.get_height())
	back.z_index = -96
	back.material = style_mat
	root.add_child.call_deferred(back)

	var moon_x := clampf(x1 - 60.0, x0 + 40.0, level_size.x - 52.0)
	var halo_tex := GradientTexture2D.new()
	var hg := Gradient.new()
	hg.set_color(0, Color(0.75, 0.82, 1.0, 0.55))
	hg.set_color(1, Color(0.75, 0.82, 1.0, 0.0))
	halo_tex.gradient = hg
	halo_tex.fill = GradientTexture2D.FILL_RADIAL
	halo_tex.fill_from = Vector2(0.5, 0.5)
	halo_tex.fill_to = Vector2(1.0, 0.5)
	halo_tex.width = 96
	halo_tex.height = 96
	moon_halo = Sprite2D.new()
	moon_halo.texture = halo_tex
	moon_halo.position = Vector2(moon_x, 34)
	moon_halo.z_index = -95
	moon_halo.modulate.a = 0.0
	root.add_child.call_deferred(moon_halo)

	moon = Sprite2D.new()
	moon.texture = MOON
	moon.position = Vector2(moon_x, 34)
	moon.scale = Vector2.ONE * lerpf(2.0, 1.5, realism)
	moon.z_index = -95
	moon.modulate.a = 0.0
	root.add_child.call_deferred(moon)

	var outdoor_style := ground_style if ground_style != "cave" else ground_style_b
	if outdoor_style == "plains" or outdoor_style == "withered":
		var forest := TextureRect.new()
		forest.texture = FOREST
		forest.stretch_mode = TextureRect.STRETCH_TILE
		forest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		forest.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		forest.position = Vector2(x0, level_size.y - FOREST.get_height())
		forest.size = Vector2(x1 - x0, FOREST.get_height())
		forest.z_index = -94
		forest.material = style_mat
		root.add_child.call_deferred(forest)

	for pos in trees:
		var tree := Sprite2D.new()
		tree.texture = TREE
		tree.centered = false
		tree.scale = Vector2.ONE * TREE_SCALE
		tree.position = pos - Vector2(TREE.get_width() / 2.0, TREE.get_height()) * TREE_SCALE
		tree.z_index = -10
		tree.material = style_mat
		root.add_child.call_deferred(tree)


func _floor_top_at(root: Node, x: float) -> float:
	var best := level_size.y
	for child in root.get_children():
		if child is StaticBody2D and not child.name.begins_with("Wall") and not child.name.begins_with("Pit"):
			var rect := child.get_node_or_null("ColorRect") as ColorRect
			if rect == null:
				continue
			var gx: float = child.global_position.x
			var gy: float = child.global_position.y
			if x >= gx + rect.offset_left and x <= gx + rect.offset_right and gy + rect.offset_top > level_size.y * 0.4:
				best = minf(best, gy + rect.offset_top)
	return best


func _gradient_rect(pos: Vector2, size: Vector2, from: Color, to: Color, z: int) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, from)
	g.set_color(1, to)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 64
	tex.height = 4
	var r := TextureRect.new()
	r.texture = tex
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.position = pos
	r.size = size
	r.z_index = z
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _add_cave_mouth(root: Node, x: float) -> void:
	var dark := Color(0.02, 0.015, 0.04)
	var floor_y := _floor_top_at(root, x + 4.0)
	var open_top := floor_y - 46.0

	root.add_child.call_deferred(_gradient_rect(Vector2(x - 70.0, -40.0), Vector2(70, level_size.y + 80.0), Color(dark, 0.0), Color(dark, 0.75), -20))
	root.add_child.call_deferred(_gradient_rect(Vector2(x, -40.0), Vector2(150, level_size.y + 80.0), Color(dark, 0.97), Color(dark, 0.0), -20))

	var arch := _rock_block(Vector2(x - 26.0, -60.0), Vector2(52, open_top + 60.0))
	arch.z_index = 3
	root.add_child.call_deferred(arch)
	var lip := _rock_block(Vector2(x - 34.0, open_top - 14.0), Vector2(30, 18))
	lip.z_index = 3
	root.add_child.call_deferred(lip)


func _add_cave_backdrop(root: Node, x0: float, x1: float) -> void:
	var y := (level_size.y - CAVE_BG.get_height()) / 2.0
	for spec in [[CAVE_BG, -96], [CAVE_WALLS, -95]]:
		var tex: Texture2D = spec[0]
		var r := TextureRect.new()
		r.texture = tex
		r.stretch_mode = TextureRect.STRETCH_TILE
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		r.position = Vector2(x0, y)
		r.size = Vector2(x1 - x0, tex.get_height())
		r.z_index = spec[1]
		r.modulate = Color(0.62, 0.6, 0.72)
		r.material = style_mat
		root.add_child.call_deferred(r)


func _tiled(tex: Texture2D, pos: Vector2, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.stretch_mode = TextureRect.STRETCH_TILE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	r.position = pos
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.material = style_mat
	return r


func _short_grass(surface: Vector2, width: float) -> Node2D:
	var holder := Node2D.new()
	holder.z_index = -5
	holder.position = surface - Vector2(0, GRASS_SHORT.get_height() * 0.5)
	holder.scale = Vector2(1.0, 0.5)
	var strip := _tiled(GRASS_SHORT, Vector2.ZERO, Vector2(width, GRASS_SHORT.get_height()))
	holder.add_child(strip)
	return holder


func _rock_block(pos: Vector2, size: Vector2) -> Control:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = pos
	holder.size = size
	var inner := _tiled(ROCK_DARK, Vector2(3, 3), size - Vector2(6, 6))
	inner.modulate = Color(0.8, 0.78, 0.82)
	holder.add_child(inner)
	var mh := mini(14, int(size.x / 2.0))
	var mv := mini(14, int(size.y / 2.0))
	var block := NinePatchRect.new()
	block.texture = ROCK_BLOCK
	block.region_rect = Rect2(0, 2, 96, 94)
	block.draw_center = false
	block.patch_margin_left = mh
	block.patch_margin_right = mh
	block.patch_margin_top = mv
	block.patch_margin_bottom = mv
	block.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	block.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	block.size = size
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.material = style_mat
	holder.add_child(block)
	return holder


func _skin_ground(body: Node, rect: ColorRect, style: String) -> void:
	rect.visible = false
	var pos := Vector2(rect.offset_left, rect.offset_top)
	var size := Vector2(rect.offset_right - rect.offset_left, rect.offset_bottom - rect.offset_top)
	var pit := body.name.begins_with("Pit")
	var bname := String(body.name)
	var ceiling := bname.contains("Ceiling") or bname.contains("Roof")
	if style != "cave" and (ceiling or bname.contains("Cliff")):
		body.add_child.call_deferred(_rock_block(pos, size))
		return

	match style:
		"plains", "withered", "highland":
			if pit:
				var dark := _tiled(GROUND_FILL, pos, size)
				dark.modulate = Color(0.35, 0.35, 0.42)
				body.add_child.call_deferred(dark)
			else:
				body.add_child.call_deferred(_short_grass(pos, size.x))
				var clip := Control.new()
				clip.clip_contents = true
				clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
				clip.position = pos
				clip.size = size
				clip.add_child(_tiled(GROUND_PATH, Vector2.ZERO, Vector2(size.x, GROUND_PATH.get_height())))
				var fill := _tiled(GROUND_FILL, Vector2(0, GROUND_PATH.get_height()), Vector2(size.x, maxf(size.y - GROUND_PATH.get_height(), 0.0)))
				fill.modulate = Color(0.85, 0.85, 0.85)
				clip.add_child(fill)
				body.add_child.call_deferred(clip)
		"grassrock":
			if pit:
				var dark := _tiled(ROCK_DARK, pos, size)
				dark.modulate = Color(0.6, 0.6, 0.65)
				body.add_child.call_deferred(dark)
			else:
				body.add_child.call_deferred(_rock_block(pos, size))
				body.add_child.call_deferred(_short_grass(pos + Vector2(0, 2), size.x))
		"cave":
			if pit:
				var dark := _tiled(CAVE_FILL, pos, size)
				dark.modulate = Color(0.55, 0.55, 0.6)
				body.add_child.call_deferred(dark)
			else:
				var clip := Control.new()
				clip.clip_contents = true
				clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
				clip.position = pos
				clip.size = size
				if ceiling:
					clip.add_child(_tiled(CAVE_FILL, Vector2.ZERO, Vector2(size.x, maxf(size.y - 8.0, 0.0))))
					var edge := _tiled(CAVE_TOP, Vector2(0, size.y - CAVE_TOP.get_height()), Vector2(size.x, CAVE_TOP.get_height()))
					edge.flip_v = true
					clip.add_child(edge)
				else:
					clip.add_child(_tiled(CAVE_FILL, Vector2(0, 8), Vector2(size.x, maxf(size.y - 8.0, 0.0))))
					clip.add_child(_tiled(CAVE_TOP, Vector2.ZERO, Vector2(size.x, CAVE_TOP.get_height())))
				body.add_child.call_deferred(clip)
		_:
			if pit:
				var dark := _tiled(ROCK_DARK, pos, size)
				dark.modulate = Color(0.6, 0.6, 0.65)
				body.add_child.call_deferred(dark)
			else:
				body.add_child.call_deferred(_rock_block(pos, size))


func _poly_bounds(poly: Polygon2D) -> Rect2:
	var pts := poly.polygon
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


func _restyle_spikes(poly: Polygon2D) -> void:
	if poly.polygon.size() < 3:
		return
	var b := _poly_bounds(poly)
	var style := style_at(poly.global_position.x + b.get_center().x)
	poly.visible = false
	var tex: Texture2D = HAZARD_CRYSTALS if style == "cave" else HAZARD_ROOTS
	var h := float(tex.get_height())
	var strip := _tiled(tex, Vector2(b.position.x, b.end.y - h), Vector2(b.size.x, h))
	strip.modulate = HAZARD_TINT.get(style, Color.WHITE)
	var holder := Node2D.new()
	holder.position = poly.position
	holder.z_index = 0
	holder.add_child(strip)
	poly.get_parent().add_child.call_deferred(holder)
	if style == "cave":
		var glow := _make_light(Color(0.75, 0.5, 1.0), b.size.x / 110.0)
		glow.energy = 0.3
		glow.position = poly.position + Vector2(b.get_center().x, b.end.y - h)
		poly.get_parent().add_child.call_deferred(glow)


func _ceiling_hazard(poly: Polygon2D, style: String) -> void:
	if poly.polygon.size() < 3:
		return
	var b := _poly_bounds(poly)
	poly.visible = false
	var tex: Texture2D = HAZARD_CRYSTALS_DOWN if style == "cave" else HAZARD_ROOTS
	var strip := _tiled(tex, poly.position + b.position, Vector2(b.size.x, float(tex.get_height())))
	if style != "cave":
		strip.flip_v = true
	strip.modulate = HAZARD_TINT.get(style, Color.WHITE)
	poly.add_sibling.call_deferred(strip)
	if style == "cave":
		var glow := _make_light(Color(0.75, 0.5, 1.0), b.size.x / 110.0)
		glow.energy = 0.3
		glow.position = poly.position + b.get_center()
		poly.add_sibling.call_deferred(glow)


func _make_particles(color: Color, grav: Vector2, size: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = int(40 * level_size.x / 320.0 * (0.5 if low_end else 1.0))
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = level_size / 2.0
	p.position = level_size / 2.0
	p.gravity = grav
	p.direction = Vector2(1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	p.scale_amount_min = size
	p.scale_amount_max = size
	p.color = color
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 1))
	fade.add_point(0.8, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	p.z_index = 10
	get_parent().add_child.call_deferred(p)
	return p


func _make_light(color: Color, scale_amount: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_texture_for(realism)
	l.color = color
	l.texture_scale = scale_amount
	l.energy = 0.0
	return l


func _setup_pad_light(l: PointLight2D) -> void:
	l.set_meta("cfg", true)
	l.texture = light_texture_for(realism)
	l.texture_scale *= lerpf(1.0, 1.9, realism)
	if realism >= 0.5:
		var bounce := PointLight2D.new()
		bounce.texture = l.texture
		bounce.color = Color(1.0, 0.45, 0.2)
		bounce.texture_scale = l.texture_scale * 2.2
		bounce.energy = 0.0
		bounce.add_to_group("pad_bounce")
		l.add_sibling.call_deferred(bounce)


func _process(delta: float) -> void:
	time += delta
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player:
			lantern = _make_light(Color(0.75, 0.9, 1.0), 1.1)
			lantern.position = Vector2(6, 12)
			player.add_child(lantern)

	var target := mood_start
	if player:
		var t := clampf(inverse_lerp(progress_from, progress_to, player.global_position.x), 0.0, 1.0)
		target = lerpf(mood_start, mood_end, smoothstep(0.0, 1.0, t))
		if lantern:
			var spr := player.get_node("Sprite2D") as Sprite2D
			lantern.position.x = -6.0 if spr.flip_h else 6.0
			lantern.energy = (0.9 + sin(Time.get_ticks_msec() * 0.008) * 0.05) * smoothstep(0.15, 0.6, mood)

	if night_at_x >= 0.0 and not is_night and player and player.global_position.x > night_at_x:
		_fall_night()
	if is_night:
		target = maxf(target, night_mood)

	mood = lerpf(mood, target, 1.0 - exp(-mood_speed * delta))
	if absf(mood - applied_mood) > 0.002:
		_apply(mood)
	_update_lights()


func _fall_night() -> void:
	is_night = true
	mood_speed = 0.7
	var shaker := get_tree().get_first_node_in_group("shaker")
	if shaker:
		shaker.shake(2.0)
	var msg := get_tree().get_first_node_in_group("msg_label") as Label
	if msg and night_message != "":
		msg.text = night_message
		msg.modulate.a = 0.0
		msg.visible_ratio = 1.0
		var t := create_tween()
		t.tween_property(msg, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
		t.tween_interval(1.8)
		t.tween_property(msg, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)


func _apply(m: float) -> void:
	applied_mood = m
	sky_mat.set_shader_parameter("top_color", SKY_TOP_HAPPY.lerp(SKY_TOP_GLOOMY, m))
	sky_mat.set_shader_parameter("bottom_color", SKY_BOTTOM_HAPPY.lerp(SKY_BOTTOM_GLOOMY, m))
	var ray_strength := 0.09 if ground_style == "withered" else 0.18
	rays_mat.set_shader_parameter("intensity", ray_strength * fx * (1.0 - smoothstep(0.0, 0.4, m)))
	for f in fog_mats:
		f.set_shader_parameter("fog_color", FOG_HAPPY.lerp(FOG_GLOOMY, m))
		f.set_shader_parameter("density", lerpf(0.15, 0.6, m) * lerpf(0.5, 1.0, fx))
	vignette_mat.set_shader_parameter("strength", lerpf(0.12, 0.6, m) * lerpf(0.6, 1.0, fx))
	modulate_node.color = MODULATE_HAPPY.lerp(MODULATE_GLOOMY, smoothstep(0.1, 1.0, m))
	if ground_style == "cave":
		drift.modulate.a = 1.0
	else:
		drift.modulate.a = (1.0 - smoothstep(0.1, 0.5, m)) * lerpf(0.5, 1.0, fx)
	ash.modulate.a = 0.0 if ground_style == "cave" else smoothstep(0.3, 0.8, m)
	if moon:
		moon.modulate.a = smoothstep(0.25, 0.6, m)
	sky_mat.set_shader_parameter("stars", smoothstep(0.4, 0.8, m))
	if goal_light:
		goal_light.energy = lerpf(0.3, 1.0, m)


func _update_lights() -> void:
	var m := mood
	if moon_halo:
		moon_halo.modulate.a = smoothstep(0.35, 0.75, m) * (0.85 + sin(time * 0.8) * 0.15)
	var i := 0
	for l in get_tree().get_nodes_in_group("pad_light"):
		var pl := l as PointLight2D
		if pl == null:
			continue
		if not pl.has_meta("cfg"):
			_setup_pad_light(pl)
		var flicker := 1.0 + (sin(time * 9.0 + i * 1.7) * 0.5 + sin(time * 23.0 + i * 3.1) * 0.5) * 0.1 * realism
		pl.energy = lerpf(0.25, 0.9, m) * flicker
		i += 1
	for bl in get_tree().get_nodes_in_group("pad_bounce"):
		(bl as PointLight2D).energy = lerpf(0.05, 0.3, m) * realism
