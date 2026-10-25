extends Node2D

const OUTLINE := Color("282332")
const COAT := Color("4d8792")
const COAT_LIGHT := Color("79b2a0")
const SKIN := Color("e6bb88")
const HAIR := Color("49352e")

var player: CombatPlayer
var dash_trail_time_left := 0.0
var dash_trail_direction := Vector2.ZERO

func _ready() -> void:
	player = get_parent() as CombatPlayer

func _process(delta: float) -> void:
	if player != null and player.dash_time_left > 0.0:
		dash_trail_direction = player.dash_direction
		dash_trail_time_left = 0.35
	else:
		dash_trail_time_left = maxf(0.0, dash_trail_time_left - delta)
	queue_redraw()

func _draw() -> void:
	if player == null:
		return
	var aim := (get_global_mouse_position() - player.global_position).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	_draw_dash_trail()
	# Shadow and boots anchor the sprite at its physics position.
	draw_rect(Rect2(-18.0, -1.0, 36.0, 8.0), Color("292632", 0.58))
	draw_rect(Rect2(-12.0, -6.0, 9.0, 8.0), OUTLINE)
	draw_rect(Rect2(3.0, -6.0, 9.0, 8.0), OUTLINE)
	draw_rect(Rect2(-10.0, -5.0, 6.0, 5.0), Color("80705c"))
	draw_rect(Rect2(5.0, -5.0, 6.0, 5.0), Color("80705c"))
	# Coat, shoulders and belt use hard-edged blocks on a 2 px grid.
	draw_rect(Rect2(-15.0, -31.0, 30.0, 24.0), OUTLINE)
	draw_rect(Rect2(-12.0, -30.0, 24.0, 22.0), COAT)
	draw_rect(Rect2(-15.0, -25.0, 5.0, 14.0), OUTLINE)
	draw_rect(Rect2(10.0, -25.0, 5.0, 14.0), OUTLINE)
	draw_rect(Rect2(-13.0, -24.0, 4.0, 11.0), COAT_LIGHT)
	draw_rect(Rect2(9.0, -24.0, 4.0, 11.0), COAT)
	draw_rect(Rect2(-11.0, -12.0, 22.0, 3.0), Color("c69c62"))
	draw_rect(Rect2(-2.0, -28.0, 4.0, 15.0), COAT_LIGHT)
	# Head and hair sit above the body in the three-quarter view.
	draw_rect(Rect2(-11.0, -48.0, 22.0, 20.0), OUTLINE)
	draw_rect(Rect2(-8.0, -50.0, 16.0, 3.0), OUTLINE)
	draw_rect(Rect2(-8.0, -46.0, 16.0, 15.0), SKIN)
	draw_rect(Rect2(-8.0, -49.0, 16.0, 5.0), HAIR)
	draw_rect(Rect2(-11.0, -45.0, 4.0, 8.0), HAIR)
	# Place the eyes on the side of the face toward the cursor.
	var face_side := Vector2(signf(aim.x), signf(aim.y) * 0.35)
	var eye_center := Vector2(0.0, -38.0) + face_side * 3.0
	draw_rect(Rect2(eye_center + Vector2(-3.0, -1.0), Vector2(2.0, 2.0)), OUTLINE)
	draw_rect(Rect2(eye_center + Vector2(2.0, -1.0), Vector2(2.0, 2.0)), OUTLINE)

func _draw_dash_trail() -> void:
	if dash_trail_time_left <= 0.0 or dash_trail_direction == Vector2.ZERO:
		return
	var fade := clampf(dash_trail_time_left / 0.35, 0.0, 1.0)
	var backward := -dash_trail_direction
	var side := Vector2(-backward.y, backward.x)
	for index in range(4):
		var offset := backward * (16.0 + float(index) * 9.0)
		var spread := side * (float(index) - 1.5) * 5.0
		var start := Vector2(0.0, -24.0) + offset + spread
		var finish := start + backward * 19.0
		var alpha := fade * (0.78 - float(index) * 0.11)
		draw_line(start, finish, Color("a9f5dc", alpha), 8.0 - float(index), true)
	for index in range(2):
		var afterimage_offset := backward * (13.0 + float(index) * 17.0)
		var afterimage_alpha := fade * (0.48 - float(index) * 0.14)
		_draw_dash_afterimage(afterimage_offset, afterimage_alpha)

func _draw_dash_afterimage(offset: Vector2, alpha: float) -> void:
	var edge := Color("b9ffe6", alpha)
	var fill := Color("62bea9", alpha)
	draw_rect(Rect2(offset + Vector2(-13.0, -30.0), Vector2(26.0, 22.0)), edge)
	draw_rect(Rect2(offset + Vector2(-10.0, -28.0), Vector2(20.0, 18.0)), fill)
	draw_rect(Rect2(offset + Vector2(-10.0, -49.0), Vector2(20.0, 20.0)), edge)
	draw_rect(Rect2(offset + Vector2(-7.0, -46.0), Vector2(14.0, 14.0)), fill)
	draw_rect(Rect2(offset + Vector2(-12.0, -8.0), Vector2(8.0, 8.0)), edge)
	draw_rect(Rect2(offset + Vector2(4.0, -8.0), Vector2(8.0, 8.0)), edge)
