class_name ShoreTouchControls
extends Control

const TOUCH_DEVICE: int = 73
const PAD_SIZE: float = 342.0
const BUTTON_SIZE := Vector2(170, 144)
const GAP: float = 14.0
const DIRECTIONS: Dictionary[StringName, Vector2] = {
	&"left": Vector2.LEFT,
	&"right": Vector2.RIGHT,
	&"up": Vector2.UP,
	&"down": Vector2.DOWN,
}
const BUTTONS: Array[StringName] = [&"water_up", &"water_down", &"use", &"drop"]
const LABELS: Array[String] = ["Tide +", "Tide −", "Use", "Drop"]

var _pad_index: int = -1
var _button_fingers: Dictionary[int, StringName] = {}
var _pressed: Dictionary[StringName, bool] = {}
var _normal: StyleBoxFlat
var _active: StyleBoxFlat
var _pad: StyleBoxFlat
var _enabled: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_normal = _button_style(Color("163d48d9"), Color("94c9c2cf"))
	_active = _button_style(Color("f0cd89"), Color("fff2cf"))
	_pad = _button_style(Color("0c2935b8"), Color("7caeaa91"))
	resized.connect(queue_redraw)


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		release_touches()
	visible = enabled
	set_process_input(enabled)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		var point := get_global_transform_with_canvas().affine_inverse() * touch.position
		var handled := _begin_touch(touch.index, point) if touch.pressed and not touch.canceled else _end_touch(touch.index)
		if handled:
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _pad_index:
			_update_pad(get_global_transform_with_canvas().affine_inverse() * drag.position)
			get_viewport().set_input_as_handled()
		elif _button_fingers.has(drag.index):
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_IN, \
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_RESUMED:
			release_touches()


func _exit_tree() -> void:
	release_touches()


func _begin_touch(index: int, point: Vector2) -> bool:
	if _pad_index < 0 and _pad_rect().has_point(point):
		_pad_index = index
		_update_pad(point)
		return true
	for action: StringName in BUTTONS:
		if _action_rect(action).has_point(point) and not _pressed.has(action):
			_button_fingers[index] = action
			_set_action(action, true)
			return true
	return false


func _end_touch(index: int) -> bool:
	if index == _pad_index:
		_pad_index = -1
		for action: StringName in DIRECTIONS:
			_set_action(action, false)
		return true
	if _button_fingers.has(index):
		var action: StringName = _button_fingers[index]
		_button_fingers.erase(index)
		_set_action(action, false)
		return true
	return false


func _update_pad(point: Vector2) -> void:
	var offset := point - _pad_rect().get_center()
	var direction := Vector2.ZERO
	if offset.length() > 35.0:
		var octant := roundf(offset.angle() / (PI / 4.0))
		direction = Vector2.RIGHT.rotated(octant * PI / 4.0)
	for action: StringName in DIRECTIONS:
		_set_action(action, direction.dot(DIRECTIONS[action]) > 0.5)


func release_touches() -> void:
	_pad_index = -1
	_button_fingers.clear()
	for action: StringName in _pressed.keys():
		_set_action(action, false)


func _set_action(action: StringName, pressed: bool) -> void:
	if _pressed.has(action) == pressed:
		return
	if pressed:
		_pressed[action] = true
	else:
		_pressed.erase(action)
	send_action(action, pressed)
	queue_redraw()


static func send_action(action: StringName, pressed: bool) -> void:
	# One event updates Input polling and reaches the existing _input handlers.
	var event := InputEventAction.new()
	event.device = TOUCH_DEVICE
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _pad_rect() -> Rect2:
	return Rect2(0.0, size.y - PAD_SIZE, PAD_SIZE, PAD_SIZE)


func _action_rect(action: StringName) -> Rect2:
	var index := BUTTONS.find(action)
	var column := float(index % 2)
	var row := floorf(float(index) / 2.0)
	var origin := size - BUTTON_SIZE * 2.0 - Vector2.ONE * GAP
	return Rect2(origin + Vector2(column, row) * (BUTTON_SIZE + Vector2.ONE * GAP), BUTTON_SIZE)


func _draw() -> void:
	if not _enabled:
		return
	var area := _pad_rect()
	var center := area.get_center()
	draw_style_box(_pad, area)
	draw_circle(center, 24.0, Color("9fcac399"), true, -1.0, true)
	for action: StringName in DIRECTIONS:
		var direction: Vector2 = DIRECTIONS[action]
		var arrow_center := center + direction * 109.0
		var color := Color("17343d") if _pressed.has(action) else Color("edf8ee")
		var tile := Rect2(arrow_center - Vector2.ONE * 52.0, Vector2.ONE * 104.0)
		draw_style_box(_active if _pressed.has(action) else _normal, tile)
		var side := direction.orthogonal() * 19.0
		draw_colored_polygon(PackedVector2Array([
			arrow_center + direction * 24.0,
			arrow_center - direction * 12.0 + side,
			arrow_center - direction * 12.0 - side,
		]), color)
	for i in BUTTONS.size():
		var action: StringName = BUTTONS[i]
		var button := _action_rect(action)
		var pressed := _pressed.has(action)
		var color := Color("17343d") if pressed else Color("f4f8ed")
		var font := ThemeDB.fallback_font
		draw_style_box(_active if pressed else _normal, button)
		var baseline := button.get_center().y + (font.get_ascent(37) - font.get_descent(37)) / 2.0
		draw_string(font, Vector2(button.position.x, baseline), LABELS[i], HORIZONTAL_ALIGNMENT_CENTER, button.size.x, 37, color)


static func _button_style(fill: Color, outline: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	return style
