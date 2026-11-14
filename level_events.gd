extends Node

@export var darken_per_death := 0.04
@export var max_extra := 0.25

var atm: Node = null
var player: Node = null
var base_start := 0.0
var base_end := 0.0


func _process(_delta: float) -> void:
	if atm == null:
		atm = get_tree().get_first_node_in_group("atmosphere")
		if atm:
			base_start = atm.mood_start
			base_end = atm.mood_end
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if atm and player:
		var extra := minf(player.deaths * darken_per_death, max_extra)
		atm.mood_start = base_start + extra
		atm.mood_end = base_end + extra
