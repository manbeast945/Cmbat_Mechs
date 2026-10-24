extends Node2D
class_name CombatTestRoom

@onready var actors: Node2D = $Actors

func _ready() -> void:
	_create_wall(Rect2(Vector2(96.0, 100.0), Vector2(1088.0, 32.0)))
	_create_wall(Rect2(Vector2(96.0, 132.0), Vector2(32.0, 456.0)))
	_create_wall(Rect2(Vector2(1152.0, 132.0), Vector2(32.0, 456.0)))
	_create_wall(Rect2(Vector2(128.0, 572.0), Vector2(1024.0, 32.0)))

func actor_container() -> Node2D:
	return actors

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
