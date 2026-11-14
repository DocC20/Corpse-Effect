class_name Atmosphere
extends Node2D

@export var mood_start := 0.0
@export var mood_end := 0.55
@export var progress_from := 40.0
@export var progress_to := 300.0
@export var level_size := Vector2(320, 180)
@export_enum("plains", "withered", "highland", "grassrock", "hills", "cave", "ruins", "moss") var ground_style := "plains"
@export_enum("none", "plains", "withered", "highland", "grassrock", "hills", "cave", "ruins", "moss") var ground_style_b := "none"
@export var style_switch_x := -1.0
@export_range(0.0, 1.0) var realism := 0.0
@export_range(0.0, 1.0) var fx := 1.0
@export_range(-1.0, 1.0) var wither := -1.0
@export var level_number := 1
@export var trees: Array[Vector2] = []
@export var night_at_x := -1.0
@export var night_mood := 0.75
@export var night_message := "Night falls."
@export var light_shaft_x := -1.0
@export var plant_density := 1.0

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
const RUIN_BLOCK = preload("res://assets/hollow_echo/ruin_block.png")
const RUIN_FILL = preload("res://assets/hollow_echo/ruin_fill.png")
const RUIN_LAYERS = [
	preload("res://assets/hollow_echo/bg.png"),
	preload("res://assets/hollow_echo/far_bg.png"),
	preload("res://assets/hollow_echo/middle_bg.png"),
	preload("res://assets/hollow_echo/near_bg.png"),
]
const RUIN_VINES = [preload("res://assets/hollow_echo/vine_a.png"), preload("res://assets/hollow_echo/vine_b.png")]
const MOSS_BLOCK = preload("res://assets/mossy/moss_block.png")
const MOSS_THORNS = preload("res://assets/mossy/thorns.png")
const MOSS_THORNS_DOWN = preload("res://assets/mossy/thorns_down.png")
const MOSS_HILLS = [preload("res://assets/mossy/hill_0.png"), preload("res://assets/mossy/hill_1.png"), preload("res://assets/mossy/hill_2.png")]
const MOSS_HANGS = [preload("res://assets/mossy/hang_0.png"), preload("res://assets/mossy/hang_1.png"), preload("res://assets/mossy/hang_2.png"), preload("res://assets/mossy/hang_3.png")]
const MOSS_ROCKS = [preload("res://assets/mossy/rock_0.png"), preload("res://assets/mossy/rock_1.png"), preload("res://assets/mossy/rock_2.png")]
const BIG_ROCKS = [preload("res://assets/brown_cave/bigrock_0.png"), preload("res://assets/brown_cave/bigrock_1.png"), preload("res://assets/brown_cave/bigrock_2.png")]
const PLANT_SHEETS = {
	"dry_grass": [preload("res://assets/plants/dry_grass.png"), 15],
	"dry_curl": [preload("res://assets/plants/dry_curl.png"), 15],
	"dry_tuft": [preload("res://assets/plants/dry_tuft.png"), 15],
	"moss_reed": [preload("res://assets/plants/moss_reed.png"), 23],
	"moss_tall": [preload("res://assets/plants/moss_tall.png"), 15],
	"moss_wind": [preload("res://assets/plants/moss_wind.png"), 15],
	"moss_bush": [preload("res://assets/plants/moss_bush.png"), 23],
	"glow_flower": [preload("res://assets/plants/glow_flower.png"), 15],
	"green_blades": [preload("res://assets/plants/green_blades.png"), 23],
	"fern": [preload("res://assets/plants/fern.png"), 20],
}
const SURFACES = {
	"plains": "grass",
	"withered": "leaves",
	"highland": "grass",
	"grassrock": "gravel",
	"hills": "gravel",
	"cave": "stone",
	"ruins": "sneaker",
	"moss": "mud",
}
const MODULATE_RUINS = Color(0.5, 0.62, 0.85)
const MODULATE_MOSS = Color(0.5, 0.66, 0.6)

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
	"ruins": Color(0.55, 0.9, 1.0),
	"moss": Color(0.9, 1.0, 0.9),
}

const TREE_SCALE = 1.35

static var _light_tex: Texture2D
static var carried_mood := -1.0
static var _light_tex_stepped: Texture2D
static var _plant_frames := {}

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
var butterflies: CPUParticles2D
var fireflies: CPUParticles2D
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


func surface_at(x: float) -> String:
	return SURFACES.get(style_at(x), "stone")


static func underground(style: String) -> bool:
	return style == "cave" or style == "ruins" or style == "moss"


func dread() -> float:
	return clampf((level_number - 1) / 9.0 + smoothstep(0.55, 0.95, mood) * 0.15, 0.0, 1.0)


func _is_grassy(style: String) -> bool:
	return style == "plains" or style == "withered" or style == "highland"


func _is_boundary(body: Node, rect: ColorRect) -> bool:
	if not body.name.begins_with("Wall"):
		return false
	var gx: float = body.global_position.x
	return gx + rect.offset_right <= 1.0 or gx + rect.offset_left >= level_size.x - 1.0


func _has_cave() -> bool:
	return underground(ground_style) or underground(ground_style_b)


func _ready() -> void:
	add_to_group("atmosphere")
	low_end = OS.has_feature("mobile") or OS.has_feature("web")
	var root := get_parent()
	var cave := underground(ground_style)
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
	var w := wither if wither >= 0.0 else (0.65 if ground_style == "withered" else 0.0)
	style_mat.set_shader_parameter("wither", w)

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
		"ruins":
			drift = _make_particles(Color(0.5, 0.85, 1.0), Vector2(0, -2), 1.0)
		"moss":
			drift = _make_particles(Color(0.65, 1.0, 0.6), Vector2(1, -2), 1.0)
		_:
			drift = _make_particles(Color(1.0, 0.92, 0.6), Vector2(0, -3), 1.0)
	ash = _make_particles(Color(0.7, 0.75, 0.88), Vector2(0, 9), 1.5)

	var x_end := level_size.x + 32.0
	if ground_style == "ruins":
		_add_ruins_backdrop(root, -32.0, x_end)
	elif ground_style == "moss":
		_add_moss_backdrop(root, -32.0, x_end)
	elif ground_style == "cave" and (ground_style_b == "none" or ground_style_b == "" or style_switch_x < 0.0):
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
			if rect and not _is_boundary(child, rect):
				_skin_ground(child, rect, style_at(child.global_position.x))
			for sub in child.get_children():
				if sub is Polygon2D:
					_ceiling_hazard(sub as Polygon2D, style_at(child.global_position.x))
		elif child is Polygon2D:
			_restyle_spikes(child as Polygon2D)

	_decorate(root)
	if not underground(ground_style):
		_add_details(root)
	else:
		_add_drips(root)
	if light_shaft_x >= 0.0:
		_add_light_shaft(root, light_shaft_x)

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

	root.add_child.call_deferred(_gradient_rect(Vector2(x - 120.0, -40.0), Vector2(120, level_size.y + 80.0), Color(dark, 0.0), Color(dark, 0.92), -20))
	root.add_child.call_deferred(_gradient_rect(Vector2(x, -40.0), Vector2(200, level_size.y + 80.0), Color(dark, 0.92), Color(dark, 0.0), -20))
	var ground_fade := _gradient_rect(Vector2(x - 50.0, floor_y - 30.0), Vector2(100, 70), Color(dark, 0.0), Color(dark, 0.55), 2)
	root.add_child.call_deferred(ground_fade)

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


func _side_shade(pos: Vector2, size: Vector2) -> Node2D:
	var holder := Node2D.new()
	holder.z_index = 1
	var w := minf(10.0, size.x * 0.25)
	var dark := Color(0.05, 0.06, 0.04)
	holder.add_child(_gradient_rect(pos + Vector2(0, 6), Vector2(w, size.y - 6), Color(dark, 0.5), Color(dark, 0.0), 0))
	holder.add_child(_gradient_rect(pos + Vector2(size.x - w, 6), Vector2(w, size.y - 6), Color(dark, 0.0), Color(dark, 0.5), 0))
	var top := _gradient_rect(pos + Vector2(0, 16), Vector2(size.x, 1), Color(dark, 0.0), Color(dark, 0.0), 0)
	top.visible = false
	holder.add_child(top)
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
	block.region_rect = Rect2(2, 2, 92, 92)
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
	if not underground(style) and (ceiling or (bname.contains("Cliff") and _has_cave())):
		body.add_child.call_deferred(_rock_block(pos, size))
		return

	match style:
		"ruins":
			if pit:
				var dark := _tiled(RUIN_FILL, pos, size)
				dark.modulate = Color(0.5, 0.5, 0.6)
				body.add_child.call_deferred(dark)
			else:
				body.add_child.call_deferred(_nine(RUIN_BLOCK, pos, size, 16, 1.0))
		"moss":
			if pit:
				var dark := ColorRect.new()
				dark.color = Color(0.02, 0.03, 0.02)
				dark.position = pos
				dark.size = size
				dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
				body.add_child.call_deferred(dark)
			else:
				var holder := _nine(MOSS_BLOCK, pos - Vector2(3, 3), size + Vector2(6, 6), 128, 0.25, true)
				holder.z_index = 1
				body.add_child.call_deferred(holder)
		"plains", "withered", "highland":
			if pit:
				var dark := _tiled(GROUND_FILL, pos, size)
				dark.modulate = Color(0.35, 0.35, 0.42)
				body.add_child.call_deferred(dark)
			else:
				body.add_child.call_deferred(_short_grass(pos - Vector2(4, 0), size.x + 8.0))
				body.add_child.call_deferred(_side_shade(pos, size))
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
	var tex: Texture2D = HAZARD_ROOTS
	if style == "cave" or style == "ruins":
		tex = HAZARD_CRYSTALS
	elif style == "moss":
		tex = MOSS_THORNS
	var h := float(tex.get_height())
	var strip := _tiled(tex, Vector2(b.position.x, b.end.y - h), Vector2(b.size.x, h))
	strip.modulate = HAZARD_TINT.get(style, Color.WHITE)
	if style == "moss":
		strip.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var holder := Node2D.new()
	holder.position = poly.position
	holder.z_index = 0
	holder.add_child(strip)
	poly.get_parent().add_child.call_deferred(holder)
	if style == "cave" or style == "ruins":
		var glow := _make_light(Color(0.75, 0.5, 1.0) if style == "cave" else Color(0.4, 0.85, 1.0), b.size.x / 110.0)
		glow.energy = 0.3
		glow.position = poly.position + Vector2(b.get_center().x, b.end.y - h)
		poly.get_parent().add_child.call_deferred(glow)


func _ceiling_hazard(poly: Polygon2D, style: String) -> void:
	if poly.polygon.size() < 3:
		return
	var b := _poly_bounds(poly)
	poly.visible = false
	var tex: Texture2D = HAZARD_ROOTS
	if style == "cave" or style == "ruins":
		tex = HAZARD_CRYSTALS_DOWN
	elif style == "moss":
		tex = MOSS_THORNS_DOWN
	var strip := _tiled(tex, poly.position + b.position, Vector2(b.size.x, float(tex.get_height())))
	if not underground(style):
		strip.flip_v = true
	strip.modulate = HAZARD_TINT.get(style, Color.WHITE)
	if style == "moss":
		strip.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	poly.add_sibling.call_deferred(strip)
	if style == "cave" or style == "ruins":
		var glow := _make_light(Color(0.75, 0.5, 1.0) if style == "cave" else Color(0.4, 0.85, 1.0), b.size.x / 110.0)
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
	_bend_plants(delta)
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
	var gloomy := MODULATE_GLOOMY
	if ground_style == "ruins":
		gloomy = MODULATE_RUINS
	elif ground_style == "moss":
		gloomy = MODULATE_MOSS
	modulate_node.color = MODULATE_HAPPY.lerp(gloomy, smoothstep(0.1, 1.0, m))
	if underground(ground_style):
		drift.modulate.a = 1.0
	else:
		drift.modulate.a = (1.0 - smoothstep(0.1, 0.5, m)) * lerpf(0.5, 1.0, fx)
	ash.modulate.a = 0.0 if underground(ground_style) else smoothstep(0.3, 0.8, m)
	if moon:
		moon.modulate.a = smoothstep(0.25, 0.6, m)
	if butterflies:
		butterflies.modulate.a = 1.0 - smoothstep(0.2, 0.45, m)
	if fireflies:
		fireflies.modulate.a = smoothstep(0.35, 0.7, m)
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
	for dl in get_tree().get_nodes_in_group("deco_light"):
		var d := dl as PointLight2D
		d.energy = float(d.get_meta("glow", 0.5)) * lerpf(0.4, 1.0, m) * (0.9 + sin(time * 1.7 + d.position.x) * 0.1)


func _nine(tex: Texture2D, pos: Vector2, size: Vector2, margin: int, s: float, smooth := false) -> Control:
	var holder := Control.new()
	if smooth:
		holder.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = pos
	holder.size = size / s
	holder.scale = Vector2.ONE * s
	var inner_size := size / s
	var mh := mini(margin, int(inner_size.x / 2.0))
	var mv := mini(margin, int(inner_size.y / 2.0))
	var block := NinePatchRect.new()
	block.texture = tex
	block.patch_margin_left = mh
	block.patch_margin_right = mh
	block.patch_margin_top = mv
	block.patch_margin_bottom = mv
	block.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	block.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	block.size = inner_size
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.material = style_mat
	holder.add_child(block)
	return holder


func _add_ruins_backdrop(root: Node, x0: float, x1: float) -> void:
	for i in RUIN_LAYERS.size():
		var tex: Texture2D = RUIN_LAYERS[i]
		var r := TextureRect.new()
		r.texture = tex
		r.stretch_mode = TextureRect.STRETCH_TILE
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		r.position = Vector2(x0, 0)
		r.size = Vector2((x1 - x0) * 2.0, tex.get_height())
		r.scale = Vector2(0.5, 0.5)
		r.z_index = -96 + i
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.material = style_mat
		root.add_child.call_deferred(r)


func _add_moss_backdrop(root: Node, x0: float, x1: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = level_number * 131
	var x := x0
	while x < x1:
		var rock := Sprite2D.new()
		rock.texture = BIG_ROCKS[rng.randi() % BIG_ROCKS.size()]
		rock.centered = false
		var s := rng.randf_range(0.55, 0.85)
		rock.scale = Vector2.ONE * s
		rock.flip_h = rng.randf() < 0.5
		rock.position = Vector2(x, level_size.y + 8.0 - rock.texture.get_height() * s)
		rock.modulate = Color(0.2, 0.18, 0.17)
		rock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		rock.z_index = -95
		root.add_child.call_deferred(rock)
		x += rock.texture.get_width() * s * rng.randf_range(0.6, 0.9)
	x = x0
	while x < x1:
		var hill := Sprite2D.new()
		hill.texture = MOSS_HILLS[rng.randi() % MOSS_HILLS.size()]
		hill.centered = false
		var s2 := rng.randf_range(0.4, 0.65)
		hill.scale = Vector2.ONE * s2
		hill.flip_h = rng.randf() < 0.5
		hill.position = Vector2(x, level_size.y + 6.0 - hill.texture.get_height() * s2)
		hill.modulate = Color(0.24, 0.36, 0.28)
		hill.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		hill.z_index = -94
		root.add_child.call_deferred(hill)
		x += hill.texture.get_width() * s2 * rng.randf_range(0.7, 1.1)
	x = x0
	while x < x1:
		var hang := Sprite2D.new()
		hang.texture = MOSS_HANGS[rng.randi() % MOSS_HANGS.size()]
		hang.centered = false
		var s3 := rng.randf_range(0.3, 0.5)
		hang.scale = Vector2.ONE * s3
		hang.position = Vector2(x, -4.0)
		hang.modulate = Color(0.3, 0.42, 0.34)
		hang.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		hang.z_index = -93
		root.add_child.call_deferred(hang)
		x += rng.randf_range(18.0, 46.0)


static func plant_frames(key: String) -> SpriteFrames:
	if _plant_frames.has(key):
		return _plant_frames[key]
	var spec: Array = PLANT_SHEETS[key]
	var sheet: Texture2D = spec[0]
	var n: int = spec[1]
	var w := sheet.get_width() / n
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", 12.0)
	sf.set_animation_loop("default", true)
	for i in n:
		var a := AtlasTexture.new()
		a.atlas = sheet
		a.region = Rect2(i * w, 0, w, sheet.get_height())
		sf.add_frame("default", a)
	_plant_frames[key] = sf
	return sf


func make_plant(key: String, foot: Vector2, s: float, rng: RandomNumberGenerator) -> AnimatedSprite2D:
	var p := AnimatedSprite2D.new()
	p.sprite_frames = plant_frames(key)
	var h := float(p.sprite_frames.get_frame_texture("default", 0).get_height())
	p.offset = Vector2(0, -h / 2.0)
	p.position = foot
	p.scale = Vector2.ONE * s
	p.flip_h = rng.randf() < 0.5
	p.z_index = -4
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	p.material = style_mat
	p.play("default")
	p.add_to_group("plant")
	p.frame = rng.randi() % p.sprite_frames.get_frame_count("default")
	p.speed_scale = rng.randf_range(0.7, 1.2)
	return p


func _decorate(root: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = level_number * 977 + 5
	var flower_lights := 0
	for child in root.get_children():
		if not (child is StaticBody2D):
			continue
		var rect := child.get_node_or_null("ColorRect") as ColorRect
		if rect == null or _is_boundary(child, rect):
			continue
		var bname := String(child.name)
		if bname.begins_with("Pit") or bname.begins_with("Wall"):
			continue
		var gx: float = child.global_position.x
		var gy: float = child.global_position.y
		var x0: float = gx + rect.offset_left
		var x1: float = gx + rect.offset_right
		var top: float = gy + rect.offset_top
		var bottom: float = gy + rect.offset_bottom
		var style := style_at(gx)
		var ceiling := bname.contains("Ceiling") or bname.contains("Roof")
		if ceiling:
			if style == "moss":
				var hx := x0 + rng.randf_range(4.0, 20.0)
				while hx < x1 - 4.0:
					var hang := Sprite2D.new()
					hang.texture = MOSS_HANGS[rng.randi() % MOSS_HANGS.size()]
					hang.centered = false
					var hs := rng.randf_range(0.18, 0.3)
					hang.scale = Vector2.ONE * hs
					hang.position = Vector2(hx - hang.texture.get_width() * hs / 2.0, bottom - 3.0)
					hang.z_index = -3
					hang.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
					hang.material = style_mat
					root.add_child.call_deferred(hang)
					hx += rng.randf_range(16.0, 40.0)
			elif style == "ruins":
				var vx := x0 + rng.randf_range(6.0, 30.0)
				while vx < x1 - 8.0:
					var vine := Sprite2D.new()
					vine.texture = RUIN_VINES[rng.randi() % RUIN_VINES.size()]
					vine.centered = false
					vine.position = Vector2(vx, bottom - 1.0)
					vine.z_index = -3
					root.add_child.call_deferred(vine)
					vx += rng.randf_range(30.0, 70.0)
			continue
		if top < 4.0:
			continue
		var spacing := 0.0
		var keys: Array = []
		var s := 0.5
		match style:
			"plains":
				spacing = 34.0
				keys = ["green_blades", "green_blades", "fern", "moss_wind"]
				s = 0.32
			"withered":
				spacing = 40.0
				keys = ["dry_grass", "dry_curl", "dry_tuft", "fern"]
				s = 0.38
			"highland":
				spacing = 50.0
				keys = ["dry_grass", "dry_tuft", "green_blades", "fern"]
				s = 0.36
			"grassrock", "hills":
				spacing = 120.0
				keys = ["dry_tuft", "dry_curl"]
				s = 0.38
			"moss":
				spacing = 26.0
				keys = ["moss_reed", "moss_tall", "moss_wind", "moss_bush", "glow_flower"]
				s = 0.42
		if spacing <= 0.0 or plant_density <= 0.0:
			continue
		spacing /= plant_density
		var px := x0 + rng.randf_range(3.0, spacing)
		while px < x1 - 3.0:
			var key: String = keys[rng.randi() % keys.size()]
			var plant := make_plant(key, Vector2(px, top + 3.0), s * rng.randf_range(0.8, 1.15), rng)
			root.add_child.call_deferred(plant)
			if key == "glow_flower" and flower_lights < 8:
				flower_lights += 1
				var gl := _make_light(Color(0.45, 0.85, 1.0), 0.35)
				gl.position = Vector2(px, top - 18.0)
				gl.set_meta("glow", 0.6)
				gl.add_to_group("deco_light")
				root.add_child.call_deferred(gl)
			px += spacing * rng.randf_range(0.6, 1.4)
		if style == "moss" and x1 - x0 > 50.0 and rng.randf() < 0.5:
			var rock := Sprite2D.new()
			rock.texture = MOSS_ROCKS[rng.randi() % MOSS_ROCKS.size()]
			var rs := rng.randf_range(0.28, 0.38)
			rock.scale = Vector2.ONE * rs
			rock.offset = Vector2(0, -rock.texture.get_height() / 2.0)
			rock.position = Vector2(rng.randf_range(x0 + 14.0, x1 - 14.0), top + 4.0)
			rock.z_index = -6
			rock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			rock.material = style_mat
			root.add_child.call_deferred(rock)
		if style == "ruins" and x1 - x0 > 60.0 and rng.randf() < 0.6:
			var cr := Sprite2D.new()
			cr.texture = preload("res://assets/hollow_echo/crystal.png")
			cr.offset = Vector2(0, -cr.texture.get_height() / 2.0)
			cr.scale = Vector2.ONE * 0.5
			cr.position = Vector2(rng.randf_range(x0 + 10.0, x1 - 10.0), top + 1.0)
			cr.z_index = -4
			root.add_child.call_deferred(cr)
			var cl := _make_light(Color(0.4, 0.8, 1.0), 0.4)
			cl.position = cr.position + Vector2(0, -8)
			cl.set_meta("glow", 0.5)
			cl.add_to_group("deco_light")
			root.add_child.call_deferred(cl)


func _add_light_shaft(root: Node, x: float) -> void:
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for spec in [[70.0, 0.22], [34.0, 0.4]]:
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.86, 0.55, spec[1]))
		g.set_color(1, Color(1.0, 0.86, 0.55, 0.0))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill_from = Vector2(0.5, 0.0)
		tex.fill_to = Vector2(0.5, 1.0)
		tex.width = 8
		tex.height = 64
		var beam := TextureRect.new()
		beam.texture = tex
		beam.stretch_mode = TextureRect.STRETCH_SCALE
		beam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		beam.size = Vector2(spec[0], level_size.y + 20.0)
		beam.position = Vector2(x - spec[0] / 2.0, -20.0)
		beam.material = add
		beam.z_index = 2
		beam.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child.call_deferred(beam)
	var sun := _make_light(Color(1.0, 0.82, 0.5), 1.6)
	sun.position = Vector2(x, 10)
	sun.set_meta("glow", 1.0)
	sun.add_to_group("deco_light")
	root.add_child.call_deferred(sun)
	var motes := CPUParticles2D.new()
	motes.amount = 18
	motes.lifetime = 5.0
	motes.preprocess = 5.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(14, 60)
	motes.position = Vector2(x, 60)
	motes.gravity = Vector2(0, 3)
	motes.initial_velocity_min = 1.0
	motes.initial_velocity_max = 4.0
	motes.spread = 180.0
	motes.color = Color(1.0, 0.9, 0.6)
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.3, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	motes.color_ramp = fade
	motes.z_index = 3
	root.add_child.call_deferred(motes)


func _add_details(root: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = level_number * 53 + 11
	var grassy := _is_grassy(ground_style)
	if grassy:
		var x := rng.randf_range(-20.0, 40.0)
		while x < level_size.x + 20.0:
			var t := Sprite2D.new()
			t.texture = TREE
			t.centered = false
			var ts := rng.randf_range(0.55, 0.85)
			t.scale = Vector2.ONE * ts
			t.flip_h = rng.randf() < 0.5
			t.position = Vector2(x, level_size.y - 22.0 - TREE.get_height() * ts)
			var fade := rng.randf_range(0.45, 0.6)
			t.modulate = Color(0.62, 0.72, 0.85).lerp(Color(1, 1, 1), 1.0 - fade) * Color(1, 1, 1, 0.85)
			if ground_style == "withered":
				t.modulate = Color(0.75, 0.62, 0.48, 0.8)
			t.z_index = -93
			t.material = style_mat
			root.add_child.call_deferred(t)
			x += rng.randf_range(70.0, 140.0)
	if ground_style == "plains" or ground_style == "highland":
		butterflies = CPUParticles2D.new()
		butterflies.amount = int(clampf(level_size.x / 40.0, 6.0, 20.0))
		butterflies.lifetime = 7.0
		butterflies.preprocess = 7.0
		butterflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		butterflies.emission_rect_extents = Vector2(level_size.x / 2.0, 40.0)
		butterflies.position = Vector2(level_size.x / 2.0, 100.0)
		butterflies.direction = Vector2(1, -0.3)
		butterflies.spread = 180.0
		butterflies.gravity = Vector2.ZERO
		butterflies.initial_velocity_min = 6.0
		butterflies.initial_velocity_max = 14.0
		butterflies.tangential_accel_min = -40.0
		butterflies.tangential_accel_max = 40.0
		butterflies.scale_amount_min = 1.0
		butterflies.scale_amount_max = 1.6
		butterflies.color = Color(1.0, 0.92, 0.55)
		butterflies.hue_variation_min = -0.35
		butterflies.hue_variation_max = 0.35
		var bf := Gradient.new()
		bf.set_color(0, Color(1, 1, 1, 0))
		bf.add_point(0.15, Color(1, 1, 1, 1))
		bf.add_point(0.85, Color(1, 1, 1, 1))
		bf.set_color(bf.get_point_count() - 1, Color(1, 1, 1, 0))
		butterflies.color_ramp = bf
		butterflies.z_index = 6
		root.add_child.call_deferred(butterflies)
	if grassy or ground_style == "grassrock":
		fireflies = CPUParticles2D.new()
		fireflies.amount = int(clampf(level_size.x / 25.0, 10.0, 30.0))
		fireflies.lifetime = 5.0
		fireflies.preprocess = 5.0
		fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		fireflies.emission_rect_extents = Vector2(level_size.x / 2.0, 30.0)
		fireflies.position = Vector2(level_size.x / 2.0, 118.0)
		fireflies.spread = 180.0
		fireflies.gravity = Vector2(0, -1)
		fireflies.initial_velocity_min = 2.0
		fireflies.initial_velocity_max = 6.0
		fireflies.tangential_accel_min = -12.0
		fireflies.tangential_accel_max = 12.0
		fireflies.scale_amount_min = 1.0
		fireflies.scale_amount_max = 1.0
		fireflies.color = Color(1.0, 0.95, 0.55)
		var ff := Gradient.new()
		ff.set_color(0, Color(1, 1, 1, 0))
		ff.add_point(0.3, Color(1, 1, 1, 1))
		ff.add_point(0.5, Color(1, 1, 1, 0.3))
		ff.add_point(0.7, Color(1, 1, 1, 1))
		ff.set_color(ff.get_point_count() - 1, Color(1, 1, 1, 0))
		fireflies.color_ramp = ff
		fireflies.z_index = 6
		fireflies.modulate.a = 0.0
		root.add_child.call_deferred(fireflies)


func _bend_plants(delta: float) -> void:
	if player == null:
		return
	var feet: Vector2 = player.global_position + Vector2(0, 16)
	var vel: Vector2 = player.get("velocity")
	var vx: float = vel.x
	var k := 1.0 - exp(-10.0 * delta)
	for n in get_tree().get_nodes_in_group("plant"):
		var p := n as Node2D
		var dx := p.global_position.x - feet.x
		var dy := absf(p.global_position.y - feet.y)
		var target := 0.0
		if absf(dx) < 14.0 and dy < 10.0:
			var push := 1.0 - absf(dx) / 14.0
			target = signf(dx if absf(vx) < 5.0 else vx) * 0.45 * push
		p.skew = lerpf(p.skew, target, k)


func _add_drips(root: Node) -> void:
	var drips := CPUParticles2D.new()
	drips.amount = int(clampf(level_size.x / 60.0, 4.0, 14.0))
	drips.lifetime = 1.2
	drips.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	drips.emission_rect_extents = Vector2(level_size.x / 2.0, 1.0)
	drips.position = Vector2(level_size.x / 2.0, 12.0)
	drips.direction = Vector2.DOWN
	drips.spread = 0.0
	drips.gravity = Vector2(0, 260)
	drips.initial_velocity_min = 0.0
	drips.initial_velocity_max = 5.0
	drips.scale_amount_min = 1.0
	drips.scale_amount_max = 1.0
	drips.randomness = 1.0
	var c := Color(0.6, 0.75, 1.0)
	if ground_style == "moss":
		c = Color(0.65, 0.95, 0.75)
	drips.color = c
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.add_point(0.1, Color(1, 1, 1, 0.8))
	g.add_point(0.7, Color(1, 1, 1, 0.5))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0.0))
	drips.color_ramp = g
	drips.z_index = 5
	root.add_child.call_deferred(drips)
