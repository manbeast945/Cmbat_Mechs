extends Node2D
class_name CombatWeapon

func use(_user: CharacterBody2D, _target: Vector2) -> void:
	pass

func display_name() -> String:
	return "WEAPON"

func effective_range() -> float:
	return INF
