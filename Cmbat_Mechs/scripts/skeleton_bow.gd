extends Node2D
class_name CombatSkeletonBow

const ARROW_SCENE: PackedScene = preload("res://scenes/projectile.tscn")

@export var projectile_speed := 540.0
@export var arrow_damage := 12
@export var shot_cooldown_seconds := 1.15

var cooldown_left := 0.0
var aim_direction := Vector2.RIGHT

func _process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	rotation = aim_direction.angle()
	queue_redraw()

func can_fire() -> bool:
	return cooldown_left <= 0.0

func set_aim_direction(direction: Vector2) -> void:
	if direction.length_squared() > 0.001:
		aim_direction = direction.normalized()

func fire_at(target: Node2D) -> void:
	if not can_fire() or target == null or not is_instance_valid(target):
		return
	var origin := global_position
	var direction := (target.global_position - origin).normalized()
	if direction.length_squared() <= 0.001:
		direction = aim_direction
	set_aim_direction(direction)
	cooldown_left = shot_cooldown_seconds
	var arrow := ARROW_SCENE.instantiate() as CombatProjectile
	arrow.speed = projectile_speed
	arrow.damage = arrow_damage
	arrow.collision_mask = 5 # Player body and walls; skeletons cannot hit each other.
	arrow.can_hit_player = true
	arrow.is_arrow = true
	arrow.attack_source = &"arrow"
	get_parent().get_parent().add_child(arrow)
	arrow.launch(origin, direction, get_parent())

func _draw() -> void:
	# Static side-view bow whose facing follows the target; no firing animation.
	var upper := Vector2(2.0, -13.0)
	var lower := Vector2(2.0, 13.0)
	draw_line(upper, Vector2(-5.0, -8.0), Color("332c30"), 5.0)
	draw_line(Vector2(-5.0, -8.0), Vector2(-7.0, 0.0), Color("332c30"), 5.0)
	draw_line(Vector2(-7.0, 0.0), Vector2(-5.0, 8.0), Color("332c30"), 5.0)
	draw_line(Vector2(-5.0, 8.0), lower, Color("332c30"), 5.0)
	draw_line(upper, lower, Color("dbcba6"), 1.5)
