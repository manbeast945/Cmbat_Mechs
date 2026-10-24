extends CombatEnemy
class_name CombatSlime

enum MovementPhase { WAITING, PREPARING, HOPPING }

@export var hop_distance := 40.0
@export var hop_speed := 420.0
@export var hop_height := 12.0
@export var hop_interval_seconds := 0.24
@export var pre_hop_squash_seconds := 0.05
@export var separation_radius := 48.0
@export_range(0.0, 0.5, 0.01) var separation_strength := 0.35
@export var minimum_spawn_spacing := 32.0

var skip_initial_spawn_spacing := false
var movement_phase := MovementPhase.WAITING
var phase_time_left := 0.0
var hop_direction := Vector2.RIGHT
var hop_distance_left := 0.0
var hop_progress := 0.0
var visual_lift := 0.0
var hop_finish_pending := false
var normal_color := Color(0.30, 0.78, 0.35)

func _ready() -> void:
	super._ready()
	add_to_group("slimes")
	normal_color = enemy_color
	if not skip_initial_spawn_spacing:
		_apply_spawn_spacing()
	phase_time_left = randf_range(0.0, maxf(hop_interval_seconds, 0.0))

func _update_movement(delta: float) -> void:
	match movement_phase:
		MovementPhase.WAITING:
			_update_waiting(delta)
		MovementPhase.PREPARING:
			_update_preparation(delta)
		MovementPhase.HOPPING:
			_update_hop(delta)

func _update_waiting(delta: float) -> void:
	velocity = Vector2.ZERO
	visual_lift = 0.0
	visual_scale = Vector2.ONE
	enemy_color = normal_color
	phase_time_left = maxf(0.0, phase_time_left - delta)
	if phase_time_left <= 0.0:
		_begin_preparation()

func _begin_preparation() -> void:
	movement_phase = MovementPhase.PREPARING
	phase_time_left = maxf(0.0, pre_hop_squash_seconds)
	velocity = Vector2.ZERO
	visual_lift = 0.0
	visual_scale = Vector2(1.12, 0.86)
	if phase_time_left <= 0.0:
		_begin_hop()

func _update_preparation(delta: float) -> void:
	phase_time_left = maxf(0.0, phase_time_left - delta)
	velocity = Vector2.ZERO
	visual_lift = 0.0
	visual_scale = Vector2(1.12, 0.86)
	if phase_time_left <= 0.0:
		_begin_hop()

func _begin_hop() -> void:
	var to_player := player.global_position - global_position
	var target_direction := to_player.normalized() if to_player.length_squared() > 0.0001 else Vector2.RIGHT
	var separation := _get_separation_vector()
	var separation_influence := minf(0.35, separation.length() * separation_strength)
	if separation_influence > 0.0:
		target_direction = target_direction.lerp(separation.normalized(), separation_influence).normalized()
	hop_direction = target_direction if target_direction.length_squared() > 0.0001 else Vector2.RIGHT
	hop_distance_left = maxf(0.0, hop_distance)
	hop_progress = 0.0
	hop_finish_pending = false
	phase_time_left = hop_distance_left / maxf(hop_speed, 0.001)
	movement_phase = MovementPhase.HOPPING
	if hop_distance_left <= 0.0 or hop_speed <= 0.0:
		_finish_hop()
		return
	_update_hop_visual()

func _update_hop(delta: float) -> void:
	if hop_finish_pending:
		_finish_hop()
		return
	if delta <= 0.0 or hop_speed <= 0.0:
		_finish_hop()
		return
	var step_distance := minf(hop_speed * delta, hop_distance_left)
	velocity = hop_direction * (step_distance / delta)
	hop_distance_left = maxf(0.0, hop_distance_left - step_distance)
	hop_progress = clampf(1.0 - hop_distance_left / maxf(hop_distance, 0.001), 0.0, 1.0)
	_update_hop_visual()
	if hop_distance_left <= 0.0:
		# Let CombatEnemy.move_and_slide() apply this final movement step.
		hop_finish_pending = true

func _update_hop_visual() -> void:
	visual_lift = sin(hop_progress * PI) * maxf(0.0, hop_height)
	# Stretch slightly along the frozen hop direction while airborne.
	var stretch := 1.08
	var squash := 0.93
	visual_scale = Vector2(stretch, squash)
	enemy_color = normal_color

func _finish_hop() -> void:
	velocity = Vector2.ZERO
	visual_lift = 0.0
	visual_scale = Vector2.ONE
	enemy_color = normal_color
	hop_finish_pending = false
	movement_phase = MovementPhase.WAITING
	var hop_duration := hop_distance / maxf(hop_speed, 0.001)
	phase_time_left = maxf(0.0, hop_interval_seconds - hop_duration - pre_hop_squash_seconds)

func _apply_spawn_spacing() -> void:
	if minimum_spawn_spacing <= 0.0:
		return
	var existing_slimes: Array[CombatSlime] = []
	for candidate in get_tree().get_nodes_in_group("slimes"):
		var other := candidate as CombatSlime
		if other != null and other != self:
			existing_slimes.append(other)
	if existing_slimes.is_empty():
		return
	var origin := global_position
	var fallback_position := origin
	var fallback_neighbor_distance := -1.0
	var fallback_origin_distance := INF
	var body_shape := CircleShape2D.new()
	body_shape.radius = 17.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = body_shape
	query.collision_mask = 4
	for ring in range(1, 9):
		var radius := minimum_spawn_spacing * float(ring)
		for index in range(32):
			var angle := TAU * float(index) / 32.0 + float(get_instance_id() % 32) * TAU / 32.0
			var candidate_position := origin + Vector2.RIGHT.rotated(angle) * radius
			if not _is_spawn_position_clear(candidate_position, query):
				continue
			var nearest_neighbor_distance := INF
			for other in existing_slimes:
				nearest_neighbor_distance = minf(nearest_neighbor_distance, candidate_position.distance_to(other.global_position))
			if nearest_neighbor_distance >= minimum_spawn_spacing:
				global_position = candidate_position
				return
			var candidate_distance := candidate_position.distance_to(origin)
			if nearest_neighbor_distance > fallback_neighbor_distance or (is_equal_approx(nearest_neighbor_distance, fallback_neighbor_distance) and candidate_distance < fallback_origin_distance):
				fallback_neighbor_distance = nearest_neighbor_distance
				fallback_origin_distance = candidate_distance
				fallback_position = candidate_position
	if fallback_neighbor_distance >= 0.0:
		global_position = fallback_position

func _is_spawn_position_clear(candidate_position: Vector2, query: PhysicsShapeQueryParameters2D) -> bool:
	query.transform = Transform2D(0.0, candidate_position)
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _get_separation_vector() -> Vector2:
	if separation_radius <= 0.0:
		return Vector2.ZERO
	var separation := Vector2.ZERO
	for candidate in get_tree().get_nodes_in_group("slimes"):
		var other := candidate as CombatSlime
		if other == null or other == self:
			continue
		var away := global_position - other.global_position
		var distance := away.length()
		if distance >= separation_radius:
			continue
		if distance <= 0.001:
			var low_id := mini(get_instance_id(), other.get_instance_id())
			var angle := float(low_id % 360) * TAU / 360.0
			var pair_direction := Vector2.RIGHT.rotated(angle)
			away = pair_direction if get_instance_id() < other.get_instance_id() else -pair_direction
			distance = 0.0
		separation += away.normalized() * (1.0 - distance / separation_radius)
	return separation
