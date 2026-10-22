extends CharacterBody2D
class_name CombatEnemy

@export var move_speed := 72.0
@export var max_health := 70
@export var contact_damage := 10
@export var contact_cooldown_seconds := 0.9

var health := 70
var player: CombatPlayer
var contact_cooldown_left := 0.0
var stagger_left := 0.0
var hit_flash_left := 0.0
var reaction_strength := 0.0
var knockback_velocity := Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	health = max_health

func _physics_process(delta: float) -> void:
	contact_cooldown_left = maxf(0.0, contact_cooldown_left - delta)
	stagger_left = maxf(0.0, stagger_left - delta)
	hit_flash_left = maxf(0.0, hit_flash_left - delta)
	if player == null or not is_instance_valid(player) or player.is_defeated:
		velocity = Vector2.ZERO
		return
	if stagger_left > 0.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	if to_player.length() > 31.0:
		velocity = to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if global_position.distance_to(player.global_position) <= 33.0 and contact_cooldown_left <= 0.0:
		player.take_damage(contact_damage)
		contact_cooldown_left = contact_cooldown_seconds

func take_damage(amount: int, heavy := false, hit_direction := Vector2.ZERO, knockback_multiplier := 1.0) -> bool:
	if health <= 0:
		return false
	health = maxi(0, health - amount)
	stagger_left = 0.30 if heavy else 0.12
	hit_flash_left = 0.12 if heavy else 0.08
	reaction_strength = 1.0 if heavy else 0.45
	knockback_velocity = hit_direction.normalized() * (270.0 if heavy else 105.0) * knockback_multiplier
	queue_redraw()
	if health == 0:
		queue_free()
	return true
