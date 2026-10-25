extends Node2D
class_name CombatExplosionEffect

@export var radius := 100.0
@export var lifetime := 0.28

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
	var current_radius := lerpf(8.0, radius, progress)
	draw_circle(Vector2.ZERO, current_radius, Color(1.0, 0.36, 0.10, alpha * 0.20))
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 32, Color(1.0, 0.72, 0.24, alpha), 3.0, true)
	draw_arc(Vector2.ZERO, current_radius * 0.56, 0.0, TAU, 24, Color(1.0, 0.92, 0.66, alpha * 0.8), 2.0, true)
