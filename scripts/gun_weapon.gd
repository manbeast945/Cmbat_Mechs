extends CombatWeapon

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")

@export var cooldown_seconds := 0.24
@export var effective_attack_range := 1248.0

var cooldown_left := 0.0

func _process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	queue_redraw()

func use(user: CharacterBody2D, target: Vector2) -> void:
	if cooldown_left > 0.0:
		return
	var direction := (target - user.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()
	cooldown_left = cooldown_seconds
	var projectile = PROJECTILE_SCENE.instantiate()
	user.get_parent().add_child(projectile)
	projectile.launch(user.global_position + direction * 22.0, direction, user)

func display_name() -> String:
	return "GUN"

func effective_range() -> float:
	return effective_attack_range

func _draw() -> void:
	draw_line(Vector2(8.0, 0.0), Vector2(27.0, 0.0), Color(0.18, 0.2, 0.23), 7.0, true)
	draw_line(Vector2(9.0, 0.0), Vector2(27.0, 0.0), Color(0.82, 0.84, 0.82), 3.0, true)
