extends CombatWeapon

@export var damage := 34
@export var attack_range := 66.0
@export var attack_angle_degrees := 100.0
@export var cooldown_seconds := 0.38

var cooldown_left := 0.0
var swing_time_left := 0.0

func _process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	swing_time_left = maxf(0.0, swing_time_left - delta)
	queue_redraw()

func use(user: CharacterBody2D, target: Vector2) -> void:
	if cooldown_left > 0.0:
		return

	var direction := (target - user.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()
	cooldown_left = cooldown_seconds
	swing_time_left = 0.16
	queue_redraw()

	var circle := CircleShape2D.new()
	circle.radius = attack_range * 0.62
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, user.global_position + direction * (attack_range * 0.58))
	query.collision_mask = 2
	query.exclude = [user.get_rid()]
	var hits := user.get_world_2d().direct_space_state.intersect_shape(query, 32)
	var hit_ids: Dictionary = {}
	var min_dot := cos(deg_to_rad(attack_angle_degrees * 0.5))
	for hit in hits:
		var enemy: Object = hit.get("collider")
		if not enemy is Node or not enemy.is_in_group("enemies"):
			continue
		var enemy_id := enemy.get_instance_id()
		if hit_ids.has(enemy_id):
			continue
		hit_ids[enemy_id] = true
		var to_enemy: Vector2 = enemy.global_position - user.global_position
		if to_enemy.length() <= attack_range and direction.dot(to_enemy.normalized()) >= min_dot:
			enemy.take_damage(damage)

func display_name() -> String:
	return "MELEE"

func _draw() -> void:
	if swing_time_left <= 0.0:
		return
	var alpha := clampf(swing_time_left / 0.16, 0.0, 1.0)
	draw_arc(Vector2(31.0, 0.0), 37.0, deg_to_rad(-57.0), deg_to_rad(57.0), 24, Color(1.0, 0.79, 0.38, alpha), 7.0, true)
	draw_line(Vector2(20.0, -16.0), Vector2(68.0, 0.0), Color(1.0, 0.96, 0.76, alpha), 3.0, true)
