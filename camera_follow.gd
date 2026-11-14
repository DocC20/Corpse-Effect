extends Camera2D

@export var bounds := Rect2(0, 0, 640, 180)
@export var screen_size := Vector2(320, 180)
@export var smoothing := 6.0
@export var look_ahead := 24.0

var target: CharacterBody2D


func _ready() -> void:
	global_position = screen_size / 2.0
	make_current.call_deferred()
	_fit_screen_layers.call_deferred()


func _fit_screen_layers() -> void:
	for c in get_tree().current_scene.get_children():
		if c is CanvasLayer and c.layer == 2:
			for r in c.get_children():
				if r is ColorRect:
					r.size = screen_size


func _process(delta: float) -> void:
	if not is_current():
		make_current()
	if target == null:
		target = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if target:
			global_position.x = _clamp_x(target.global_position.x)
		return
	var ahead := signf(target.velocity.x) * look_ahead * minf(1.0, absf(target.velocity.x) / 90.0)
	var x := lerpf(global_position.x, _clamp_x(target.global_position.x + ahead), 1.0 - exp(-smoothing * delta))
	global_position = Vector2(roundf(x), screen_size.y / 2.0)


func _clamp_x(x: float) -> float:
	return clampf(x, bounds.position.x + screen_size.x / 2.0, bounds.end.x - screen_size.x / 2.0)
