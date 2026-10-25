extends Area2D
class_name CombatProjectile

const EXPLOSION_EFFECT_SCRIPT = preload("res://Cmbat_Mechs/scripts/explosion_effect.gd")

@export var speed := 780.0
@export var damage := 25
@export var lifetime_seconds := 1.6
@export var can_hit_player := false
@export var is_arrow := false
@export var attack_source: StringName = &"bullet"
@export var damage_falloff_enabled := false
@export var minimum_damage := 2
@export var damage_falloff_distance := 300.0
@export var is_rocket := false
@export var explosive := false
@export var explosion_radius := 100.0
@export var explosion_max_damage := 60
@export var explosion_edge_damage := 10

var direction := Vector2.RIGHT
var owner_body: Node2D
var lifetime_left := 0.0
var distance_travelled := 0.0
var has_detonated := false
var ignored_hurtboxes: Array[WeakRef] = []

func launch(origin: Vector2, travel_direction: Vector2, firing_body: Node2D) -> void:
	global_position = origin
	direction = travel_direction.normalized()
	owner_body = firing_body
	lifetime_left = lifetime_seconds
	distance_travelled = 0.0
	has_detonated = false
	rotation = direction.angle()
	queue_redraw()

func _physics_process(delta: float) -> void:
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		queue_free()
		return

	var next_position := global_position + direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next_position, collision_mask)
	query.hit_from_inside = true
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var excluded_rids: Array[RID] = []
	if owner_body != null and is_instance_valid(owner_body):
		excluded_rids.append(owner_body.get_rid())
		var owner_hurtbox := owner_body.find_child("AttackHurtbox", true, false) as CollisionObject2D
		if owner_hurtbox != null:
			excluded_rids.append(owner_hurtbox.get_rid())
	for ignored_ref: WeakRef in ignored_hurtboxes:
		var ignored_hurtbox := ignored_ref.get_ref() as CollisionObject2D
		if ignored_hurtbox != null:
			excluded_rids.append(ignored_hurtbox.get_rid())
	query.exclude = excluded_rids
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if explosive:
			_detonate(hit.get("position", next_position), hit.get("normal", Vector2.ZERO))
			return
		if collider is CombatAttackHurtbox and (collider as CombatAttackHurtbox).enemy == owner_body:
			# Defensive owner check: never let a projectile consume itself on its shooter's hurtbox.
			distance_travelled += global_position.distance_to(next_position)
			global_position = next_position
			return
		var registered_hit := false
		if collider is CombatAttackHurtbox:
			var enemy := (collider as CombatAttackHurtbox).enemy
			if enemy != null and enemy.has_method("should_projectile_pass_through") and enemy.should_projectile_pass_through():
				ignored_hurtboxes.append(weakref(collider))
				distance_travelled += global_position.distance_to(next_position)
				global_position = next_position
				return
			if enemy != null and enemy.is_in_group("enemies") and enemy != owner_body:
				registered_hit = enemy.take_damage(_damage_at_distance(global_position.distance_to(hit.get("position", next_position))), false, direction, 1.0, attack_source)
		elif can_hit_player and collider is CombatPlayer and collider != owner_body:
			(collider as CombatPlayer).take_damage(damage)
			registered_hit = true
		elif collider is CombatPlayer and collider == owner_body:
			# Ignore the shooter if the launch point overlaps its player collider.
			distance_travelled += global_position.distance_to(next_position)
			global_position = next_position
			return
		if registered_hit and owner_body != null and is_instance_valid(owner_body) and owner_body.has_method("notify_combat_hit"):
			owner_body.notify_combat_hit(hit.get("position", next_position), false)
		queue_free()
		return
	distance_travelled += global_position.distance_to(next_position)
	global_position = next_position

func _damage_at_distance(additional_distance: float) -> int:
	if not damage_falloff_enabled or damage_falloff_distance <= 0.0:
		return damage
	var falloff := clampf((distance_travelled + additional_distance) / damage_falloff_distance, 0.0, 1.0)
	return maxi(0, roundi(lerpf(float(damage), float(minimum_damage), falloff)))

func _detonate(impact_position: Vector2, surface_normal: Vector2 = Vector2.ZERO) -> void:
	if has_detonated:
		return
	has_detonated = true
	var blast_center := impact_position + surface_normal.normalized()
	global_position = blast_center
	var enemy_damaged := _damage_enemies_in_blast(blast_center)
	_damage_player_in_blast(blast_center)
	var effect := EXPLOSION_EFFECT_SCRIPT.new() as Node2D
	effect.set("radius", explosion_radius)
	get_parent().add_child(effect)
	effect.global_position = blast_center
	if enemy_damaged and owner_body != null and is_instance_valid(owner_body) and owner_body.has_method("notify_combat_hit"):
		owner_body.notify_combat_hit(blast_center, true)
	queue_free()

func _damage_enemies_in_blast(blast_center: Vector2) -> bool:
	var damaged_enemy := false
	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as CombatEnemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance := enemy.global_position.distance_to(blast_center)
		if distance > explosion_radius or _blast_path_is_blocked(blast_center, enemy.global_position):
			continue
		var amount := _explosion_damage_at_distance(distance)
		if enemy.take_damage(amount, false, Vector2.ZERO, 1.0, attack_source):
			damaged_enemy = true
	return damaged_enemy

func _damage_player_in_blast(blast_center: Vector2) -> void:
	var player := get_tree().get_first_node_in_group("player") as CombatPlayer
	if player == null or not is_instance_valid(player):
		return
	var distance := player.global_position.distance_to(blast_center)
	if distance > explosion_radius or _blast_path_is_blocked(blast_center, player.global_position):
		return
	player.take_damage(_explosion_damage_at_distance(distance))

func _explosion_damage_at_distance(distance: float) -> int:
	if explosion_radius <= 0.0:
		return explosion_max_damage
	var falloff := clampf(distance / explosion_radius, 0.0, 1.0)
	return maxi(0, roundi(lerpf(float(explosion_max_damage), float(explosion_edge_damage), falloff)))

func _blast_path_is_blocked(blast_center: Vector2, target_position: Vector2) -> bool:
	if blast_center.distance_squared_to(target_position) <= 0.001:
		return false
	var query := PhysicsRayQueryParameters2D.create(blast_center, target_position, 4)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func deflect(new_direction: Vector2, new_owner: Node2D) -> void:
	if new_direction.length_squared() <= 0.001:
		return
	direction = new_direction.normalized()
	owner_body = new_owner
	can_hit_player = false
	collision_mask = 12 # Walls and enemy attack hurtboxes.
	attack_source = &"deflected"
	rotation = direction.angle()
	queue_redraw()

func _draw() -> void:
	if is_rocket:
		draw_rect(Rect2(-13.0, -4.0, 23.0, 8.0), Color("58705d"))
		draw_colored_polygon(PackedVector2Array([Vector2(10.0, -4.0), Vector2(17.0, 0.0), Vector2(10.0, 4.0)]), Color("b7b59a"))
		draw_colored_polygon(PackedVector2Array([Vector2(-8.0, -4.0), Vector2(-15.0, -9.0), Vector2(-12.0, -2.0)]), Color("884f41"))
		draw_colored_polygon(PackedVector2Array([Vector2(-8.0, 4.0), Vector2(-15.0, 9.0), Vector2(-12.0, 2.0)]), Color("884f41"))
		draw_rect(Rect2(-17.0, -2.0, 5.0, 4.0), Color("ff9a45"))
		return
	if is_arrow:
		# Draw the arrow along local +X; it remains visible while travelling.
		draw_line(Vector2(-13.0, 0.0), Vector2(9.0, 0.0), Color("62452c"), 3.0)
		draw_line(Vector2(8.0, 0.0), Vector2(13.0, 0.0), Color("d8d2bf"), 2.0)
		draw_line(Vector2(-11.0, -1.0), Vector2(-15.0, -5.0), Color("e4e0d4"), 2.0)
		draw_line(Vector2(-11.0, 1.0), Vector2(-15.0, 5.0), Color("e4e0d4"), 2.0)
		return
	draw_rect(Rect2(-3.0, -3.0, 8.0, 6.0), Color("ffae55"))
	draw_rect(Rect2(0.0, -2.0, 5.0, 4.0), Color("ffe18a"))
	draw_rect(Rect2(-8.0, -2.0, 6.0, 4.0), Color("e86d45", 0.75))
