extends Node2D

const FLOOR_ONE_SCENE: PackedScene = preload("res://scenes/floors/floor_1/floor_1.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const TRANSITION_SECONDS := 0.38

var current_floor: DungeonFloor
var player: TemporaryDungeonPlayer
var camera: Camera2D
var transition_running := false
var doors_locked := false
var iris_material: ShaderMaterial

func _ready() -> void:
	_build_player()
	_build_camera()
	_build_iris()
	_load_initial_floor()

func _build_player() -> void:
	player = PLAYER_SCENE.instantiate() as TemporaryDungeonPlayer
	player.add_to_group("player")
	add_child(player)

func _build_camera() -> void:
	camera = Camera2D.new()
	camera.name = "RoomCamera"
	camera.enabled = true
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()

func _build_iris() -> void:
	var overlay := ColorRect.new()
	overlay.name = "IrisTransition"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := load("res://scripts/iris_transition.gdshader") as Shader
	iris_material = ShaderMaterial.new()
	iris_material.shader = shader
	iris_material.set_shader_parameter("radius", 2.0)
	overlay.material = iris_material
	var canvas := CanvasLayer.new()
	canvas.name = "TransitionLayer"
	canvas.layer = 10
	canvas.add_child(overlay)
	add_child(canvas)

func _load_initial_floor() -> void:
	current_floor = FLOOR_ONE_SCENE.instantiate() as DungeonFloor
	_connect_floor_signals(current_floor)
	add_child(current_floor)
	player.global_position = current_floor.get_entry_position()
	camera.global_position = current_floor.get_entry_position()
	current_floor.set_room_doors_enabled(true)
	doors_locked = false

func _connect_floor_signals(floor: DungeonFloor) -> void:
	floor.room_transition_requested.connect(_on_room_transition_requested)
	floor.next_floor_requested.connect(_on_next_floor_requested)

func _on_room_transition_requested(player_position: Vector2, camera_position: Vector2) -> void:
	if transition_running or doors_locked:
		return
	_transition_within_floor(player_position, camera_position)

func _transition_within_floor(player_position: Vector2, camera_position: Vector2) -> void:
	transition_running = true
	_lock_current_floor_doors()
	player.set_movement_enabled(false)
	player.velocity = Vector2.ZERO
	await _animate_iris(0.0)
	player.global_position = player_position
	player.velocity = Vector2.ZERO
	camera.global_position = camera_position
	await _animate_iris(2.0)
	player.set_movement_enabled(true)
	transition_running = false

func _on_next_floor_requested(next_floor_scene: PackedScene) -> void:
	if transition_running or next_floor_scene == null:
		return
	_transition_to_floor(next_floor_scene)

func _transition_to_floor(next_floor_scene: PackedScene) -> void:
	transition_running = true
	_lock_current_floor_doors()
	player.set_movement_enabled(false)
	player.velocity = Vector2.ZERO
	await _animate_iris(0.0)
	current_floor.queue_free()
	current_floor = next_floor_scene.instantiate() as DungeonFloor
	_connect_floor_signals(current_floor)
	add_child(current_floor)
	player.global_position = current_floor.get_entry_position()
	player.velocity = Vector2.ZERO
	camera.global_position = current_floor.get_entry_position()
	current_floor.set_room_doors_enabled(false)
	await _animate_iris(2.0)
	player.set_movement_enabled(true)
	transition_running = false

func _lock_current_floor_doors() -> void:
	doors_locked = true
	if current_floor != null:
		current_floor.set_room_doors_enabled(false)

func _unhandled_key_input(event: InputEvent) -> void:
	if not doors_locked or transition_running or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_1:
		doors_locked = false
		if current_floor != null:
			current_floor.set_room_doors_enabled(true)

func _animate_iris(target_radius: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_iris_radius, float(iris_material.get_shader_parameter("radius")), target_radius, TRANSITION_SECONDS)
	await tween.finished

func _set_iris_radius(value: float) -> void:
	iris_material.set_shader_parameter("radius", value)
