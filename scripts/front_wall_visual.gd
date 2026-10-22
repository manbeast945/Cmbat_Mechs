extends Node2D

func _draw() -> void:
	draw_rect(Rect2(Vector2(-544.0, 0.0), Vector2(1088.0, 52.0)), Color(0.28, 0.29, 0.29))
	draw_rect(Rect2(Vector2(-560.0, -14.0), Vector2(1120.0, 16.0)), Color(0.50, 0.49, 0.45))
	draw_line(Vector2(-560.0, 0.0), Vector2(560.0, 0.0), Color(0.68, 0.65, 0.59), 2.0)
