extends CombatEnemy
class_name CombatSticker

enum AttackState { RUNNING, AIRBORNE, LATCHED, RECOVERY }

@export_group("Sticker attack")
@export var leap_trigger_range := 110.0
@export var jump_speed := 520.0
@export var jump_height := 36.0
@export var latch_duration_seconds := 2.0
@export var latch_damage := 3
@export var latch_damage_interval_seconds := 0.5
@export var get_up_recovery_seconds := 0.5
@export var latch_contact_offset := 12.0

var attack_state := AttackState.RUNNING
var visual_lift := 0.0
var facing_direction := Vector2.RIGHT
var jump_start_position := Vector2.ZERO
var landing_position := Vector2.ZERO
var jump_distance := 0.0
var latch_time_left := 0.0
var latch_damage_left := 0.0
var recovery_left := 0.0
var collision_mask_before_jump := 0
var collision_layer_before_jump := 0
var hurtbox_layer_before_jump := 0

@onready var attack_hurtbox: CombatAttackHurtbox = $Visual/AttackHurtbox

func _ready() -> void:
	super._ready()
	add_to_group("sticker_enemies")
	for other: Node in get_tree().get_nodes_in_group("sticker_enemies"):
		var other_sticker := other as CombatSticker
		if other_sticker == null or other_sticker == self:
			continue
		add_collision_exception_with(other_sticker)
		other_sticker.add_collision_exception_with(self)

func _physics_process(delta: float) -> void:
	contact_cooldown_left = maxf(0.0, contact_cooldown_left - delta)
	stagger_left = maxf(0.0, stagger_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	if player == null or not is_instance_valid(player) or player.is_defeated:
		velocity = Vector2.ZERO
		if attack_state == AttackState.AIRBORNE or attack_state == AttackState.LATCHED:
			_restore_collision()
		attack_state = AttackState.RUNNING
		z_index = 0
		visual_lift = 0.0
		return

	match attack_state:
		AttackState.RUNNING:
			if stagger_left > 0.0:
				velocity = knockback_velocity
				knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
			else:
				var offset := player.global_position - global_position
				if offset.length_squared() > 0.001:
					facing_direction = offset.normalized()
				_update_movement(delta)
			move_and_slide()
			if stagger_left <= 0.0 and global_position.distance_to(player.global_position) <= leap_trigger_range:
				_begin_leap()
		AttackState.AIRBORNE:
			_update_leap(delta)
		AttackState.LATCHED:
			velocity = Vector2.ZERO
			global_position = player.global_position - facing_direction * latch_contact_offset + Vector2(0.0, -12.0)
			latch_time_left = maxf(0.0, latch_time_left - delta)
			latch_damage_left -= delta
			if latch_damage_left <= 0.0:
				player.take_damage(latch_damage)
				latch_damage_left += maxf(latch_damage_interval_seconds, 0.05)
			if latch_time_left <= 0.0:
				_begin_recovery()
		AttackState.RECOVERY:
			velocity = Vector2.ZERO
			recovery_left = maxf(0.0, recovery_left - delta)
			if recovery_left <= 0.0:
				attack_state = AttackState.RUNNING
				visual_scale = Vector2.ONE

func take_damage(amount: int, heavy: bool = false, hit_direction: Vector2 = Vector2.ZERO, knockback_multiplier: float = 1.0, attack_source: StringName = &"generic") -> bool:
	if attack_state == AttackState.AIRBORNE:
		return false
	if attack_state == AttackState.LATCHED and attack_source != &"knife":
		return false
	var registered := super.take_damage(amount, heavy, hit_direction, knockback_multiplier, attack_source)
	if registered and attack_state == AttackState.LATCHED:
		_begin_recovery()
	return registered

func should_projectile_pass_through() -> bool:
	return attack_state == AttackState.AIRBORNE or attack_state == AttackState.LATCHED

func _begin_leap() -> void:
	var offset := player.global_position - global_position
	if offset.length_squared() <= 0.001:
		return
	facing_direction = offset.normalized()
	jump_start_position = global_position
	landing_position = player.global_position
	jump_distance = jump_start_position.distance_to(landing_position)
	attack_state = AttackState.AIRBORNE
	collision_mask_before_jump = collision_mask
	collision_layer_before_jump = collision_layer
	hurtbox_layer_before_jump = attack_hurtbox.collision_layer
	collision_mask = 0
	collision_layer = 0
	attack_hurtbox.collision_layer = 0

func _update_leap(delta: float) -> void:
	var offset := landing_position - global_position
	var distance_left := offset.length()
	if distance_left <= 1.0 or delta <= 0.0:
		_finish_leap()
		return
	velocity = offset / distance_left * minf(maxf(jump_speed, 1.0), distance_left / delta)
	move_and_slide()
	var progress := clampf(1.0 - global_position.distance_to(landing_position) / maxf(jump_distance, 0.001), 0.0, 1.0)
	visual_lift = sin(progress * PI) * maxf(jump_height, 0.0)
	visual_scale = Vector2(1.08, 0.9)
	if global_position.distance_to(landing_position) <= 1.0:
		_finish_leap()

func _finish_leap() -> void:
	global_position = landing_position
	velocity = Vector2.ZERO
	visual_lift = 0.0
	visual_scale = Vector2.ONE
	_restore_collision()
	if player != null and is_instance_valid(player) and not player.is_defeated and global_position.distance_to(player.global_position) <= latch_contact_offset + 12.0:
		facing_direction = (player.global_position - jump_start_position).normalized()
		if facing_direction.length_squared() <= 0.001:
			facing_direction = Vector2.RIGHT
		global_position = player.global_position - facing_direction * latch_contact_offset + Vector2(0.0, -12.0)
		attack_state = AttackState.LATCHED
		z_index = 2
		latch_time_left = maxf(0.0, latch_duration_seconds)
		latch_damage_left = maxf(latch_damage_interval_seconds, 0.05)
		collision_layer = 0
		collision_mask = 0
	else:
		_begin_recovery()

func _begin_recovery() -> void:
	attack_state = AttackState.RECOVERY
	z_index = 0
	velocity = Vector2.ZERO
	visual_lift = 0.0
	visual_scale = Vector2(1.18, 0.78)
	recovery_left = maxf(0.0, get_up_recovery_seconds)
	_restore_collision()
	if recovery_left <= 0.0:
		attack_state = AttackState.RUNNING
		visual_scale = Vector2.ONE

func _restore_collision() -> void:
	if not is_node_ready():
		return
	collision_mask = collision_mask_before_jump
	collision_layer = collision_layer_before_jump
	attack_hurtbox.collision_layer = hurtbox_layer_before_jump
