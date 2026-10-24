extends Node2D

func _draw() -> void:
	draw_rect(Rect2(Vector2(-544.0, 0.0), Vector2(1088.0, 52.0)), Color("494847"))
	for column in range(23):
		var x := -544.0 + float(column * 48)
		var offset := 24.0 if column % 2 == 1 else 0.0
		draw_rect(Rect2(Vector2(x, 2.0), Vector2(46.0, 22.0)), Color("625f5b"))
		draw_rect(Rect2(Vector2(x - offset, 26.0), Vector2(46.0, 24.0)), Color("585653"))
	draw_rect(Rect2(Vector2(-560.0, -16.0), Vector2(1120.0, 16.0)), Color("81796e"))
	draw_rect(Rect2(Vector2(-560.0, -16.0), Vector2(1120.0, 4.0)), Color("a09785"))
