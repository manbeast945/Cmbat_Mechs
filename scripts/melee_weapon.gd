extends CombatWeapon

enum AttackPhase { IDLE, WINDUP, HIT_WINDOW, RECOVERY }

@export var damage := 34
@export var attack_range := 66.0
@export var attack_angle_degrees := 100.0
@export var combo_reset_seconds := 1.0
@export var buffered_click_window := 0.11
@export var blade_start_distance := 18.0

const LIGHT_BLADE_WIDTH := 4.5
const HEAVY_BLADE_WIDTH := 6.0
const TRAIL_LIFETIME := 0.12
const MAX_TRAIL_POSITIONS := 8

var phase := AttackPhase.IDLE
var phase_left := 0.0
var phase_duration := 0.0
var active_hit_window_duration := 0.0
var combo_reset_left := 0.0
var combo_step := 0
var active_attack_step := 0
var swing_direction := Vector2.RIGHT
var sweep_start_angle := 0.0
var sweep_end_angle := 0.0
var blade_angle := 0.0
var buffered_attack := false
var buffered_target := Vector2.ZERO
var hit_enemies: Dictionary = {}
var trail_origins: Array[Vector2] = []
var trail_directions: Array[Vector2] = []
var trail_ages: Array[float] = []
var blade_shape := CapsuleShape2D.new()
var blade_query := PhysicsShapeQueryParameters2D.new()

@onready var whoosh_audio: AudioStreamPlayer2D = $WhooshAudio

func _ready() -> void:
	whoosh_audio.stream = CombatSounds.make_whoosh()
	blade_query.shape = blade_shape
	blade_query.collision_mask = 2
	blade_query.collide_with_bodies = true
	blade_query.collide_with_areas = false

func _process(delta: float) -> void:
	_update_combo_timer(delta)
	_update_trail(delta)
	match phase:
		AttackPhase.WINDUP:
			phase_left -= delta
			if phase_left <= 0.0:
				_begin_hit_window()
		AttackPhase.HIT_WINDOW:
			var previous_progress := _hit_window_progress()
			phase_left = maxf(0.0, phase_left - delta)
			var current_progress := _hit_window_progress()
			blade_angle = _angle_at_progress(current_progress)
			_sweep_blade(previous_progress, current_progress)
			if phase_left <= 0.0:
				_begin_recovery()
		AttackPhase.RECOVERY:
			phase_left -= delta
			if phase_left <= 0.0:
				_finish_attack()
	queue_redraw()

func use(user: CharacterBody2D, target: Vector2) -> void:
	if phase == AttackPhase.IDLE:
		_start_attack(user, target)
	elif phase == AttackPhase.RECOVERY and phase_left <= buffered_click_window and not buffered_attack:
		buffered_attack = true
		buffered_target = target

func _update_combo_timer(delta: float) -> void:
	if combo_reset_left <= 0.0:
		return
	combo_reset_left = maxf(0.0, combo_reset_left - delta)
	if combo_reset_left == 0.0:
		combo_step = 0

func _start_attack(user: CharacterBody2D, target: Vector2) -> void:
	if combo_reset_left <= 0.0:
		combo_step = 0
	active_attack_step = combo_step
	combo_step = (combo_step + 1) % 3
	combo_reset_left = combo_reset_seconds
	swing_direction = (target - user.global_position).normalized()
	if swing_direction == Vector2.ZERO:
		swing_direction = Vector2.RIGHT
	rotation = swing_direction.angle()
	var half_angle := deg_to_rad(attack_angle_degrees * 0.5)
	var reverse_slash := active_attack_step == 1
	sweep_start_angle = half_angle if reverse_slash else -half_angle
	sweep_end_angle = -half_angle if reverse_slash else half_angle
	blade_angle = sweep_start_angle
	phase = AttackPhase.WINDUP
	phase_duration = 0.16 if active_attack_step == 2 else 0.09
	phase_left = phase_duration
	hit_enemies.clear()
	trail_origins.clear()
	trail_directions.clear()
	trail_ages.clear()
	whoosh_audio.play()
	queue_redraw()

func _begin_hit_window() -> void:
	phase = AttackPhase.HIT_WINDOW
	active_hit_window_duration = 0.10 if active_attack_step == 2 else 0.07
	phase_duration = active_hit_window_duration
	phase_left = phase_duration
	blade_angle = sweep_start_angle
	_sweep_blade(0.0, 0.0)

func _begin_recovery() -> void:
	phase = AttackPhase.RECOVERY
	phase_duration = 0.42 if active_attack_step == 2 else 0.20
	phase_left = phase_duration
	blade_angle = sweep_end_angle

func _finish_attack() -> void:
	phase = AttackPhase.IDLE
	phase_left = 0.0
	if not buffered_attack:
		return
	var target := buffered_target
	buffered_attack = false
	var user := get_parent() as CharacterBody2D
	if user != null:
		_start_attack(user, target)

func _hit_window_progress() -> float:
	return clampf(1.0 - phase_left / maxf(active_hit_window_duration, 0.001), 0.0, 1.0)

func _angle_at_progress(progress: float) -> float:
	return lerpf(sweep_start_angle, sweep_end_angle, progress)

func _sweep_blade(from_progress: float, to_progress: float) -> void:
	var angle_from := _angle_at_progress(from_progress)
	var angle_to := _angle_at_progress(to_progress)
	var arc_length := absf(angle_to - angle_from) * attack_range
	var sample_spacing := maxf(_active_blade_width() * 0.75, 1.0)
	var sample_count := maxi(1, ceili(arc_length / sample_spacing))
	for sample_index in range(sample_count + 1):
		var sample_progress := lerpf(from_progress, to_progress, float(sample_index) / float(sample_count))
		var sample_angle := _angle_at_progress(sample_progress)
		_check_blade_contact(sample_angle)
	blade_angle = angle_to
	_record_trail_angle(blade_angle)

func _check_blade_contact(local_blade_angle: float) -> void:
	var user := get_parent() as CharacterBody2D
	if user == null or hit_enemies.size() >= 32:
		return
	var blade_direction := swing_direction.rotated(local_blade_angle)
	var blade_base := _blade_base_distance()
	var blade_length := attack_range - blade_base
	var blade_center := global_position + blade_direction * (blade_base + blade_length * 0.5)
	blade_shape.radius = _active_blade_width() * 0.5
	blade_shape.height = blade_length
	blade_query.transform = Transform2D(blade_direction.angle() + PI * 0.5, blade_center)
	blade_query.exclude = [user.get_rid()]
	var hits := user.get_world_2d().direct_space_state.intersect_shape(blade_query, 32)
	for hit in hits:
		var enemy := hit.get("collider") as CombatEnemy
		if enemy == null or not enemy.is_in_group("enemies"):
			continue
		var enemy_id := enemy.get_instance_id()
		if hit_enemies.has(enemy_id):
			continue
		var away_from_player := enemy.global_position - user.global_position
		var knockback_direction := blade_direction if away_from_player.length_squared() < 0.001 else away_from_player.normalized()
		var heavy := active_attack_step == 2
		var knockback_multiplier := 1.35 if heavy else 1.55
		if enemy.take_damage(damage * (2 if heavy else 1), heavy, knockback_direction, knockback_multiplier):
			hit_enemies[enemy_id] = true
			var along_blade := clampf((enemy.global_position - global_position).dot(blade_direction), blade_base, attack_range)
			user.notify_combat_hit(global_position + blade_direction * along_blade, heavy)

func _active_blade_width() -> float:
	var requested_width := HEAVY_BLADE_WIDTH if active_attack_step == 2 else LIGHT_BLADE_WIDTH
	return minf(requested_width, maxf(attack_range - _blade_base_distance(), 1.0))

func _blade_base_distance() -> float:
	return minf(blade_start_distance, attack_range * 0.5)

func _record_trail_angle(angle: float) -> void:
	var world_direction := swing_direction.rotated(angle)
	if not trail_directions.is_empty():
		var same_origin := global_position.distance_squared_to(trail_origins[-1]) < 0.25
		var same_angle := world_direction.distance_squared_to(trail_directions[-1]) < 0.0001
		if same_origin and same_angle:
			return
	trail_origins.append(global_position)
	trail_directions.append(world_direction)
	trail_ages.append(0.0)
	while trail_origins.size() > MAX_TRAIL_POSITIONS:
		trail_origins.pop_front()
		trail_directions.pop_front()
		trail_ages.pop_front()

func _update_trail(delta: float) -> void:
	for index in range(trail_ages.size() - 1, -1, -1):
		trail_ages[index] += delta
		if trail_ages[index] >= TRAIL_LIFETIME:
			trail_ages.remove_at(index)
			trail_directions.remove_at(index)
			trail_origins.remove_at(index)

func display_name() -> String:
	return "MELEE"

func effective_range() -> float:
	return attack_range

func _draw() -> void:
	if phase == AttackPhase.IDLE and trail_origins.is_empty():
		return
	for index in range(trail_origins.size()):
		var fade := 1.0 - trail_ages[index] / TRAIL_LIFETIME
		var trail_color := Color(0.69, 0.85, 0.94, fade * (0.18 if active_attack_step != 2 else 0.24))
		var trail_start := trail_origins[index] + trail_directions[index] * _blade_base_distance()
		var trail_end := trail_origins[index] + trail_directions[index] * attack_range
		draw_line(to_local(trail_start), to_local(trail_end), trail_color, 2.0, true)
	if phase != AttackPhase.IDLE:
		var blade_color := Color(0.91, 0.95, 0.97, 1.0) if active_attack_step != 2 else Color(1.0, 1.0, 0.98, 1.0)
		_draw_blade(blade_angle, blade_color, _active_blade_width(), true)

func _draw_blade(local_angle: float, color: Color, blade_width: float, show_handle: bool) -> void:
	var direction := Vector2.RIGHT.rotated(local_angle)
	var normal := direction.rotated(PI * 0.5)
	var blade_base := _blade_base_distance()
	var base := direction * blade_base
	var tip := direction * attack_range
	if show_handle:
		draw_line(direction * (blade_base - 10.0), base, Color(0.24, 0.16, 0.12, 1.0), 4.0, true)
	draw_line(base, tip, color, blade_width, true)
	if show_handle:
		draw_line(base + normal * 4.0, base - normal * 4.0, Color(0.72, 0.56, 0.35, 1.0), 2.0, true)
		draw_line(base + direction * 2.0 + normal, tip - direction * 3.0 + normal, Color(1.0, 1.0, 1.0, 0.92), 1.0, true)
