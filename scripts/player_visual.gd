extends Node2D

const OUTLINE := Color("282332")
const COAT := Color("4d8792")
const COAT_LIGHT := Color("79b2a0")
const SKIN := Color("e6bb88")
const HAIR := Color("49352e")

var player: CombatPlayer

func _ready() -> void:
	player = get_parent() as CombatPlayer

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if player == null:
		return
	var aim := (get_global_mouse_position() - player.global_position).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
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
