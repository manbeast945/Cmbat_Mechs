class_name DungeonFloor
extends Node2D

signal room_transition_requested(player_position: Vector2, camera_position: Vector2)
signal next_floor_requested(floor_scene: PackedScene)

const ROOM_SCENE: PackedScene = preload("res://scenes/room.tscn")
const ROOM_WIDTH := 1280.0
const ROOM_HEIGHT := 720.0
const DOOR_CLEARANCE := 120.0

@export var entry_marker_path: NodePath = ^"EntryPoint"

var room_doorways: Array[Area2D] = []

func get_entry_position() -> Vector2:
	var marker := get_node_or_null(entry_marker_path) as Node2D
	if marker == null:
		push_error("Floor scene is missing its EntryPoint marker.")
		return global_position
	return marker.global_position

func add_room(origin: Vector2, name: String, open_sides: Array[Vector2i]) -> DungeonRoom:
	var room := ROOM_SCENE.instantiate() as DungeonRoom
	room.name = name
	room.room_width = ROOM_WIDTH
	room.room_height = ROOM_HEIGHT
	for side in open_sides:
		room.open_sides.append(side)
	room.position = origin
	add_child(room)
	return room

func add_room_link(source_origin: Vector2, direction: Vector2i, destination_origin: Vector2) -> void:
	var doorway := Area2D.new()
	doorway.name = "RoomDoorway_%d_%d" % [direction.x, direction.y]
	doorway.add_to_group("floor_room_doorways")
	var half_room := Vector2(ROOM_WIDTH * 0.5, ROOM_HEIGHT * 0.5)
	doorway.position = source_origin + Vector2(
		direction.x * (half_room.x - 42.0),
		direction.y * (half_room.y - 42.0)
	)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(150.0, 88.0) if direction.y != 0 else Vector2(88.0, 150.0)
	collision.shape = shape
	doorway.add_child(collision)
	var destination_offset := Vector2(
		-direction.x * (half_room.x - DOOR_CLEARANCE),
		-direction.y * (half_room.y - DOOR_CLEARANCE)
	)
	doorway.body_entered.connect(_on_room_doorway_entered.bind(destination_origin + destination_offset, destination_origin))
	room_doorways.append(doorway)
	add_child(doorway)

func set_room_doors_enabled(enabled: bool) -> void:
	for doorway in room_doorways:
		doorway.monitoring = enabled

func _on_room_doorway_entered(body: Node2D, destination_position: Vector2, destination_camera: Vector2) -> void:
	if not body.is_in_group("player"):
		return
	room_transition_requested.emit(to_global(destination_position), to_global(destination_camera))
