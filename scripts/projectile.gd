extends Area2D
class_name CombatProjectile

@export var speed := 780.0
@export var damage := 25
@export var lifetime_seconds := 1.6

var direction := Vector2.RIGHT
var owner_body: Node2D
var lifetime_left := 0.0

func launch(origin: Vector2, travel_direction: Vector2, firing_body: Node2D) -> void:
	global_position = origin
	direction = travel_direction.normalized()
	owner_body = firing_body
	lifetime_left = lifetime_seconds
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		queue_free()
		return

	var next_position := global_position + direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, collision_mask)
	if owner_body != null and is_instance_valid(owner_body):
		query.exclude = [owner_body.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if collider is Node and collider.is_in_group("enemies"):
			if collider.take_damage(damage, false, direction):
				if owner_body != null and is_instance_valid(owner_body) and owner_body.has_method("notify_combat_hit"):
					owner_body.notify_combat_hit(hit.get("position", next_position), false)
		queue_free()
		return
	global_position = next_position

func _draw() -> void:
	draw_set_transform(Vector2(0.0, -12.0).rotated(-rotation), 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.88, 0.48))
	draw_line(Vector2(-8.0, 0.0), Vector2.ZERO, Color(1.0, 0.48, 0.27, 0.7), 2.0, true)
