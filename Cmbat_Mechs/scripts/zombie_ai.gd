extends CombatEnemy
class_name CombatZombie

enum AttackState { APPROACHING, WINDUP, STRIKING, RECOVERY, STAGGERED }

@export var detection_range := 390.0
@export var hearing_range := 480.0
@export var pursuit_memory_seconds := 3.2
@export var attack_damage := 13
@export var attack_reach := 42.0
@export var attack_arc_degrees := 105.0
@export var attack_windup_seconds := 0.1
@export var attack_active_seconds := 0.13
@export var attack_recovery_seconds := 0.42
@export var attack_cooldown_seconds := 0.24
@export var surround_distance := 32.0
@export var separation_radius := 62.0
@export_range(0.0, 1.0, 0.01) var separation_strength := 0.72
@export var light_knife_knockback := 76.0
@export var heavy_knife_knockback := 240.0
@export var bullet_knockback := 44.0
@export_range(0.0, 1.0, 0.01) var light_stagger_resistance := 0.62
@export var light_stagger_seconds := 0.10
@export var light_stagger_lockout_seconds := 0.40
@export var heavy_stagger_seconds := 0.50

var attack_state := AttackState.APPROACHING
var attack_state_left := 0.0
var attack_cooldown_left := 0.0
var pursuit_memory_left := 0.0
var investigation_left := 0.0
var light_stagger_lockout_left := 0.0
var knockback_left := 0.0
var knockback_from_heavy := false
var has_spotted_player := false
var last_known_player_position := Vector2.ZERO
var investigation_position := Vector2.ZERO
var windup_direction := Vector2.RIGHT
var committed_attack_direction := Vector2.RIGHT
var attack_hit_registered := false
var assigned_surround_angle := -1.0
var growl_player: AudioStreamPlayer2D

func _ready() -> void:
	super._ready()
	add_to_group("zombies")
	if assigned_surround_angle < 0.0:
		assigned_surround_angle = randf_range(0.0, TAU)
	attack_cooldown_left = randf_range(0.12, maxf(0.2, attack_cooldown_seconds + 0.35))
	growl_player = AudioStreamPlayer2D.new()
	growl_player.name = "AttackGrowl"
	growl_player.stream = CombatSounds.make_growl()
	growl_player.volume_db = -2.0
	growl_player.max_distance = 640.0
	add_child(growl_player)

func _physics_process(delta: float) -> void:
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	contact_cooldown_left = maxf(0.0, contact_cooldown_left - delta)
	light_stagger_lockout_left = maxf(0.0, light_stagger_lockout_left - delta)
	if player == null or not is_instance_valid(player) or player.is_defeated:
		velocity = Vector2.ZERO
		return

	_update_surround_slot()
	_update_awareness(delta)
	if attack_state == AttackState.STAGGERED:
		stagger_left = maxf(0.0, stagger_left - delta)
		velocity = knockback_velocity
		move_and_slide()
		_apply_contact_damage()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 680.0 * delta)
		if stagger_left <= 0.0:
			if knockback_from_heavy:
				attack_state = AttackState.RECOVERY
				attack_state_left = attack_recovery_seconds * 0.65
			else:
				attack_state = AttackState.APPROACHING
			knockback_from_heavy = false
		return

	var steering_velocity := Vector2.ZERO
	match attack_state:
		AttackState.APPROACHING:
			steering_velocity = _approach_velocity(_current_target_position(), move_speed)
			if has_spotted_player and _player_is_attackable() and attack_cooldown_left <= 0.0:
				_begin_windup()
		AttackState.WINDUP:
			if has_spotted_player:
				var to_player := player.global_position - global_position
				if to_player.length_squared() > 0.001:
					windup_direction = to_player.normalized()
			steering_velocity = Vector2.ZERO
			attack_state_left = maxf(0.0, attack_state_left - delta)
			if attack_state_left <= 0.0:
				_begin_strike()
		AttackState.STRIKING:
			steering_velocity = Vector2.ZERO
		AttackState.RECOVERY:
			attack_state_left = maxf(0.0, attack_state_left - delta)
			if attack_state_left <= 0.0:
				attack_state = AttackState.APPROACHING

	var impulse := Vector2.ZERO
	if knockback_left > 0.0 and attack_state != AttackState.STRIKING:
		knockback_left = maxf(0.0, knockback_left - delta)
		impulse = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 680.0 * delta)
	velocity = steering_velocity + impulse
	move_and_slide()
	_apply_contact_damage()

	if attack_state == AttackState.STRIKING:
		if not attack_hit_registered:
			attack_hit_registered = _try_attack_hit()
		attack_state_left = maxf(0.0, attack_state_left - delta)
		if attack_state_left <= 0.0:
			attack_state = AttackState.RECOVERY
			attack_state_left = attack_recovery_seconds
			attack_cooldown_left = randf_range(attack_cooldown_seconds * 0.65, attack_cooldown_seconds * 1.35)

func hear_gunshot(origin: Vector2) -> void:
	if player == null or not is_instance_valid(player) or has_spotted_player:
		return
	if global_position.distance_to(origin) > hearing_range:
		return
	investigation_position = origin
	investigation_left = pursuit_memory_seconds

func is_attack_winding_up() -> bool:
	return attack_state == AttackState.WINDUP

func attack_warning_progress() -> float:
	if attack_state != AttackState.WINDUP:
		return 0.0
	return clampf(1.0 - attack_state_left / maxf(attack_windup_seconds, 0.001), 0.0, 1.0)

func take_damage(amount: int, heavy: bool = false, hit_direction: Vector2 = Vector2.ZERO, knockback_multiplier: float = 1.0, attack_source: StringName = &"generic") -> bool:
	if health <= 0:
		return false
	health = maxi(0, health - amount)
	hit_flash_left = 0.12 if heavy else 0.08
	reaction_strength = 1.0 if heavy else 0.48
	var knockback_amount := heavy_knife_knockback if heavy else light_knife_knockback if attack_source == &"knife" else bullet_knockback
	knockback_velocity = hit_direction.normalized() * knockback_amount * knockback_multiplier
	knockback_left = 0.15 if heavy else 0.10
	if heavy and attack_source == &"knife":
		stagger_left = heavy_stagger_seconds
		attack_state = AttackState.STAGGERED
		knockback_from_heavy = true
	elif attack_source == &"knife" and light_stagger_lockout_left <= 0.0 and randf() >= light_stagger_resistance:
		stagger_left = light_stagger_seconds
		attack_state = AttackState.STAGGERED
		knockback_from_heavy = false
		light_stagger_lockout_left = light_stagger_lockout_seconds
	queue_redraw()
	if health == 0:
		queue_free()
	return true

func _update_awareness(delta: float) -> void:
	if _can_see_player():
		has_spotted_player = true
		last_known_player_position = player.global_position
		pursuit_memory_left = pursuit_memory_seconds
		investigation_left = 0.0
		return
	if has_spotted_player:
		pursuit_memory_left = maxf(0.0, pursuit_memory_left - delta)
		if pursuit_memory_left <= 0.0:
			has_spotted_player = false
	elif investigation_left > 0.0:
		investigation_left = maxf(0.0, investigation_left - delta)
		if global_position.distance_to(investigation_position) <= 20.0:
			investigation_left = 0.0

func _can_see_player() -> bool:
	if global_position.distance_to(player.global_position) > detection_range:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 4)
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _current_target_position() -> Vector2:
	if has_spotted_player:
		return last_known_player_position
	if investigation_left > 0.0:
		return investigation_position
	return global_position

func _approach_velocity(target_position: Vector2, speed: float) -> Vector2:
	if not has_spotted_player and investigation_left <= 0.0:
		return Vector2.ZERO
	var desired_position := target_position
	if has_spotted_player:
		var slot_direction := Vector2.RIGHT.rotated(assigned_surround_angle)
		desired_position += slot_direction * surround_distance
	var to_target := desired_position - global_position
	var direction := to_target.normalized() if to_target.length() > 7.0 else Vector2.ZERO
	var separation := _get_zombie_separation()
	if separation.length_squared() > 0.001:
		direction = (direction + separation.normalized() * separation_strength).normalized()
	return direction * speed

func _get_zombie_separation() -> Vector2:
	var separation := Vector2.ZERO
	for candidate in get_tree().get_nodes_in_group("zombies"):
		var other := candidate as CombatZombie
		if other == null or other == self:
			continue
		var offset := global_position - other.global_position
		var distance := offset.length()
		if distance > 0.001 and distance < separation_radius:
			separation += offset.normalized() * (1.0 - distance / separation_radius)
	return separation

func _update_surround_slot() -> void:
	var zombies := get_tree().get_nodes_in_group("zombies")
	var slot_index := zombies.find(self)
	if slot_index >= 0 and not zombies.is_empty():
		assigned_surround_angle = TAU * float(slot_index) / float(zombies.size())

func _player_is_attackable() -> bool:
	var offset := player.global_position - global_position
	if offset.length() > attack_reach:
		return false
	return _can_see_player()

func _begin_windup() -> void:
	attack_state = AttackState.WINDUP
	attack_state_left = maxf(0.0, attack_windup_seconds)
	var offset := player.global_position - global_position
	if offset.length_squared() > 0.001:
		windup_direction = offset.normalized()
	if growl_player != null and not growl_player.playing:
		growl_player.play()
	if attack_state_left <= 0.0:
		_begin_strike()

func _begin_strike() -> void:
	var offset := player.global_position - global_position
	committed_attack_direction = offset.normalized() if offset.length_squared() > 0.001 else windup_direction
	attack_hit_registered = false
	attack_state = AttackState.STRIKING
	attack_state_left = maxf(0.01, attack_active_seconds)

func _try_attack_hit() -> bool:
	var offset := player.global_position - global_position
	if offset.length() > attack_reach:
		return false
	if offset.length_squared() > 0.001 and committed_attack_direction.dot(offset.normalized()) < cos(deg_to_rad(attack_arc_degrees * 0.5)):
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 5)
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.get("collider") != player:
		return false
	player.take_damage(attack_damage)
	return true

func _apply_contact_damage() -> void:
	if player == null or not is_instance_valid(player) or player.is_defeated:
		return
	# Match the actual player/enemy circle collider radii, without the old early-hit buffer.
	if global_position.distance_to(player.global_position) > 24.0:
		return
	if contact_cooldown_left > 0.0:
		return
	player.take_damage(contact_damage)
	contact_cooldown_left = contact_cooldown_seconds
	if attack_state == AttackState.STRIKING:
		attack_hit_registered = true
