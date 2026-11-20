class_name TideFootprints
extends Node2D

const LIFETIME: float = 7.0
const MAX_MARKS: int = 24
const WASH_DURATION: float = 0.45

class Footprint:
	var position: Vector2
	var angle: float
	var remaining: float = LIFETIME

var _marks: Array[Footprint] = []
var _foot_side: float = 1.0


func _ready() -> void:
	global_position = Vector2.ZERO
	Events.water_level_changed.connect(_on_water_level_changed)
	set_process(false)


func leave_mark(point: Vector2, heading: Vector2) -> void:
	var mark := Footprint.new()
	mark.position = point - heading * 5.0 + heading.orthogonal() * _foot_side * 3.0
	mark.angle = heading.angle()
	_foot_side = -_foot_side
	if _marks.size() >= MAX_MARKS:
		_marks.pop_front()
	_marks.append(mark)
	set_process(true)
	queue_redraw()


func _on_water_level_changed(_height: int) -> void:
	for mark: Footprint in _marks:
		mark.remaining = minf(mark.remaining, WASH_DURATION)


func _process(delta: float) -> void:
	for mark: Footprint in _marks:
		mark.remaining -= delta
	_marks = _marks.filter(func(mark: Footprint) -> bool: return mark.remaining > 0.0)
	set_process(not _marks.is_empty())
	queue_redraw()


func _draw() -> void:
	for mark: Footprint in _marks:
		var ink := Color(0.12, 0.17, 0.16, 0.53 * clampf(mark.remaining, 0.0, 1.0))
		draw_set_transform(mark.position, mark.angle)
		draw_rect(Rect2(-1.6, -1.1, 3.2, 2.2), ink)
