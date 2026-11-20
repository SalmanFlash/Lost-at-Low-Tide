class_name MapFragment
extends Area2D

@export var fragment_id: StringName

var _collected: bool = false
var _time: float = 0.0


func _ready() -> void:
	if GameStats.has_fragment(fragment_id):
		queue_free()
		return
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _collected or GameStats.input_blocked or not body.is_in_group(&"player"):
		return
	_collected = true
	GameStats.collect_fragment(fragment_id)
	queue_free()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var paper := Vector2(0.0, -16.0 + sin(_time * 3.0) * 2.5)
	draw_ellipse_shadow()
	var outline := PackedVector2Array([
		paper + Vector2(-9, -7), paper + Vector2(-1, -5), paper + Vector2(8, -9),
		paper + Vector2(9, 4), paper + Vector2(0, 8), paper + Vector2(-9, 5),
	])
	draw_colored_polygon(outline, Color("f6d99b"))
	draw_polyline(PackedVector2Array([
		outline[0], outline[1], outline[2], outline[3], outline[4], outline[5], outline[0],
	]), Color("4e4239"), 1.0)
	draw_polyline(PackedVector2Array([
		paper + Vector2(-5, 2), paper + Vector2(-1, -1), paper + Vector2(2, 1), paper + Vector2(6, -4),
	]), Color("966349"), 1.4)
	var spark := paper + Vector2(13, -9)
	draw_line(spark - Vector2(2, 0), spark + Vector2(2, 0), Color("fff2cf"), 1.0)
	draw_line(spark - Vector2(0, 2), spark + Vector2(0, 2), Color("fff2cf"), 1.0)


func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 11.0, Color("1b30487f"))
	draw_set_transform(Vector2.ZERO)
