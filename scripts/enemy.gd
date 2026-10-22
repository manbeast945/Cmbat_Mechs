extends CharacterBody2D
class_name CombatEnemy

@export var move_speed := 72.0
@export var max_health := 70
@export var contact_damage := 10
@export var contact_cooldown_seconds := 0.9

var health := 70
var player: CombatPlayer
var contact_cooldown_left := 0.0

func _ready() -> void:
	add_to_group("enemies")
	health = max_health

func _physics_process(delta: float) -> void:
	contact_cooldown_left = maxf(0.0, contact_cooldown_left - delta)
	if player == null or not is_instance_valid(player) or player.is_defeated:
		velocity = Vector2.ZERO
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

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	queue_redraw()
	if health == 0:
		queue_free()

