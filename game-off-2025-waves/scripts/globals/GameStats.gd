extends Node
#global game stats

signal fragments_changed(count: int)

const FRAGMENT_TOTAL: int = 3

var input_blocked: bool = false
var _fragments: Dictionary[StringName, bool] = {}

var water_level : float
var SFX_allowed : bool
var water_control_unlocked : bool = true
var player_allowed_to_move : bool = true


var steps_taken : int = 0
var time_played : float = 0
var stuck_in_water_amount : int = 0 


func _process(delta: float) -> void:
	time_played += delta


func fragment_count() -> int:
	return _fragments.size()


func has_fragment(fragment_id: StringName) -> bool:
	return _fragments.has(fragment_id)


func collect_fragment(fragment_id: StringName) -> void:
	if fragment_id == &"" or has_fragment(fragment_id):
		return
	_fragments[fragment_id] = true
	fragments_changed.emit(fragment_count())


func reset_run() -> void:
	_fragments.clear()
	steps_taken = 0
	time_played = 0.0
	stuck_in_water_amount = 0
	fragments_changed.emit(0)
