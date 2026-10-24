extends DungeonFloor

func _ready() -> void:
	var no_exits: Array[Vector2i] = []
	add_room(Vector2.ZERO, "FloorTwoEntryRoom", no_exits)
