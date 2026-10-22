extends CombatEnemy
class_name CombatSlime

enum MovementPhase { CHASING, PREPARING, LUNGING, RECOVERING }

@export var jump_prepare_seconds := 0.45
@export var jump_speed := 320.0
@export var jump_distance := 120.0
@export var jump_recovery_seconds := 0.6
@export var jump_cooldown_seconds := 2.8
@export var jump_trigger_distance := 220.0
@export var separation_radius := 48.0
@export var separation_strength := 1.0
@export var warning_flash_rate := 8.0
@export var warning_color := Color(1.0, 0.84, 0.32)
@export var lunge_color := Color(0.76, 1.0, 0.56)

var movement_phase := MovementPhase.CHASING
var phase_time_left := 0.0
var jump_cooldown_left := 0.0
var lunge_direction := Vector2.RIGHT
var lunge_distance_left := 0.0
var normal_color := Color(0.30, 0.78, 0.35)

func _ready() -> void:
	super._ready()
	add_to_group("slimes")
	normal_color = enemy_color
	jump_cooldown_left = randf_range(0.0, jump_cooldown_seconds)

func _update_movement(delta: float) -> void:
	jump_cooldown_left = maxf(0.0, jump_cooldown_left - delta)
	match movement_phase:
		MovementPhase.CHASING:
			_update_chase()
		MovementPhase.PREPARING:
			_update_preparation(delta)
		MovementPhase.LUNGING:
			_update_lunge(delta)
		MovementPhase.RECOVERING:
			_update_recovery(delta)

func _update_chase() -> void:
	enemy_color = normal_color
	visual_scale = Vector2.ONE
	var to_player := player.global_position - global_position
	var separation := _get_separation_vector()
	if to_player.length() <= jump_trigger_distance and jump_cooldown_left <= 0.0 and separation.length_squared() < 0.01:
		_begin_preparation()
		return
	var direction := to_player.normalized()
	var separation_influence := minf(0.8, separation.length() * separation_strength)
	var steering := direction
	if separation_influence > 0.0:
		steering = direction.lerp(separation.normalized(), separation_influence)
	if steering.length_squared() > 0.0001:
		velocity = steering.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	if to_player.length() <= stop_distance and separation.length_squared() < 0.01:
		velocity = Vector2.ZERO

func _begin_preparation() -> void:
	movement_phase = MovementPhase.PREPARING
	phase_time_left = maxf(0.0, jump_prepare_seconds)
	velocity = Vector2.ZERO
	visual_scale = Vector2(1.12, 0.86)
	enemy_color = normal_color.lerp(warning_color, 0.45)
	if phase_time_left <= 0.0:
		_begin_lunge()

func _update_preparation(delta: float) -> void:
	phase_time_left = maxf(0.0, phase_time_left - delta)
	velocity = Vector2.ZERO
	visual_scale = Vector2(1.12, 0.86)
	var elapsed := jump_prepare_seconds - phase_time_left
	var flash := 0.45 + 0.55 * absf(sin(elapsed * warning_flash_rate * TAU))
	enemy_color = normal_color.lerp(warning_color, flash)
	if phase_time_left <= 0.0:
		_begin_lunge()

func _begin_lunge() -> void:
	var to_player := player.global_position - global_position
	lunge_direction = to_player.normalized() if to_player.length_squared() > 0.0001 else Vector2.RIGHT
	lunge_distance_left = maxf(0.0, jump_distance)
	jump_cooldown_left = maxf(0.0, jump_cooldown_seconds)
	movement_phase = MovementPhase.LUNGING
	enemy_color = lunge_color
	visual_scale = Vector2(1.28, 0.76)
	if lunge_distance_left <= 0.0:
		_begin_recovery()

func _update_lunge(delta: float) -> void:
	enemy_color = lunge_color
	visual_scale = Vector2(1.28, 0.76)
	if delta <= 0.0 or jump_speed <= 0.0:
		velocity = Vector2.ZERO
		_begin_recovery()
		return
	var step_distance := minf(jump_speed * delta, lunge_distance_left)
	velocity = lunge_direction * (step_distance / delta)
	lunge_distance_left = maxf(0.0, lunge_distance_left - step_distance)
	if lunge_distance_left <= 0.0:
		_begin_recovery()

func _begin_recovery() -> void:
	movement_phase = MovementPhase.RECOVERING
	phase_time_left = maxf(0.0, jump_recovery_seconds)
	enemy_color = normal_color
	visual_scale = Vector2.ONE
	if phase_time_left <= 0.0:
		movement_phase = MovementPhase.CHASING

func _update_recovery(delta: float) -> void:
	velocity = Vector2.ZERO
	phase_time_left = maxf(0.0, phase_time_left - delta)
	enemy_color = normal_color
	visual_scale = Vector2.ONE
	if phase_time_left <= 0.0:
		movement_phase = MovementPhase.CHASING

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
