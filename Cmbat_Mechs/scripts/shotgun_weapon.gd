extends CombatWeapon

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectile.tscn")
const PELLET_COUNT := 5

@export var cooldown_seconds := 0.6
@export var spread_degrees := 22.0
@export var damage_at_muzzle := 12
@export var minimum_damage := 2
@export var damage_falloff_distance := 300.0

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
	var muzzle_position := to_global(Vector2(39.0, 0.0))
	cooldown_left = cooldown_seconds
	var total_spread_radians := deg_to_rad(spread_degrees)
	for pellet_index in range(PELLET_COUNT):
		var spread_fraction := float(pellet_index) / float(PELLET_COUNT - 1) - 0.5
		var pellet_direction := direction.rotated(spread_fraction * total_spread_radians)
		var projectile := PROJECTILE_SCENE.instantiate() as CombatProjectile
		projectile.damage = damage_at_muzzle
		projectile.damage_falloff_enabled = true
		projectile.minimum_damage = minimum_damage
		projectile.damage_falloff_distance = damage_falloff_distance
		projectile.attack_source = &"bullet"
		user.get_parent().add_child(projectile)
		projectile.launch(muzzle_position, pellet_direction, user)
	user.get_tree().call_group("zombies", "hear_gunshot", user.global_position)

func display_name() -> String:
	return "SHOTGUN"

func effective_range() -> float:
	return damage_falloff_distance

func _draw() -> void:
	draw_rect(Rect2(5.0, -6.0, 10.0, 12.0), Color("332c30"))
	draw_rect(Rect2(13.0, -5.0, 23.0, 10.0), Color("292b32"))
	draw_rect(Rect2(16.0, -3.0, 18.0, 6.0), Color("aaa89a"))
	draw_rect(Rect2(34.0, -3.0, 5.0, 6.0), Color("d3cda9"))
	draw_rect(Rect2(7.0, 4.0, 7.0, 10.0), Color("6f5440"))
