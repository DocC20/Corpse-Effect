extends Node2D

const CLOAK = preload("res://assets/player/cloak_blue.png")
const SERIF = preload("res://fonts/Lora-Variable.ttf")
const SERIF_ITALIC = preload("res://fonts/Lora-Italic-Variable.ttf")
const FAR = preload("res://assets/hollow_echo/far_bg.png")
const MID = preload("res://assets/hollow_echo/middle_bg.png")
const NEAR = preload("res://assets/hollow_echo/near_bg.png")
const TREE = preload("res://assets/country/tree.png")
const HILLS = [preload("res://assets/mossy/hill_0.png"), preload("res://assets/mossy/hill_1.png"), preload("res://assets/mossy/hill_2.png")]
const CAVE_ROCK = preload("res://assets/brown_cave/bigrock_0.png")
const CAVE_ROCK_B = preload("res://assets/brown_cave/bigrock_2.png")
const ROCK_SEAT = preload("res://assets/mossy/rock_1.png")
const BENCH_PATH := "res://assets/ending/bench.png"
const LIGHT = preload("res://assets/kenney/light/circle_b_noise.png")
const ATMO = preload("res://atmosphere.gd")
const TORSOS = [preload("res://assets/player/torso_orange.png"), preload("res://assets/player/torso_blue.png")]
const LEGS = [preload("res://assets/player/legs_orange.png"), preload("res://assets/player/legs_blue.png")]

const GROUND_Y := 146.0
const SEAT_X := 214.0
const WALK_SPEED := 24.0

const CREDITS := [
	"Corpse & Effect",
	"",
	"Made for the Bounce Back game jam",
	"",
	"Created by",
	"@Enache Andrei Christian",
	"Lead developer, concept, systems programming",
	"@Alex Ionita",
	"Lead developer, concept, gameplay programming",
	"@Rosu Tudor",
	"Visual effects, graphics, cross-platform support",
	"@Nita David",
	"Sound design, level design",
	"",
	"Art",
	"Country Platform, Caverns by ansimuz",
	"Hollow Echo by Hollow Dolphin",
	"Mossy Cavern, Brown Cave by Maaot",
	"Light masks and UI by Kenney",
	"Free PSX UI by rohhsa",
	"",
	"Sound",
	"Footsteps SFX Free by heyheythere",
	"Freesound and SFXMint contributors",
	"",
	"Music",
	"Purrple Cat",
	"Dark Fantasy Ambient Strings",
	"",
	"Font",
	"Lora by Cyreal",
]

var hero: Sprite2D
var sun: Node2D
var dusk: ColorRect
var text_layer: CanvasLayer
var line: Label
var title_root: Control
var credits_box: VBoxContainer
var prompt: Label
var t := 0.0
var sat_at := -1.0
var seat_top := 0.0
var step_timer := 0.0
var fired := {}
var leaving := false
var credits_speed := 14.0
var rain_left := 0
var rain_timer := 0.0


func _ready() -> void:
	_build_world()
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 8
	floor_body.collision_mask = 0
	var fs := CollisionShape2D.new()
	var fr := RectangleShape2D.new()
	fr.size = Vector2(500, 20)
	fs.shape = fr
	floor_body.add_child(fs)
	floor_body.position = Vector2(160, GROUND_Y + 11.0)
	add_child(floor_body)
	_build_text()


func _tex_rect(tex: Texture2D, pos: Vector2, size: Vector2, z: int, tint: Color) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = pos
	r.size = size
	r.z_index = z
	r.modulate = tint
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(r)
	return r


func _gradient(colors: Array, offsets: Array, vertical := true) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 16 if vertical else 128
	tex.height = 128 if vertical else 16
	tex.fill_from = Vector2(0.5, 0.0) if vertical else Vector2(0.0, 0.5)
	tex.fill_to = Vector2(0.5, 1.0) if vertical else Vector2(1.0, 0.5)
	return tex


func _band(tex: Texture2D, y: float, tint: Color, z: int) -> void:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(0, 180, 640, 180)
	_tex_rect(a, Vector2(0, y), Vector2(320, 90), z, tint)


func _build_world() -> void:
	_tex_rect(_gradient([Color(0.16, 0.15, 0.36), Color(0.55, 0.3, 0.48), Color(0.98, 0.5, 0.36), Color(1.0, 0.78, 0.5)], [0.0, 0.38, 0.72, 1.0]), Vector2(0, 0), Vector2(320, 140), -100, Color.WHITE)

	sun = Node2D.new()
	sun.position = Vector2(236, 88)
	sun.z_index = -95
	add_child(sun)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var glow := Sprite2D.new()
	glow.texture = LIGHT
	glow.scale = Vector2.ONE * 0.55
	glow.modulate = Color(1.0, 0.55, 0.3, 0.55)
	glow.material = add
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sun.add_child(glow)
	var disc_tex := GradientTexture2D.new()
	var dg := Gradient.new()
	dg.offsets = PackedFloat32Array([0.0, 0.45, 0.5])
	dg.colors = PackedColorArray([Color(1.0, 0.95, 0.75, 1.0), Color(1.0, 0.82, 0.5, 1.0), Color(1.0, 0.75, 0.45, 0.0)])
	disc_tex.gradient = dg
	disc_tex.fill = GradientTexture2D.FILL_RADIAL
	disc_tex.fill_from = Vector2(0.5, 0.5)
	disc_tex.fill_to = Vector2(1.0, 0.5)
	disc_tex.width = 64
	disc_tex.height = 64
	var disc := Sprite2D.new()
	disc.texture = disc_tex
	disc.scale = Vector2.ONE * 0.5
	disc.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sun.add_child(disc)

	_band(FAR, 76.0, Color(0.62, 0.4, 0.55), -94)
	_band(MID, 80.0, Color(0.42, 0.27, 0.4), -93)
	_band(NEAR, 84.0, Color(0.27, 0.18, 0.27), -92)

	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var x := 60.0
	while x < 330.0:
		var tr := Sprite2D.new()
		tr.texture = TREE
		tr.centered = false
		var ts := rng.randf_range(0.35, 0.55)
		tr.scale = Vector2.ONE * ts
		tr.flip_h = rng.randf() < 0.5
		tr.position = Vector2(x, GROUND_Y - 10.0 - TREE.get_height() * ts)
		tr.modulate = Color(0.2, 0.14, 0.22)
		tr.z_index = -91
		add_child(tr)
		x += rng.randf_range(40.0, 90.0)

	x = -20.0
	while x < 330.0:
		var hill := Sprite2D.new()
		hill.texture = HILLS[rng.randi() % HILLS.size()]
		hill.centered = false
		var hs := rng.randf_range(0.3, 0.45)
		hill.scale = Vector2.ONE * hs
		hill.flip_h = rng.randf() < 0.5
		hill.position = Vector2(x, GROUND_Y + 6.0 - hill.texture.get_height() * hs)
		hill.modulate = Color(0.3, 0.28, 0.2)
		hill.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		hill.z_index = -90
		add_child(hill)
		x += hill.texture.get_width() * hs * rng.randf_range(0.6, 0.9)

	dusk = ColorRect.new()
	dusk.color = Color(0.08, 0.06, 0.2, 0.0)
	dusk.size = Vector2(320, 180)
	dusk.z_index = 8
	dusk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dusk)

	_tex_rect(_gradient([Color(0.3, 0.26, 0.12), Color(0.14, 0.11, 0.07), Color(0.05, 0.04, 0.035)], [0.0, 0.35, 1.0]), Vector2(-10, GROUND_Y - 1.0), Vector2(340, 182.0 - GROUND_Y + 1.0), 0, Color.WHITE)

	for spec in [[CAVE_ROCK, Vector2(-72, GROUND_Y + 8.0), 0.75], [CAVE_ROCK_B, Vector2(30, GROUND_Y + 4.0), 0.45]]:
		var tex: Texture2D = spec[0]
		var sc: float = spec[2]
		var rock := Sprite2D.new()
		rock.texture = tex
		rock.centered = false
		rock.scale = Vector2.ONE * sc
		rock.position = spec[1] - Vector2(0, tex.get_height() * sc)
		rock.modulate = Color(0.32, 0.24, 0.24)
		rock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		rock.z_index = 3
		add_child(rock)
	var shade := GradientTexture2D.new()
	shade.gradient = _gradient([Color(0.02, 0.01, 0.03, 0.95), Color(0.02, 0.01, 0.03, 0.7), Color(0.02, 0.01, 0.03, 0.0)], [0.0, 0.45, 1.0]).gradient
	shade.fill = GradientTexture2D.FILL_RADIAL
	shade.fill_from = Vector2(0.5, 0.5)
	shade.fill_to = Vector2(1.0, 0.5)
	shade.width = 64
	shade.height = 64
	_tex_rect(shade, Vector2(-70, GROUND_Y - 80.0), Vector2(150, 110), 5, Color.WHITE)

	var seat_tex: Texture2D = ROCK_SEAT
	var seat_scale := 0.3
	if ResourceLoader.exists(BENCH_PATH):
		seat_tex = load(BENCH_PATH)
		seat_scale = 30.0 / float(seat_tex.get_width())
	var seat := Sprite2D.new()
	seat.texture = seat_tex
	seat.centered = false
	seat.scale = Vector2.ONE * seat_scale
	var seat_h := seat_tex.get_height() * seat_scale
	seat.position = Vector2(SEAT_X - seat_tex.get_width() * seat_scale / 2.0, GROUND_Y + 2.0 - seat_h)
	seat.modulate = Color(0.85, 0.75, 0.62)
	seat.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	seat.z_index = 3
	add_child(seat)
	seat_top = GROUND_Y + 2.0 - seat_h * 0.82

	hero = Sprite2D.new()
	hero.texture = CLOAK
	hero.hframes = 8
	hero.vframes = 5
	hero.offset = Vector2(0, -20)
	hero.scale = Vector2.ONE * 0.5
	hero.position = Vector2(-6, GROUND_Y)
	hero.modulate = Color(1.0, 0.9, 0.82)
	hero.z_index = 4
	add_child(hero)

	var keys := ["green_blades", "green_blades", "moss_wind", "fern", "moss_reed"]
	x = -8.0
	while x < 330.0:
		var g := _plant("green_blades", Vector2(x, GROUND_Y + 2.0), rng.randf_range(0.14, 0.2), rng, Color(0.85, 0.8, 0.5))
		g.z_index = 1
		x += rng.randf_range(3.0, 6.0)
	x = 30.0
	while x < 330.0:
		if absf(x - SEAT_X) > 16.0:
			var p := _plant(keys[rng.randi() % keys.size()], Vector2(x, GROUND_Y + 3.0), rng.randf_range(0.2, 0.3), rng, Color(1.0, 0.82, 0.62))
			p.z_index = 1
		x += rng.randf_range(6.0, 13.0)
	x = -10.0
	while x < 330.0:
		var f := _plant(keys[rng.randi() % keys.size()], Vector2(x, 186.0), rng.randf_range(0.6, 0.85), rng, Color(0.42, 0.3, 0.28))
		f.z_index = 7
		x += rng.randf_range(14.0, 30.0)

	var motes := CPUParticles2D.new()
	motes.amount = 30
	motes.lifetime = 8.0
	motes.preprocess = 8.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(170, 40)
	motes.position = Vector2(160, 110)
	motes.gravity = Vector2(1, -1)
	motes.spread = 180.0
	motes.initial_velocity_min = 1.0
	motes.initial_velocity_max = 5.0
	motes.tangential_accel_min = -6.0
	motes.tangential_accel_max = 6.0
	motes.color = Color(1.0, 0.85, 0.55)
	var mf := Gradient.new()
	mf.set_color(0, Color(1, 1, 1, 0))
	mf.add_point(0.3, Color(1, 1, 1, 0.9))
	mf.set_color(mf.get_point_count() - 1, Color(1, 1, 1, 0))
	motes.color_ramp = mf
	motes.z_index = 6
	add_child(motes)


func _plant(key: String, foot: Vector2, s: float, rng: RandomNumberGenerator, tint: Color) -> AnimatedSprite2D:
	var p := AnimatedSprite2D.new()
	p.sprite_frames = ATMO.plant_frames(key)
	var h := float(p.sprite_frames.get_frame_texture("default", 0).get_height())
	p.offset = Vector2(0, -h / 2.0)
	p.position = foot
	p.scale = Vector2.ONE * s
	p.flip_h = rng.randf() < 0.5
	p.modulate = tint
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(p)
	p.play("default")
	p.frame = rng.randi() % p.sprite_frames.get_frame_count("default")
	p.speed_scale = rng.randf_range(0.5, 0.9)
	return p


func _label(font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 2
	ls.outline_color = Color(0.1, 0.05, 0.12, 0.45)
	ls.shadow_color = Color(0, 0, 0, 0.45)
	ls.shadow_offset = Vector2(0.5, 0.5)
	l.label_settings = ls
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.modulate.a = 0.0
	return l


func _build_text() -> void:
	text_layer = CanvasLayer.new()
	text_layer.layer = 5
	add_child(text_layer)
	line = _label(SERIF_ITALIC, 9, Color(1.0, 0.96, 0.9))
	line.position = Vector2(20, 22)
	line.size = Vector2(280, 30)
	text_layer.add_child(line)
	prompt = _label(SERIF_ITALIC, 6, Color(1.0, 0.95, 0.9))
	prompt.position = Vector2(20, 166)
	prompt.size = Vector2(280, 12)
	prompt.text = "Press any key to return"
	text_layer.add_child(prompt)


func _say(text: String, hold: float) -> void:
	line.text = text
	line.visible_ratio = 0.0
	var tw := create_tween()
	tw.tween_property(line, "modulate:a", 1.0, 0.6)
	tw.parallel().tween_property(line, "visible_ratio", 1.0, maxf(0.5, text.length() * 0.035))
	tw.tween_interval(hold)
	tw.tween_property(line, "modulate:a", 0.0, 0.7)


func _show_title() -> void:
	title_root = Control.new()
	title_root.size = Vector2(320, 180)
	title_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_layer.add_child(title_root)
	var title := _label(SERIF, 18, Color(1.0, 0.92, 0.78))
	title.text = "Corpse & Effect"
	title.position = Vector2(20, 30)
	title.size = Vector2(280, 28)
	title_root.add_child(title)
	var sub := _label(SERIF_ITALIC, 8, Color(1.0, 0.96, 0.92))
	sub.text = "Thank you for playing."
	sub.position = Vector2(20, 56)
	sub.size = Vector2(280, 14)
	title_root.add_child(sub)
	var tw := create_tween()
	tw.tween_property(title, "modulate:a", 1.0, 1.2)
	tw.tween_property(sub, "modulate:a", 1.0, 1.0)
	tw.tween_interval(3.0)
	tw.tween_property(title_root, "modulate:a", 0.0, 1.0)


func _start_credits() -> void:
	credits_box = VBoxContainer.new()
	credits_box.add_theme_constant_override("separation", 1)
	credits_box.position = Vector2(60, 182)
	credits_box.size = Vector2(200, 10)
	text_layer.add_child(credits_box)
	for i in CREDITS.size():
		var text: String = CREDITS[i]
		var is_name := text.begins_with("@")
		if is_name:
			text = text.substr(1)
		var heading: bool = i == 0 or (text != "" and CREDITS[i - 1] == "")
		var size := 8 if i == 0 else (7 if heading or is_name else 6)
		var col := Color(1.0, 0.97, 0.94)
		if heading:
			col = Color(1.0, 0.92, 0.8)
		elif is_name:
			col = Color(1.0, 0.8, 0.55)
		var l := _label(SERIF if heading or is_name else SERIF_ITALIC, size, col)
		l.modulate.a = 1.0
		l.text = text
		l.custom_minimum_size = Vector2(200, 5 if text == "" else size + 3)
		if is_name and i > 0 and CREDITS[i - 1] != "" and not CREDITS[i - 1].begins_with("Created"):
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(200, 3)
			credits_box.add_child(gap)
		credits_box.add_child(l)


func _soul(pos: Vector2) -> void:
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var s := Sprite2D.new()
	s.texture = ATMO.light_texture()
	s.material = add
	s.scale = Vector2.ONE * randf_range(0.03, 0.05)
	s.modulate = Color(1.0, 0.62, 0.3, 0.0)
	s.position = pos
	s.z_index = 5
	add_child(s)
	var dur := randf_range(6.0, 9.0)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.95, 0.6)
	tw.parallel().tween_property(s, "position", pos + Vector2(randf_range(-30.0, 30.0), -pos.y - 20.0), dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 2.0).set_delay(dur - 2.0)
	tw.tween_callback(s.queue_free)


func _part(tex: Texture2D, pos: Vector2, shape_size: Vector2, tint: Color) -> RigidBody2D:
	var b := RigidBody2D.new()
	b.collision_layer = 8
	b.collision_mask = 8
	b.mass = 0.2
	b.linear_damp = 0.3
	b.angular_damp = 1.5
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.25
	mat.friction = 0.9
	b.physics_material_override = mat
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = shape_size
	cs.shape = rect
	b.add_child(cs)
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.scale = Vector2.ONE * 0.5
	sp.modulate = tint
	b.add_child(sp)
	b.position = pos
	b.z_index = 2
	add_child(b)
	return b


func _spawn_ragdoll() -> void:
	var x := randf_range(56.0, 312.0)
	if absf(x - SEAT_X) < 24.0:
		x = SEAT_X + (30.0 if randf() < 0.5 else -30.0)
	var start := Vector2(x, randf_range(-40.0, -12.0))
	var kind := randi() % 2
	var tint := Color(1.0, 0.72, 0.5)
	var torso := _part(TORSOS[kind], start, Vector2(7, 13), tint)
	var legs := _part(LEGS[kind], start + Vector2(0.25, 8.5), Vector2(5, 5), tint)
	torso.angular_velocity = randf_range(-7.0, 7.0)
	torso.linear_velocity = Vector2(randf_range(-25.0, 25.0), randf_range(0.0, 40.0))
	legs.linear_velocity = torso.linear_velocity
	var joint := PinJoint2D.new()
	joint.position = start + Vector2(0, 6.0)
	joint.softness = 0.4
	add_child(joint)
	joint.node_a = joint.get_path_to(torso)
	joint.node_b = joint.get_path_to(legs)
	torso.contact_monitor = true
	torso.max_contacts_reported = 1
	var on_hit := func(_b: Node) -> void:
		if not torso.has_meta("landed"):
			torso.set_meta("landed", true)
			Game.sfx("land", 0.15, 0.18, 0.75)
	torso.body_entered.connect(on_hit)
	var life := randf_range(4.0, 6.5)
	var tw := create_tween()
	tw.tween_interval(life)
	tw.tween_callback(func() -> void: _soul(torso.global_position + Vector2(0, -4)))
	tw.parallel().tween_property(torso, "modulate:a", 0.0, 1.2)
	tw.parallel().tween_property(legs, "modulate:a", 0.0, 1.2)
	tw.tween_callback(joint.queue_free)
	tw.tween_callback(torso.queue_free)
	tw.tween_callback(legs.queue_free)


func _once(key: String) -> bool:
	if fired.has(key):
		return false
	fired[key] = true
	return true


func _process(delta: float) -> void:
	t += delta
	var k := clampf(t / 55.0, 0.0, 1.0)
	sun.position = Vector2(236, 88).lerp(Vector2(246, 126), k)
	dusk.color.a = smoothstep(0.35, 1.0, k) * 0.4

	if sat_at < 0.0:
		hero.position.x += WALK_SPEED * delta
		hero.frame = 8 + int(t * 8.0) % 8
		step_timer -= delta
		if step_timer <= 0.0 and hero.position.x > 6.0:
			step_timer = 0.45
			Game.sfx("step_grass", 0.1, 0.25)
		if hero.position.x >= SEAT_X - 2.0:
			_sit()
		return

	var s := t - sat_at
	hero.frame = 32 + int(t * 4.0) % 4
	if s > 1.0 and _once("l1"):
		var deaths: int = Game.total_deaths
		var first := "You fell %d times." % deaths
		if deaths == 1:
			first = "You fell once."
		elif deaths == 0:
			first = "You never fell. Not once."
		_say(first, 2.4)
	if s > 4.6 and _once("rain"):
		rain_left = clampi(Game.total_deaths, 8, 26)
	if rain_left > 0:
		rain_timer -= delta
		if rain_timer <= 0.0:
			rain_timer = randf_range(0.12, 0.3)
			rain_left -= 1
			_spawn_ragdoll()
	if s > 5.2 and _once("l2"):
		_say("Every time, something of you stayed behind", 2.4)
	if s > 9.4 and _once("l3"):
		_say("and lifted you a little higher.", 2.4)
	if s > 13.6 and _once("l4"):
		_say("You bounced back.", 3.0)
	if s > 19.0 and _once("title"):
		_show_title()
	if s > 26.5 and _once("credits"):
		_start_credits()
	if credits_box:
		credits_box.position.y -= credits_speed * delta
		if credits_box.position.y + credits_box.size.y < -10.0:
			credits_box.queue_free()
			credits_box = null
			fired["credits_done"] = true
	if (fired.has("credits_done") or s > 60.0) and _once("prompt"):
		create_tween().tween_property(prompt, "modulate:a", 1.0, 0.8)
	if s > 90.0:
		_leave()


func _sit() -> void:
	sat_at = t
	hero.position = Vector2(SEAT_X, seat_top + 3.5)
	hero.frame = 32
	hero.scale = Vector2(0.55, 0.45)
	create_tween().tween_property(hero, "scale", Vector2.ONE * 0.5, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if t < 2.0:
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_leave()


func _leave() -> void:
	if leaving:
		return
	leaving = true
	var ui := get_tree().get_first_node_in_group("shaker")
	if ui and ui.has_method("fade_out"):
		await ui.fade_out()
	Game.load_scene("res://menu.tscn")
