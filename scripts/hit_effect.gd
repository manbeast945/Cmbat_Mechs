extends Node2D
class_name CombatHitEffect

var heavy := false
var lifetime := 0.20
var age := 0.0

func _ready() -> void:
	z_index = 30

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var progress := clampf(age / lifetime, 0.0, 1.0)
	var alpha := 1.0 - progress
	var radius := lerpf(3.0, 16.0 if heavy else 11.0, progress)
	var color := Color(1.0, 0.56, 0.20, alpha) if heavy else Color(1.0, 0.91, 0.62, alpha)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, color, 2.5 if heavy else 1.8, true)
	for index in range(4 if not heavy else 6):
		var angle := TAU * float(index) / float(4 if not heavy else 6)
		var direction := Vector2.RIGHT.rotated(angle)
		draw_line(direction * (radius + 1.0), direction * (radius + (9.0 if heavy else 6.0)), color, 2.0, true)
