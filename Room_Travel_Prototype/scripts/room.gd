class_name DungeonRoom
extends Node2D

@export var room_width := 1280.0
@export var room_height := 720.0
@export var open_sides: Array[Vector2i] = []

const FLOOR_COLOR := Color("#343b43")
const WALL_COLOR := Color("#76533f")
const WALL_TRIM_COLOR := Color("#b8875b")
const DOOR_GAP := 150.0
const WALL_THICKNESS := 36.0

func _ready() -> void:
	_add_floor()
	_add_horizontal_wall(-room_height * 0.5, _has_open_side(Vector2i(0, -1)))
	_add_horizontal_wall(room_height * 0.5 - WALL_THICKNESS, _has_open_side(Vector2i(0, 1)))
	_add_vertical_wall(-room_width * 0.5, _has_open_side(Vector2i(-1, 0)))
	_add_vertical_wall(room_width * 0.5 - WALL_THICKNESS, _has_open_side(Vector2i(1, 0)))
	for direction in open_sides:
		_add_black_door_void(direction)

func _has_open_side(direction: Vector2i) -> bool:
	return open_sides.has(direction)

func _add_floor() -> void:
	var floor := ColorRect.new()
	floor.name = "Floor"
	floor.position = Vector2(-room_width * 0.5, -room_height * 0.5)
	floor.size = Vector2(room_width, room_height)
	floor.color = FLOOR_COLOR
	floor.z_index = -2
	add_child(floor)

func _add_black_door_void(direction: Vector2i) -> void:
	var half_room := Vector2(room_width * 0.5, room_height * 0.5)
	var is_vertical_exit := direction.y != 0
	var center: Vector2
	var dimensions: Vector2
	if is_vertical_exit:
		center = Vector2(0.0, direction.y * (half_room.y - WALL_THICKNESS * 0.5))
		dimensions = Vector2(DOOR_GAP, WALL_THICKNESS)
	else:
		center = Vector2(direction.x * (half_room.x - WALL_THICKNESS * 0.5), 0.0)
		dimensions = Vector2(WALL_THICKNESS, DOOR_GAP)

	var visual := ColorRect.new()
	visual.name = "BlackDoorVoid"
	visual.position = center - dimensions * 0.5
	visual.size = dimensions
	visual.color = Color.BLACK
	visual.z_index = 1
	add_child(visual)

func _add_horizontal_wall(y: float, has_door: bool) -> void:
	if not has_door:
		_add_wall(Rect2(-room_width * 0.5, y, room_width, WALL_THICKNESS))
		return
	var segment_width := (room_width - DOOR_GAP) * 0.5
	_add_wall(Rect2(-room_width * 0.5, y, segment_width, WALL_THICKNESS))
	_add_wall(Rect2(DOOR_GAP * 0.5, y, segment_width, WALL_THICKNESS))

func _add_vertical_wall(x: float, has_door: bool) -> void:
	if not has_door:
		_add_wall(Rect2(x, -room_height * 0.5, WALL_THICKNESS, room_height))
		return
	var segment_height := (room_height - DOOR_GAP) * 0.5
	_add_wall(Rect2(x, -room_height * 0.5, WALL_THICKNESS, segment_height))
	_add_wall(Rect2(x, DOOR_GAP * 0.5, WALL_THICKNESS, segment_height))

func _add_wall(rect: Rect2) -> void:
	var wall := StaticBody2D.new()
	wall.position = rect.position + rect.size * 0.5
	wall.collision_layer = 1
	wall.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	wall.add_child(collision)
	var visual := ColorRect.new()
	visual.position = -rect.size * 0.5
	visual.size = rect.size
	visual.color = WALL_COLOR
	visual.z_index = 1
	wall.add_child(visual)
	var trim := ColorRect.new()
	trim.name = "WallTrim"
	trim.color = WALL_TRIM_COLOR
	trim.z_index = 2
	if rect.size.x >= rect.size.y:
		trim.position = Vector2(-rect.size.x * 0.5, rect.size.y * 0.5 - 5.0)
		trim.size = Vector2(rect.size.x, 5.0)
	else:
		trim.position = Vector2(rect.size.x * 0.5 - 5.0, -rect.size.y * 0.5)
		trim.size = Vector2(5.0, rect.size.y)
	wall.add_child(trim)
	add_child(wall)
