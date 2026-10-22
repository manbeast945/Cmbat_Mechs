extends Node2D

const OUTLINE := Color(0.15, 0.09, 0.09)

var enemy: CombatEnemy

func _ready() -> void:
	enemy = get_parent() as CombatEnemy

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_colored_polygon(_ellipse(Vector2(0.0, 4.0), Vector2(19.0, 7.0)), Color(0.02, 0.025, 0.03, 0.48))
	draw_colored_polygon(_ellipse(Vector2(0.0, -4.0), Vector2(8.0, 4.0)), Color(0.16, 0.10, 0.10))
	draw_colored_polygon(_ellipse(Vector2(0.0, -17.0), Vector2(13.0, 16.0)), OUTLINE)
	draw_colored_polygon(_ellipse(Vector2(0.0, -18.0), Vector2(10.5, 13.5)), Color(0.67, 0.30, 0.30))
	draw_colored_polygon(_ellipse(Vector2(0.0, -34.0), Vector2(9.0, 9.0)), OUTLINE)
	draw_colored_polygon(_ellipse(Vector2(0.0, -35.0), Vector2(7.5, 7.5)), Color(0.77, 0.56, 0.49))
	draw_circle(Vector2(-3.0, -35.0), 1.3, Color(0.14, 0.08, 0.08))
	draw_circle(Vector2(3.0, -35.0), 1.3, Color(0.14, 0.08, 0.08))
	draw_rect(Rect2(-18.0, -53.0, 36.0, 5.0), Color(0.10, 0.10, 0.10))
	var health_ratio := float(enemy.health) / float(enemy.max_health)
	draw_rect(Rect2(-17.0, -52.0, 34.0 * health_ratio, 3.0), Color(0.88, 0.43, 0.36))

func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
