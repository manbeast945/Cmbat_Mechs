extends Area2D
class_name CombatAttackHurtbox

const ATTACK_HITBOX_LAYER := 8

var enemy: CombatEnemy
var appearance := 0

func _ready() -> void:
	var visual := get_parent() as Node2D
	enemy = visual.get_parent() as CombatEnemy if visual != null else null
	if visual != null:
		var appearance_value: Variant = visual.get("appearance")
		if appearance_value is int:
			appearance = appearance_value

	collision_layer = ATTACK_HITBOX_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	_build_hitbox()

func _build_hitbox() -> void:
	if enemy == null:
		return
	if enemy.attack_hitbox_style == CombatEnemy.AttackHitboxStyle.CAPSULE:
		_add_capsule()
	else:
		_add_silhouette()

func _add_capsule() -> void:
	var shape := CapsuleShape2D.new()
	shape.radius = 16.0 if appearance == 2 else 24.0 if appearance == 3 else 20.0 if appearance == 1 else 22.0
	shape.height = 54.0 if appearance != 3 else 56.0
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0.0, -26.0)
	collision.shape = shape
	add_child(collision)

func _add_silhouette() -> void:
	if appearance == 5:
		_add_rect(Vector2(-19.0, -28.0), Vector2(39.0, 22.0))
		_add_rect(Vector2(11.0, -40.0), Vector2(20.0, 18.0))
		_add_rect(Vector2(12.0, -47.0), Vector2(8.0, 8.0))
		_add_rect(Vector2(21.0, -46.0), Vector2(8.0, 8.0))
		_add_rect(Vector2(-19.0, -12.0), Vector2(7.0, 12.0))
		_add_rect(Vector2(9.0, -12.0), Vector2(7.0, 12.0))
		return
	if appearance == 1:
		_add_rect(Vector2(-13.0, -8.0), Vector2(10.0, 8.0))
		_add_rect(Vector2(3.0, -8.0), Vector2(10.0, 8.0))
		_add_rect(Vector2(-9.0, -34.0), Vector2(18.0, 25.0))
		_add_rect(Vector2(-17.0, -29.0), Vector2(6.0, 17.0))
		_add_rect(Vector2(11.0, -29.0), Vector2(6.0, 17.0))
		_add_rect(Vector2(-20.0, -16.0), Vector2(8.0, 5.0))
		_add_rect(Vector2(12.0, -16.0), Vector2(8.0, 5.0))
		_add_rect(Vector2(-11.0, -51.0), Vector2(22.0, 20.0))
		return

	var runner := appearance == 2
	var brute := appearance == 3
	var torso_half_width := 18.0 if brute else 11.0 if runner else 16.0
	var head_half_width := 12.0 if brute else 8.0 if runner else 12.0
	var arm_half_width := 4.0 if runner else 6.0
	var torso_left := -torso_half_width
	_add_rect(Vector2(-14.0, -8.0), Vector2(11.0, 8.0))
	_add_rect(Vector2(3.0, -8.0), Vector2(11.0, 8.0))
	_add_rect(Vector2(torso_left - 2.0, -32.0), Vector2(torso_half_width * 2.0 + 4.0, 25.0))
	_add_rect(Vector2(torso_left - arm_half_width, -27.0), Vector2(arm_half_width, 15.0))
	_add_rect(Vector2(torso_half_width, -27.0), Vector2(arm_half_width, 15.0))
	_add_rect(Vector2(-head_half_width, -52.0), Vector2(head_half_width * 2.0, 24.0))

func _add_rect(rect_position: Vector2, rect_size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect_size
	var collision := CollisionShape2D.new()
	collision.position = rect_position + rect_size * 0.5
	collision.shape = shape
	add_child(collision)
