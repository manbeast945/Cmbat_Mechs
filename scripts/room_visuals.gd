extends Node2D

const FLOOR_RECT := Rect2(Vector2(128.0, 132.0), Vector2(1024.0, 440.0))
const TILE_SIZE := Vector2(64.0, 32.0)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color(0.085, 0.09, 0.095))
	_draw_floor()
	_draw_back_wall()
	_draw_side_walls()

func _draw_floor() -> void:
	draw_rect(FLOOR_RECT, Color(0.43, 0.43, 0.40))
	var rows := int(FLOOR_RECT.size.y / TILE_SIZE.y)
	var columns := int(FLOOR_RECT.size.x / TILE_SIZE.x)
	for row in range(rows):
		for column in range(columns):
			var shade := 0.015 if (row + column) % 2 == 0 else -0.012
			var tile_color := Color(0.47 + shade, 0.46 + shade, 0.42 + shade)
			var tile_position := FLOOR_RECT.position + Vector2(column, row) * TILE_SIZE
			draw_rect(Rect2(tile_position, TILE_SIZE - Vector2.ONE), tile_color)
	for x in range(int(FLOOR_RECT.position.x), int(FLOOR_RECT.end.x) + 1, int(TILE_SIZE.x)):
		draw_line(Vector2(x, FLOOR_RECT.position.y), Vector2(x, FLOOR_RECT.end.y), Color(0.28, 0.29, 0.28, 0.32), 1.0)
	for y in range(int(FLOOR_RECT.position.y), int(FLOOR_RECT.end.y) + 1, int(TILE_SIZE.y)):
		draw_line(Vector2(FLOOR_RECT.position.x, y), Vector2(FLOOR_RECT.end.x, y), Color(0.28, 0.29, 0.28, 0.32), 1.0)

func _draw_back_wall() -> void:
	draw_rect(Rect2(Vector2(96.0, 100.0), Vector2(1088.0, 32.0)), Color(0.30, 0.31, 0.31))
	draw_rect(Rect2(Vector2(80.0, 68.0), Vector2(1120.0, 32.0)), Color(0.52, 0.51, 0.47))
	draw_line(Vector2(80.0, 100.0), Vector2(1200.0, 100.0), Color(0.68, 0.65, 0.59), 2.0)
	draw_line(Vector2(96.0, 132.0), Vector2(1184.0, 132.0), Color(0.22, 0.23, 0.23), 2.0)

func _draw_side_walls() -> void:
	draw_rect(Rect2(Vector2(96.0, 132.0), Vector2(32.0, 456.0)), Color(0.29, 0.30, 0.30))
	draw_rect(Rect2(Vector2(1152.0, 132.0), Vector2(32.0, 456.0)), Color(0.29, 0.30, 0.30))
	draw_rect(Rect2(Vector2(80.0, 116.0), Vector2(48.0, 16.0)), Color(0.50, 0.49, 0.45))
	draw_rect(Rect2(Vector2(1152.0, 116.0), Vector2(48.0, 16.0)), Color(0.50, 0.49, 0.45))
	draw_line(Vector2(128.0, 132.0), Vector2(128.0, 588.0), Color(0.20, 0.21, 0.21), 2.0)
	draw_line(Vector2(1152.0, 132.0), Vector2(1152.0, 588.0), Color(0.20, 0.21, 0.21), 2.0)
