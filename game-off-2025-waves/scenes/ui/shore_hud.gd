class_name ShoreHUD
extends CanvasLayer

signal begin_requested
signal replay_requested

const TITLE_FONT: Font = preload("res://misc/BoldPixels.ttf")
const CREAM := Color("f7f0df")
const GOLD := Color("f4cc82")
const PALE := Color("cbded9")
const INK := Color("122c36")
const BORDER := Color("8bc5bc")
const CARD := Color("142f3cf5")
const EDGE: float = 46.0

var touch_mode: bool
var touch_controls: ShoreTouchControls
var _safe: Control
var _fragment_pill: PanelContainer
var _fragment_label: Label
var _hint_pill: PanelContainer
var _hint_label: Label
var _menu_button: Button
var _modal: Control
var _heading: Label
var _description: Label
var _controls_hint: Label
var _continue_button: Button
var _replay: bool = false


func _ready() -> void:
	touch_mode = OS.has_feature("mobile") or "--touch-controls" in OS.get_cmdline_user_args()
	_safe = Control.new()
	_safe.name = "SafeArea"
	_safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe)
	_make_header()
	touch_controls = ShoreTouchControls.new()
	touch_controls.name = "TouchControls"
	_safe.add_child(touch_controls)
	touch_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch_controls.set_enabled(false)
	_make_modal()
	get_viewport().size_changed.connect(_layout_safe_area)
	_layout_safe_area()


func _layout_safe_area() -> void:
	var bounds := get_viewport().get_visible_rect()
	if OS.has_feature("mobile"):
		var display_safe := Rect2(DisplayServer.get_display_safe_area())
		if display_safe.has_area():
			var to_viewport := get_viewport().get_screen_transform().affine_inverse()
			var clipped := bounds.intersection(to_viewport * display_safe)
			if clipped.has_area():
				bounds = clipped
	_safe.position = bounds.position + Vector2.ONE * EDGE
	_safe.size = bounds.size - Vector2.ONE * EDGE * 2.0


func set_fragment_count(count: int) -> void:
	_fragment_label.text = "Map fragments   %d/%d" % [count, GameStats.FRAGMENT_TOTAL]


func set_level_hint(path: String) -> void:
	var level_name := path.get_file().get_basename()
	var hint: String
	match level_name:
		"level_1":
			hint = "Walk onto the map fragment to collect it."
		"level_3":
			hint = "Board the raft. Raise the tide to reach the far bank." if touch_mode else "Board the raft. Press ↑ to reach the far bank."
		"level_6":
			hint = "Stand beside an obelisk and tap Use." if touch_mode else "Stand beside an obelisk and press E."
		"level_9":
			hint = "Tap Drop to set a carried item on a pressure plate." if touch_mode else "Press Q to set a carried item on a pressure plate."
		"level_11":
			hint = "Find the last fragment and solve the exit locks."
	_hint_label.text = hint
	_hint_pill.visible = not hint.is_empty()


func set_play_state(playable: bool, menu_open: bool) -> void:
	touch_controls.set_enabled(playable and touch_mode)
	_fragment_pill.visible = playable
	_hint_pill.visible = playable and not _hint_label.text.is_empty()
	_menu_button.visible = playable or menu_open
	_menu_button.text = "Resume" if menu_open else "Menu"


func show_intro() -> void:
	_replay = false
	_heading.text = "Lost at Low Tide"
	_description.text = "You're a stranded cartographer. Shift the tides and recover three map fragments to chart your way home."
	_controls_hint.text = "Move with the pad. Tap Tide + or Tide − to shift the water." if touch_mode else "WASD to move  •  ↑ / ↓ to shift the tide  •  E to use  •  Q to drop"
	_controls_hint.show()
	_continue_button.text = "Begin"
	_modal.show()
	_focus_continue()


func show_completion() -> void:
	_replay = true
	_heading.text = "Route found"
	_description.text = "You recovered all three map fragments and charted your way home."
	_controls_hint.hide()
	_continue_button.text = "Play again"
	_modal.show()
	_focus_continue()


func hide_message() -> void:
	_modal.hide()


func _focus_continue() -> void:
	if not touch_mode:
		_continue_button.grab_focus()


func _continue() -> void:
	if _replay:
		replay_requested.emit()
	else:
		begin_requested.emit()


func _make_header() -> void:
	_fragment_pill = PanelContainer.new()
	_fragment_pill.name = "Fragments"
	_fragment_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fragment_pill.add_theme_stylebox_override("panel", _panel(CARD, GOLD, 22.0))
	_safe.add_child(_fragment_pill)
	_fragment_label = _label("", 39, CREAM)
	_fragment_pill.add_child(_fragment_label)

	_hint_pill = PanelContainer.new()
	_hint_pill.name = "TutorialHint"
	_hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_pill.add_theme_stylebox_override("panel", _panel(CARD, BORDER, 17.0))
	_safe.add_child(_hint_pill)
	_hint_pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_hint_pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_label = _label("", 31, PALE)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.custom_minimum_size.x = 900.0
	_hint_pill.add_child(_hint_label)

	_menu_button = _button("Menu", 38)
	_menu_button.name = "Menu"
	_menu_button.custom_minimum_size = Vector2(170, 132)
	_menu_button.focus_mode = Control.FOCUS_NONE
	if OS.has_feature("mobile"):
		_menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe.add_child(_menu_button)
	_menu_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_menu_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_menu_button.pressed.connect(_send_menu)


func _input(event: InputEvent) -> void:
	if not OS.has_feature("mobile") or not _menu_button.visible or not event is InputEventScreenTouch:
		return
	var touch: InputEventScreenTouch = event
	if touch.pressed and not touch.canceled and _menu_button.get_global_rect().has_point(touch.position):
		_send_menu()
		get_viewport().set_input_as_handled()


func _send_menu() -> void:
	ShoreTouchControls.send_action(&"menu", true)
	ShoreTouchControls.send_action(&"menu", false)


func _make_modal() -> void:
	var overlay := ColorRect.new()
	overlay.name = "Story"
	overlay.color = Color("071d2aca")
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal = overlay

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel(CARD, GOLD, 56.0))
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 900.0
	content.add_theme_constant_override("separation", 28)
	panel.add_child(content)

	_heading = _label("", 86, GOLD)
	_heading.add_theme_font_override("font", TITLE_FONT)
	content.add_child(_heading)

	_description = _label("", 45, CREAM)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_description)

	_controls_hint = _label("", 31, PALE)
	_controls_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_controls_hint)

	_continue_button = _button("Begin", 45)
	_continue_button.custom_minimum_size = Vector2(330.0, 122.0)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.pressed.connect(_continue)
	content.add_child(_continue_button)


func _button(button_text: String, font_size: int) -> Button:
	var button := Button.new()
	button.text = button_text
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_stylebox_override("normal", _panel(GOLD, CREAM, 14.0))
	button.add_theme_stylebox_override("hover", _panel(CREAM, GOLD, 14.0))
	button.add_theme_stylebox_override("pressed", _panel(PALE, BORDER, 14.0))
	return button


func _label(label_text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel(fill: Color, outline: Color, padding: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(padding)
	style.shadow_color = Color("07192470")
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 6)
	return style
