extends Node2D
class_name CombatWeapon

func use(_user: CharacterBody2D, _target: Vector2) -> void:
	pass

func display_name() -> String:
	return "WEAPON"

func effective_range() -> float:
	return INF

func get_effective_range_origin(user: CharacterBody2D) -> Vector2:
	return user.global_position
