extends Node2D

const FLOOR_RECT := Rect2(Vector2(128.0, 132.0), Vector2(1024.0, 440.0))
const DOOR_CENTER_Y := 360.0
const DOOR_OPENING_HEIGHT := 80.0
const TILE_WIDTH := 32
const TILE_HEIGHT := 24

const BACKGROUND := Color("292b30")
const GROUT := Color("37383b")
const STONE_A := Color("77736d")
const STONE_B := Color("706d68")
const STONE_HIGHLIGHT := Color("928b7e")
const STONE_DARK := Color("514f4d")
const WALL_FACE := Color("625f5b")
const WALL_SIDE := Color("494847")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), BACKGROUND)
	_draw_floor()
	_draw_back_wall()
	_draw_side_walls()

func _draw_floor() -> void:
	draw_rect(FLOOR_RECT, GROUT)
	# Continue the floor through either side doorway so the passage reads as open.
	draw_rect(Rect2(Vector2(96.0, DOOR_CENTER_Y - 36.0), Vector2(32.0, 72.0)), GROUT)
	draw_rect(Rect2(Vector2(1152.0, DOOR_CENTER_Y - 36.0), Vector2(32.0, 72.0)), GROUT)
	var rows := int(FLOOR_RECT.size.y / TILE_HEIGHT)
	var columns := int(FLOOR_RECT.size.x / TILE_WIDTH)
	for row in range(rows):
		for column in range(columns):
			var tile_position := FLOOR_RECT.position + Vector2(column * TILE_WIDTH, row * TILE_HEIGHT)
			var tile_color := STONE_A if (row + column) % 2 == 0 else STONE_B
			draw_rect(Rect2(tile_position + Vector2(1.0, 1.0), Vector2(TILE_WIDTH - 2, TILE_HEIGHT - 2)), tile_color)
		# Small blocky highlights keep the floor readable without adding clutter.
			if (column * 7 + row * 11) % 9 == 0:
				draw_rect(Rect2(tile_position + Vector2(5.0, 5.0), Vector2(5.0, 2.0)), STONE_HIGHLIGHT.darkened(0.16))
			if (column * 3 + row * 5) % 13 == 0:
				draw_rect(Rect2(tile_position + Vector2(22.0, 16.0), Vector2(3.0, 2.0)), STONE_DARK.darkened(0.08))

func _draw_back_wall() -> void:
	draw_rect(Rect2(Vector2(96.0, 100.0), Vector2(1088.0, 32.0)), WALL_SIDE)
	_draw_brick_course(Vector2(80.0, 68.0), Vector2(1120.0, 16.0), 48, 0)
	_draw_brick_course(Vector2(80.0, 84.0), Vector2(1120.0, 16.0), 48, 24)
	draw_rect(Rect2(Vector2(80.0, 100.0), Vector2(1120.0, 8.0)), Color("766f64"))
	draw_rect(Rect2(Vector2(96.0, 108.0), Vector2(1088.0, 24.0)), WALL_FACE)
	draw_rect(Rect2(Vector2(96.0, 128.0), Vector2(1088.0, 4.0)), STONE_DARK)

func _draw_side_walls() -> void:
	var room := get_parent() as CombatTestRoom
	var left_has_door := room != null and room.door_side == CombatTestRoom.DoorSide.LEFT
	var right_has_door := room != null and room.door_side == CombatTestRoom.DoorSide.RIGHT
	_draw_side_wall(96.0, left_has_door)
	_draw_side_wall(1152.0, right_has_door)
	_draw_brick_course(Vector2(80.0, 116.0), Vector2(48.0, 16.0), 24, 0)
	_draw_brick_course(Vector2(1152.0, 116.0), Vector2(48.0, 16.0), 24, 0)
	if left_has_door:
		_draw_door_frame(96.0)
	if right_has_door:
		_draw_door_frame(1152.0)

func _draw_side_wall(x: float, has_door: bool) -> void:
	var opening_top := DOOR_CENTER_Y - DOOR_OPENING_HEIGHT * 0.5
	var opening_bottom := DOOR_CENTER_Y + DOOR_OPENING_HEIGHT * 0.5
	if has_door:
		draw_rect(Rect2(Vector2(x, 132.0), Vector2(32.0, opening_top - 132.0)), WALL_SIDE)
		draw_rect(Rect2(Vector2(x, opening_bottom), Vector2(32.0, 588.0 - opening_bottom)), WALL_SIDE)
	else:
		draw_rect(Rect2(Vector2(x, 132.0), Vector2(32.0, 456.0)), WALL_SIDE)
	for row in range(19):
		var y := 132.0 + float(row * 24)
		if has_door and y >= opening_top and y < opening_bottom:
			continue
		var offset := 0.0 if row % 2 == 0 else 8.0
		draw_rect(Rect2(Vector2(x, y), Vector2(32.0, 23.0)), WALL_FACE)
		draw_rect(Rect2(Vector2(x + offset, y + 11.0), Vector2(12.0, 2.0)), Color("514f4d"))

func _draw_door_frame(x: float) -> void:
	var frame := Color("8a745d")
	draw_rect(Rect2(Vector2(x - 2.0, DOOR_CENTER_Y - 43.0), Vector2(36.0, 5.0)), frame)
	draw_rect(Rect2(Vector2(x - 2.0, DOOR_CENTER_Y + 38.0), Vector2(36.0, 5.0)), frame)
	draw_rect(Rect2(Vector2(x + 28.0, DOOR_CENTER_Y - 40.0), Vector2(4.0, 80.0)), WALL_SIDE)

func _draw_brick_course(position: Vector2, size: Vector2, brick_width: int, offset: int) -> void:
	var brick_count := int(ceil((size.x + float(offset)) / float(brick_width)))
	for index in range(brick_count):
		var x := position.x + float(index * brick_width - offset)
		var brick_left := maxf(position.x, x)
		var brick_right := minf(position.x + size.x, x + float(brick_width - 2))
		if brick_right <= brick_left:
			continue
		var brick_rect := Rect2(Vector2(brick_left, position.y), Vector2(brick_right - brick_left, size.y - 2))
		draw_rect(brick_rect, WALL_FACE if index % 2 == 0 else Color("6a6762"))
		var highlight_left := maxf(brick_left + 2.0, position.x)
		var highlight_right := minf(brick_right - 2.0, position.x + size.x)
		if highlight_right > highlight_left:
			draw_rect(Rect2(Vector2(highlight_left, position.y + 2.0), Vector2(highlight_right - highlight_left, 2.0)), Color("817a70"))
