extends Node2D

const FIRST_LEVEL_PATH: String = "res://levels/level_1.tscn"
const END_LEVEL_PATH: String = "res://levels/level_end.tscn"

@onready var level_container: Node2D = $levelContainer
@onready var animation_player: AnimationPlayer = $SceneTransition/AnimationPlayer
@onready var level_indicator: Label = $CanvasLayer/levelIndicator
@onready var focus_menu: CanvasLayer = $AudioManager/focusMenu
@onready var menu_canvas_layer: CanvasLayer = $menuCanvasLayer
@onready var menu_controller: Control = $menuCanvasLayer/Control
@onready var hud: ShoreHUD = $ShoreHUD

var next_level_path: String
var current_level_path: String
var showing_menu: bool = false
var _intro_open: bool = true
var _transitioning: bool = true


func _ready() -> void:
	GameStats.reset_run()
	GameStats.fragments_changed.connect(hud.set_fragment_count)
	Events.load_new_level.connect(start_new_level)
	Events.restart_current_level.connect(restart_level)
	hud.begin_requested.connect(_begin)
	hud.replay_requested.connect(_replay)

	if not OS.has_feature("mobile"):
		get_window().focus_entered.connect(_on_window_focus_entered)
		get_window().focus_exited.connect(_on_window_focus_exited)

	next_level_path = FIRST_LEVEL_PATH
	_setup_new_level()
	hud.set_fragment_count(0)
	hud.show_intro()


func start_new_level(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	showing_menu = false
	next_level_path = path
	_update_interface()
	animation_player.play("fade_to_black")
	remove_active_cam()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"fade_to_black":
		_setup_new_level()
	elif anim_name == &"fade_out":
		_transitioning = false
		_update_interface()
		if current_level_path == END_LEVEL_PATH:
			hud.show_completion()


func _setup_new_level() -> void:
	var level_scene := load(next_level_path) as PackedScene
	if level_scene == null:
		push_error("Failed to load level: " + next_level_path)
		animation_player.play("fade_out")
		return

	GameStats.SFX_allowed = false
	for child: Node in level_container.get_children():
		level_container.remove_child(child)
		child.queue_free()

	var new_level: Node = level_scene.instantiate()
	level_container.add_child(new_level)
	current_level_path = next_level_path
	level_indicator.text = current_level_path
	hud.set_level_hint(current_level_path)
	_update_interface()

	Events.new_level_done_loading.emit()
	animation_player.play("fade_out")
	_unmute_sfx_temporarily()


func restart_level() -> void:
	start_new_level(current_level_path)


func _begin() -> void:
	_intro_open = false
	hud.hide_message()
	_update_interface()


func _replay() -> void:
	if _transitioning or current_level_path != END_LEVEL_PATH:
		return
	hud.hide_message()
	GameStats.reset_run()
	start_new_level(FIRST_LEVEL_PATH)


func _unmute_sfx_temporarily() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	GameStats.SFX_allowed = true


func remove_active_cam() -> void:
	for cam: PhantomCamera2D in PhantomCameraManager.get_phantom_camera_2ds():
		cam.priority = 0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu"):
		menu()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		menu()


func menu() -> void:
	if _intro_open or _transitioning or current_level_path == END_LEVEL_PATH:
		return
	showing_menu = not showing_menu
	_update_interface()
	menu_controller.play_menu_sfx(showing_menu)


func _update_interface() -> void:
	var playable := not (_intro_open or _transitioning or showing_menu or current_level_path == END_LEVEL_PATH)
	GameStats.input_blocked = not playable
	menu_canvas_layer.visible = showing_menu
	hud.set_play_state(playable, showing_menu)


func _on_window_focus_entered() -> void:
	focus_menu.visible = false


func _on_window_focus_exited() -> void:
	focus_menu.visible = true
