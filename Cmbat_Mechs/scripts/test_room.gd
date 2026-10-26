extends Node2D
class_name CombatTestRoom

enum DoorSide { LEFT, RIGHT }

signal doorway_entered(door_side: int)

const DOOR_CENTER_Y := 360.0
const DOOR_OPENING_HEIGHT := 80.0

@export var door_side: DoorSide = DoorSide.RIGHT

func _ready() -> void:
	_create_wall(Rect2(Vector2(96.0, 100.0), Vector2(1088.0, 32.0)))
	_create_side_wall(96.0, door_side == DoorSide.LEFT)
	_create_side_wall(1152.0, door_side == DoorSide.RIGHT)
	_create_wall(Rect2(Vector2(128.0, 572.0), Vector2(1024.0, 32.0)))
	_create_door_trigger()

func _create_side_wall(x: float, has_door: bool) -> void:
	if not has_door:
		_create_wall(Rect2(Vector2(x, 132.0), Vector2(32.0, 456.0)))
		return
	var opening_top := DOOR_CENTER_Y - DOOR_OPENING_HEIGHT * 0.5
	var opening_bottom := DOOR_CENTER_Y + DOOR_OPENING_HEIGHT * 0.5
	_create_wall(Rect2(Vector2(x, 132.0), Vector2(32.0, opening_top - 132.0)))
	_create_wall(Rect2(Vector2(x, opening_bottom), Vector2(32.0, 588.0 - opening_bottom)))

func _create_door_trigger() -> void:
	var doorway := Area2D.new()
	doorway.name = "RoomDoorway"
	doorway.collision_layer = 0
	doorway.collision_mask = 1
	var doorway_x := 110.0 if door_side == DoorSide.LEFT else 1170.0
	doorway.position = Vector2(doorway_x, DOOR_CENTER_Y)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(54.0, DOOR_OPENING_HEIGHT - 8.0)
	collision.shape = shape
	doorway.add_child(collision)
	doorway.body_entered.connect(_on_doorway_body_entered)
	add_child(doorway)

func _on_doorway_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		doorway_entered.emit(door_side)

func _create_wall(rect: Rect2) -> void:
	var wall := StaticBody2D.new()
	wall.position = rect.position + rect.size * 0.5
	wall.collision_layer = 4
	wall.collision_mask = 3
	add_child(wall)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	wall.add_child(collision)
