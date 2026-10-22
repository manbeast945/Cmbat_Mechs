extends Node2D

const OUTLINE := Color(0.08, 0.12, 0.14)

var player: CombatPlayer

func _ready() -> void:
	player = get_parent() as CombatPlayer

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var aim := (get_global_mouse_position() - player.global_position).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	draw_colored_polygon(_ellipse(Vector2(0.0, 4.0), Vector2(19.0, 7.0)), Color(0.02, 0.025, 0.03, 0.48))
	draw_colored_polygon(_ellipse(Vector2(0.0, -4.0), Vector2(8.0, 4.0)), Color(0.10, 0.12, 0.13))
	draw_colored_polygon(_ellipse(Vector2(0.0, -19.0), Vector2(13.0, 16.0)), OUTLINE)
	draw_colored_polygon(_ellipse(Vector2(0.0, -20.0), Vector2(10.5, 13.5)), Color(0.27, 0.68, 0.74))
	draw_colored_polygon(_ellipse(Vector2(0.0, -37.0), Vector2(9.0, 9.0)), OUTLINE)
	draw_colored_polygon(_ellipse(Vector2(0.0, -38.0), Vector2(7.5, 7.5)), Color(0.83, 0.73, 0.60))
	draw_colored_polygon(_ellipse(Vector2(0.0, -42.0), Vector2(7.8, 4.8)), Color(0.20, 0.22, 0.22))
	draw_set_transform(Vector2(0.0, -37.0), aim.angle(), Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(5.0, -4.0), Vector2(15.0, 0.0), Vector2(5.0, 4.0)]), Color(0.94, 0.90, 0.78))

func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
