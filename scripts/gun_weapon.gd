extends CombatWeapon

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")

@export var cooldown_seconds := 0.24
@export var effective_attack_range := 1248.0

var cooldown_left := 0.0

func _process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	var user := get_parent() as CharacterBody2D
	if user != null:
		var aim := get_global_mouse_position() - user.global_position
		if aim.length_squared() > 0.0001:
			rotation = aim.angle()
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
	projectile.launch(user.global_position, direction, user)

func display_name() -> String:
	return "GUN"

func effective_range() -> float:
	return effective_attack_range

func _draw() -> void:
	draw_rect(Rect2(5.0, -5.0, 9.0, 10.0), Color("332c30"))
	draw_rect(Rect2(12.0, -4.0, 18.0, 8.0), Color("292b32"))
	draw_rect(Rect2(14.0, -3.0, 14.0, 4.0), Color("aaa89a"))
	draw_rect(Rect2(28.0, -2.0, 5.0, 4.0), Color("d3cda9"))
	draw_rect(Rect2(7.0, 3.0, 5.0, 9.0), Color("6f5440"))
