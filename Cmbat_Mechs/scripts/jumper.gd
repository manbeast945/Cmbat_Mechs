extends CombatEnemy
class_name CombatJumper

enum AttackState { WALKING, CHARGING, JUMPING, LANDING_RECOVERY }

@export var attack_trigger_range := 250.0
@export var charge_seconds := 0.6
@export var jump_speed := 360.0
@export var jump_height := 44.0
@export var landing_aoe_radius := 45.0
@export var landing_damage := 8
@export var post_landing_cooldown_seconds := 1.8
@export var landing_stagger_seconds := 0.5

var attack_state := AttackState.WALKING
var attack_state_left := 0.0
var attack_cooldown_left := 0.0
var landing_recovery_left := 0.0
var landing_position := Vector2.ZERO
var jump_start_position := Vector2.ZERO
var jump_distance := 0.0
var visual_lift := 0.0
var landing_telegraph_visible := false
var collision_mask_before_jump := 0
var collision_layer_before_jump := 0
var hurtbox_layer_before_jump := 0

@onready var attack_hurtbox: CombatAttackHurtbox = $Visual/AttackHurtbox

func _physics_process(delta: float) -> void:
	contact_cooldown_left = maxf(0.0, contact_cooldown_left - delta)
	stagger_left = maxf(0.0, stagger_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		landing_telegraph_visible = false
		if attack_state == AttackState.JUMPING:
			_restore_collision()
			attack_state = AttackState.WALKING
			visual_lift = 0.0
		return

	match attack_state:
		AttackState.WALKING:
			if stagger_left > 0.0:
				velocity = knockback_velocity
				knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
			else:
				_update_movement(delta)
			move_and_slide()
			_apply_contact_damage()
			if stagger_left <= 0.0 and not player.is_defeated and attack_cooldown_left <= 0.0 and global_position.distance_to(player.global_position) <= attack_trigger_range:
				_begin_charge()
		AttackState.CHARGING:
			velocity = Vector2.ZERO
			visual_scale = Vector2(1.14, 0.84)
			landing_position = player.global_position
			attack_state_left = maxf(0.0, attack_state_left - delta)
			if attack_state_left <= 0.0:
				_begin_jump()
		AttackState.JUMPING:
			_update_jump(delta)
		AttackState.LANDING_RECOVERY:
			velocity = Vector2.ZERO
			landing_recovery_left = maxf(0.0, landing_recovery_left - delta)
			if landing_recovery_left <= 0.0:
				attack_state = AttackState.WALKING
				stagger_left = 0.0
				visual_scale = Vector2.ONE

func take_damage(amount: int, heavy: bool = false, hit_direction: Vector2 = Vector2.ZERO, knockback_multiplier: float = 1.0, attack_source: StringName = &"generic") -> bool:
	if attack_state == AttackState.JUMPING:
		return false
	var adjusted_amount := amount
	if attack_state == AttackState.CHARGING and amount > 0:
		adjusted_amount = maxi(1, roundi(float(amount) * 0.7))
	return super.take_damage(adjusted_amount, heavy, hit_direction, knockback_multiplier, attack_source)

func _begin_charge() -> void:
	attack_state = AttackState.CHARGING
	attack_state_left = maxf(0.0, charge_seconds)
	velocity = Vector2.ZERO
	visual_scale = Vector2(1.14, 0.84)
	landing_position = player.global_position
	landing_telegraph_visible = true
	if attack_state_left <= 0.0:
		_begin_jump()

func _begin_jump() -> void:
	landing_position = player.global_position
	jump_start_position = global_position
	jump_distance = jump_start_position.distance_to(landing_position)
	attack_state = AttackState.JUMPING
	# Become intangible for the full airborne phase: pass through walls and
	# bodies, and remove the attack hurtbox until landing.
	collision_mask_before_jump = collision_mask
	collision_layer_before_jump = collision_layer
	hurtbox_layer_before_jump = attack_hurtbox.collision_layer
	collision_mask = 0
	collision_layer = 0
	attack_hurtbox.collision_layer = 0
	visual_scale = Vector2(1.0, 1.0)
	if jump_distance <= 1.0 or jump_speed <= 0.0:
		_land()

func _update_jump(delta: float) -> void:
	var to_landing := landing_position - global_position
	var distance_left := to_landing.length()
	if distance_left <= 1.0 or delta <= 0.0:
		_land()
		return
	var direction := to_landing / distance_left
	velocity = direction * minf(jump_speed, distance_left / delta)
	move_and_slide()
	if get_slide_collision_count() > 0 and global_position.distance_to(landing_position) > 1.0:
		# Keep the indicated landing point aligned with the actual collision stop.
		landing_position = global_position
		_land()
		return
	var progress := clampf(1.0 - global_position.distance_to(landing_position) / maxf(jump_distance, 0.001), 0.0, 1.0)
	visual_lift = sin(progress * PI) * maxf(0.0, jump_height)
	visual_scale = Vector2(1.08, 0.9)
	if global_position.distance_to(landing_position) <= 1.0:
		_land()

func _land() -> void:
	global_position = landing_position
	velocity = Vector2.ZERO
	visual_lift = 0.0
	visual_scale = Vector2(1.12, 0.84)
	attack_state = AttackState.LANDING_RECOVERY
	landing_recovery_left = maxf(0.0, landing_stagger_seconds)
	stagger_left = landing_recovery_left
	reaction_strength = 1.0
	attack_cooldown_left = maxf(0.0, post_landing_cooldown_seconds)
	landing_telegraph_visible = false
	_apply_landing_damage()
	_apply_contact_damage()
	_move_clear_of_player()
	_restore_collision()
	if landing_recovery_left <= 0.0:
		attack_state = AttackState.WALKING
		stagger_left = 0.0
		visual_scale = Vector2.ONE

func _move_clear_of_player() -> void:
	if player == null or not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) >= 25.0:
		return
	var separation_direction := (jump_start_position - player.global_position).normalized()
	if separation_direction.length_squared() <= 0.001:
		separation_direction = Vector2.RIGHT
	global_position = player.global_position + separation_direction * 25.0

func _restore_collision() -> void:
	if not is_node_ready():
		return
	collision_mask = collision_mask_before_jump
	collision_layer = collision_layer_before_jump
	attack_hurtbox.collision_layer = hurtbox_layer_before_jump

func _apply_landing_damage() -> void:
	if player == null or not is_instance_valid(player) or player.is_defeated:
		return
	if global_position.distance_to(player.global_position) > landing_aoe_radius:
		return
	if global_position.distance_squared_to(player.global_position) <= 0.001:
		player.take_damage(landing_damage)
		return
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 4)
	query.exclude = [get_rid()]
	if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		player.take_damage(landing_damage)

func _apply_contact_damage() -> void:
	if player == null or not is_instance_valid(player) or player.is_defeated:
		return
	if global_position.distance_to(player.global_position) > 33.0 or contact_cooldown_left > 0.0:
		return
	player.take_damage(contact_damage)
	contact_cooldown_left = contact_cooldown_seconds
