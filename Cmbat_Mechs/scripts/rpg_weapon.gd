extends CombatWeapon

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")

@export var cooldown_seconds := 1.2
@export var projectile_speed := 300.0
@export var projectile_lifetime := 100000
@export var explosion_radius := 100.0
@export var explosion_max_damage := 60
@export var explosion_edge_damage := 10

var cooldown_left := 0.0

func _process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)
	var user := get_parent() as CharacterBody2D
	if user != null:
		var aim := get_global_mouse_position() - global_position
		if aim.length_squared() > 0.0001:
			global_rotation = aim.angle()
	queue_redraw()

func use(user: CharacterBody2D, target: Vector2) -> void:
	if cooldown_left > 0.0:
		return
	var direction := (target - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	global_rotation = direction.angle()
	var muzzle_position := to_global(Vector2(41.0, 0.0))
	cooldown_left = cooldown_seconds
	var rocket := PROJECTILE_SCENE.instantiate() as CombatProjectile
	rocket.speed = projectile_speed
	rocket.lifetime_seconds = projectile_lifetime
	rocket.collision_mask = 13 # Player body, walls, and enemy attack hurtboxes.
	rocket.can_hit_player = true
	rocket.is_rocket = true
	rocket.explosive = true
	rocket.explosion_radius = explosion_radius
	rocket.explosion_max_damage = explosion_max_damage
	rocket.explosion_edge_damage = explosion_edge_damage
	rocket.attack_source = &"rpg"
	user.get_parent().add_child(rocket)
	rocket.launch(muzzle_position, direction, user)
	user.get_tree().call_group("zombies", "hear_gunshot", user.global_position)

func display_name() -> String:
	return "RPG"

func effective_range() -> float:
	return projectile_speed * projectile_lifetime

func _draw() -> void:
	draw_rect(Rect2(4.0, -8.0, 10.0, 16.0), Color("383339"))
	draw_rect(Rect2(11.0, -7.0, 28.0, 14.0), Color("596c57"))
	draw_rect(Rect2(17.0, -4.0, 19.0, 8.0), Color("92977a"))
	draw_rect(Rect2(36.0, -5.0, 7.0, 10.0), Color("b8b69a"))
	draw_rect(Rect2(8.0, 5.0, 8.0, 10.0), Color("59483d"))
	draw_rect(Rect2(14.0, -12.0, 7.0, 5.0), Color("332f35"))
