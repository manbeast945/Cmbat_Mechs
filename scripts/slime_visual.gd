extends Node2D

const OUTLINE := Color(0.09, 0.27, 0.12)
const FACE := Color(0.07, 0.18, 0.09)

var slime: CombatSlime

func _ready() -> void:
	slime = get_parent() as CombatSlime

func _process(_delta: float) -> void:
	if slime == null:
		return
	var airborne := slime.movement_phase == CombatSlime.MovementPhase.HOPPING and slime.stagger_left <= 0.0
	var lift := slime.visual_lift if airborne else 0.0
	position = Vector2(0.0, -lift)
	rotation = 0.0
	scale = Vector2.ONE
	var flash_duration := 0.12 if slime.reaction_strength >= 1.0 else 0.08
	var flash_ratio := slime.hit_flash_left / flash_duration
	modulate = Color.WHITE.lerp(Color(1.0, 0.56, 0.36), clampf(flash_ratio, 0.0, 1.0))
	queue_redraw()

func _draw() -> void:
	if slime == null:
		return
	var lift := -position.y
	var shadow_alpha := 0.48 - minf(lift / 12.0, 0.24)
	draw_colored_polygon(_ellipse(Vector2(0.0, lift + 4.0), Vector2(18.0 + lift * 0.15, 6.0)), Color(0.02, 0.025, 0.03, shadow_alpha))
	var airborne := slime.movement_phase == CombatSlime.MovementPhase.HOPPING and slime.stagger_left <= 0.0
	var body_rotation := slime.hop_direction.angle() if airborne else 0.0
	var stagger_ratio := slime.stagger_left / 0.30
	var stagger_scale := Vector2.ONE.lerp(Vector2(1.18, 0.84), clampf(stagger_ratio, 0.0, 1.0) * slime.reaction_strength * 0.45)
	# Rotate around the body's center so leftward hops stay above the ground shadow.
	draw_set_transform(Vector2(0.0, -16.0), body_rotation, slime.visual_scale * stagger_scale)
	draw_colored_polygon(_ellipse(Vector2(0.0, 1.0), Vector2(18.0, 14.0)), OUTLINE)
	draw_colored_polygon(_ellipse(Vector2.ZERO, Vector2(15.5, 11.5)), slime.enemy_color)
	draw_colored_polygon(_ellipse(Vector2(-4.5, -4.0), Vector2(5.0, 3.2)), Color(0.62, 0.91, 0.52, 0.6))
	draw_circle(Vector2(-4.5, 2.0), 1.5, FACE)
	draw_circle(Vector2(4.5, 2.0), 1.5, FACE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(-17.0, -39.0, 34.0, 5.0), Color(0.10, 0.10, 0.10))
	var health_ratio := float(slime.health) / float(slime.max_health)
	draw_rect(Rect2(-16.0, -38.0, 32.0 * health_ratio, 3.0), Color(0.56, 0.91, 0.47))

func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
