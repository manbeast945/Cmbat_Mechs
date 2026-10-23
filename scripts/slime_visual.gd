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
	draw_rect(Rect2(Vector2(-15.0 - lift * 0.1, lift + 1.0), Vector2(30.0 + lift * 0.2, 6.0)), Color("292632", shadow_alpha))
	var airborne := slime.movement_phase == CombatSlime.MovementPhase.HOPPING and slime.stagger_left <= 0.0
	var body_rotation := slime.hop_direction.angle() if airborne else 0.0
	var stagger_ratio := slime.stagger_left / 0.30
	var stagger_scale := Vector2.ONE.lerp(Vector2(1.18, 0.84), clampf(stagger_ratio, 0.0, 1.0) * slime.reaction_strength * 0.45)
	# Rotate around the body's center so leftward hops stay above the ground shadow.
	draw_set_transform(Vector2(0.0, -16.0), body_rotation, slime.visual_scale * Vector2(1.08, 1.08) * stagger_scale)
	# Stepped rectangles make a compact, original pixel-art slime silhouette.
	draw_rect(Rect2(-8.0, -15.0, 16.0, 3.0), OUTLINE)
	draw_rect(Rect2(-13.0, -12.0, 26.0, 3.0), OUTLINE)
	draw_rect(Rect2(-16.0, -9.0, 32.0, 15.0), OUTLINE)
	draw_rect(Rect2(-13.0, 4.0, 26.0, 10.0), OUTLINE)
	draw_rect(Rect2(-13.0, -6.0, 26.0, 12.0), slime.enemy_color)
	draw_rect(Rect2(-10.0, 4.0, 20.0, 7.0), slime.enemy_color)
	draw_rect(Rect2(-8.0, -12.0, 16.0, 3.0), slime.enemy_color)
	draw_rect(Rect2(-10.0, -7.0, 6.0, 3.0), Color("8ddd62"))
	draw_rect(Rect2(-6.0, -4.0, 4.0, 3.0), Color("8ddd62"))
	draw_rect(Rect2(-7.0, 1.0, 3.0, 3.0), FACE)
	draw_rect(Rect2(4.0, 1.0, 3.0, 3.0), FACE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(-18.0, -40.0, 36.0, 5.0), Color("292632"))
	draw_rect(Rect2(-17.0, -39.0, 34.0, 3.0), Color("35533a"))
	var health_ratio := float(slime.health) / float(slime.max_health)
	draw_rect(Rect2(-17.0, -39.0, 34.0 * health_ratio, 3.0), Color("a5dc68"))
