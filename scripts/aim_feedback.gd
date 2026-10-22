extends Node2D
class_name CombatAimFeedback

var player: CombatPlayer
var hit_marker_left := 0.0

func bind_player(value: CombatPlayer) -> void:
	player = value
	player.hit_confirmed.connect(_on_hit_confirmed)

func _process(delta: float) -> void:
	hit_marker_left = maxf(0.0, hit_marker_left - delta)
	queue_redraw()

func _on_hit_confirmed(_impact_position: Vector2, _heavy: bool) -> void:
	hit_marker_left = 0.22

func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	var cursor := get_viewport().get_mouse_position()
	var weapon: CombatWeapon = player.melee_weapon if player.active_weapon_index == 0 else player.gun_weapon
	var range_origin := player.melee_weapon.global_position if player.active_weapon_index == 0 else player.global_position
	var distance := player.get_global_mouse_position().distance_to(range_origin)
	var in_range := distance <= weapon.effective_range()
	var range_color := Color(0.43, 1.0, 0.67, 0.94) if in_range else Color(1.0, 0.43, 0.39, 0.9)
	if in_range:
		_draw_plus(cursor, range_color, 7.0, 2.0)
	elif player.active_weapon_index == 0:
		_draw_x(cursor, range_color, 7.0, 2.0)
	else:
		draw_circle(cursor, 2.0, range_color)
		draw_arc(cursor, 7.0, 0.0, TAU, 20, Color(0.8, 0.82, 0.85, 0.6), 1.0, true)
	if hit_marker_left > 0.0:
		var alpha := clampf(hit_marker_left / 0.22, 0.0, 1.0)
		var marker_color := Color(1.0, 1.0, 0.92, alpha)
		var diagonals: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
		for direction: Vector2 in diagonals:
			var start: Vector2 = cursor + direction * 11.0
			var end: Vector2 = cursor + direction * 16.0
			draw_line(start, end, marker_color, 2.5, true)

func _draw_plus(center: Vector2, color: Color, size: float, width: float) -> void:
	draw_line(center + Vector2(-size, 0), center + Vector2(size, 0), color, width, true)
	draw_line(center + Vector2(0, -size), center + Vector2(0, size), color, width, true)

func _draw_x(center: Vector2, color: Color, size: float, width: float) -> void:
	draw_line(center + Vector2(-size, -size), center + Vector2(size, size), color, width, true)
	draw_line(center + Vector2(-size, size), center + Vector2(size, -size), color, width, true)
