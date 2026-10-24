extends DungeonFloor

const FLOOR_TWO_SCENE: PackedScene = preload("res://scenes/floors/floor_2/floor_2.tscn")
const STARTER_ORIGIN := Vector2(0.0, 0.0)
const BOSS_ORIGIN := Vector2(ROOM_WIDTH, 0.0)
const STAIRS_ORIGIN := Vector2(ROOM_WIDTH * 2.0, 0.0)

func _ready() -> void:
	var starter_sides: Array[Vector2i] = [Vector2i(1, 0)]
	var boss_sides: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0)]
	var stairs_sides: Array[Vector2i] = [Vector2i(-1, 0)]
	add_room(STARTER_ORIGIN, "StarterRoom", starter_sides)
	add_room(BOSS_ORIGIN, "BossRoomPlaceholder", boss_sides)
	add_room(STAIRS_ORIGIN, "StairsRoom", stairs_sides)
	add_room_link(STARTER_ORIGIN, Vector2i(1, 0), BOSS_ORIGIN)
	add_room_link(BOSS_ORIGIN, Vector2i(1, 0), STAIRS_ORIGIN)
	_add_stairs()

func _add_stairs() -> void:
	for step_index in range(6):
		var step := ColorRect.new()
		step.name = "StairStep_%d" % step_index
		step.position = STAIRS_ORIGIN + Vector2(-150.0 + step_index * 30.0, 90.0 - step_index * 30.0)
		step.size = Vector2(300.0 - step_index * 40.0, 24.0)
		step.color = Color("#92704d") if step_index % 2 == 0 else Color("#b8875b")
		step.z_index = 0
		add_child(step)
	var trigger := Area2D.new()
	trigger.name = "FloorTwoStairsTrigger"
	trigger.position = STAIRS_ORIGIN
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(320.0, 240.0)
	collision.shape = shape
	trigger.add_child(collision)
	trigger.body_entered.connect(_on_stairs_body_entered)
	add_child(trigger)

func _on_stairs_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		next_floor_requested.emit(FLOOR_TWO_SCENE)
