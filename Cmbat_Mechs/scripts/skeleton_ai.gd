extends CombatEnemy
class_name CombatSkeleton

@export var detection_range := INF
@export var shooting_range := 320.0
@export var pursuit_memory_seconds := 2.5

var has_detected_player := false
var last_seen_player_position := Vector2.ZERO
var pursuit_memory_left := 0.0

@onready var bow: CombatSkeletonBow = $Bow

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	contact_cooldown_left = maxf(0.0, contact_cooldown_left - delta)
	stagger_left = maxf(0.0, stagger_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	if health <= 0:
		return

	_update_player_detection(delta)
	var target: Node2D = _get_target()
	if target == null:
		velocity = Vector2.ZERO
		bow.set_aim_direction(Vector2.RIGHT)
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var has_line_of_sight := _has_line_of_sight(global_position, target.global_position)

	var aim_direction := to_target.normalized() if distance > 0.001 else Vector2.RIGHT
	bow.set_aim_direction(aim_direction)

	if stagger_left > 0.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
		move_and_slide()
		_apply_contact_damage()
		return

	if distance <= shooting_range and has_line_of_sight:
		velocity = Vector2.ZERO
		if bow.can_fire():
			bow.fire_at(target)
	else:
		var destination := target.global_position
		if not has_line_of_sight:
			destination = _find_reposition_point(target)
		var to_destination := destination - global_position
		velocity = to_destination.normalized() * move_speed if to_destination.length() > 8.0 else Vector2.ZERO
		if distance > shooting_range:
			velocity = to_target.normalized() * move_speed
	
	move_and_slide()
	_apply_contact_damage()

func _update_player_detection(delta: float) -> void:
	if player == null or not is_instance_valid(player) or player.is_defeated:
		pursuit_memory_left = 0.0
		return
	var distance := global_position.distance_to(player.global_position)
	if distance <= detection_range and _has_line_of_sight(global_position, player.global_position):
		has_detected_player = true
		last_seen_player_position = player.global_position
		pursuit_memory_left = pursuit_memory_seconds
	elif has_detected_player:
		pursuit_memory_left = maxf(0.0, pursuit_memory_left - delta)
		if pursuit_memory_left <= 0.0:
			has_detected_player = false

func _get_target() -> Node2D:
	if player != null and is_instance_valid(player) and not player.is_defeated:
		if has_detected_player:
			return player
	return null

func _has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 4)
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _find_reposition_point(target: Node2D) -> Vector2:
	# Seek an angle with a clear shot around nearby cover instead of firing through it.
	var best_position := target.global_position
	var best_distance := INF
	var orbit_radius := shooting_range * 0.68
	var start_angle := float(get_instance_id() % 16) * TAU / 16.0
	for index in range(16):
		var candidate := target.global_position + Vector2.RIGHT.rotated(start_angle + TAU * float(index) / 16.0) * orbit_radius
		if not _has_line_of_sight(candidate, target.global_position):
			continue
		var candidate_distance := global_position.distance_to(candidate)
		if candidate_distance < best_distance:
			best_distance = candidate_distance
			best_position = candidate
	return best_position

func _apply_contact_damage() -> void:
	if player == null or not is_instance_valid(player) or player.is_defeated:
		return
	if global_position.distance_to(player.global_position) > 24.0 or contact_cooldown_left > 0.0:
		return
	player.take_damage(contact_damage)
	contact_cooldown_left = contact_cooldown_seconds
