extends Node2D

enum Appearance { ZOMBIE, SKELETON }

@export var appearance := Appearance.ZOMBIE

const OUTLINE := Color("292533")

var enemy: CombatEnemy

func _ready() -> void:
	enemy = get_parent() as CombatEnemy

func _process(_delta: float) -> void:
	if enemy != null:
		var flash_ratio := enemy.hit_flash_left / (0.12 if enemy.reaction_strength >= 1.0 else 0.08)
		modulate = Color.WHITE.lerp(Color(1.0, 0.52, 0.30), clampf(flash_ratio, 0.0, 1.0))
		var stagger_ratio := enemy.stagger_left / (0.30 if enemy.reaction_strength >= 1.0 else 0.12)
		var stagger_scale := Vector2.ONE.lerp(Vector2(1.25, 0.78), clampf(stagger_ratio, 0.0, 1.0) * enemy.reaction_strength * 0.55)
		scale = enemy.visual_scale * stagger_scale
	queue_redraw()

func _draw() -> void:
	if enemy == null:
		return
	draw_rect(Rect2(-17.0, 0.0, 34.0, 7.0), Color("292632", 0.54))
	if appearance == Appearance.SKELETON:
		_draw_skeleton()
	else:
		_draw_zombie()
	draw_rect(Rect2(-18.0, -55.0, 36.0, 5.0), OUTLINE)
	draw_rect(Rect2(-17.0, -54.0, 34.0, 3.0), Color("4a3038"))
	var health_ratio := float(enemy.health) / float(enemy.max_health)
	draw_rect(Rect2(-17.0, -54.0, 34.0 * health_ratio, 3.0), Color("d76352"))

func _draw_zombie() -> void:
	var skin := enemy.enemy_color
	var cloth := Color("465849")
	draw_rect(Rect2(-13.0, -8.0, 10.0, 8.0), OUTLINE)
	draw_rect(Rect2(3.0, -8.0, 10.0, 8.0), OUTLINE)
	draw_rect(Rect2(-10.0, -7.0, 6.0, 5.0), Color("6a5948"))
	draw_rect(Rect2(6.0, -7.0, 6.0, 5.0), Color("6a5948"))
	draw_rect(Rect2(-16.0, -32.0, 32.0, 25.0), OUTLINE)
	draw_rect(Rect2(-13.0, -30.0, 26.0, 22.0), cloth)
	draw_rect(Rect2(-19.0, -27.0, 6.0, 15.0), OUTLINE)
	draw_rect(Rect2(13.0, -27.0, 6.0, 15.0), OUTLINE)
	draw_rect(Rect2(-17.0, -25.0, 4.0, 11.0), skin.darkened(0.12))
	draw_rect(Rect2(13.0, -25.0, 4.0, 11.0), skin)
	draw_rect(Rect2(-3.0, -29.0, 6.0, 19.0), Color("a69c69"))
	draw_rect(Rect2(-12.0, -49.0, 24.0, 21.0), OUTLINE)
	draw_rect(Rect2(-9.0, -48.0, 18.0, 16.0), skin)
	draw_rect(Rect2(-9.0, -52.0, 18.0, 6.0), Color("564333"))
	draw_rect(Rect2(-4.0, -42.0, 3.0, 3.0), Color("f0c653"))
	draw_rect(Rect2(4.0, -42.0, 3.0, 3.0), Color("f0c653"))
	draw_rect(Rect2(-3.0, -34.0, 8.0, 2.0), Color("704038"))

func _draw_skeleton() -> void:
	var bone := Color("ded9c4")
	var bone_light := Color("f2ecd8")
	draw_rect(Rect2(-13.0, -8.0, 10.0, 8.0), OUTLINE)
	draw_rect(Rect2(3.0, -8.0, 10.0, 8.0), OUTLINE)
	draw_rect(Rect2(-10.0, -7.0, 6.0, 5.0), Color("77716a"))
	draw_rect(Rect2(6.0, -7.0, 6.0, 5.0), Color("77716a"))
	# Narrow ribs and visible bone limbs distinguish the skeleton silhouette.
	draw_rect(Rect2(-5.0, -34.0, 10.0, 25.0), OUTLINE)
	draw_rect(Rect2(-3.0, -32.0, 6.0, 21.0), bone)
	for y in [-27.0, -22.0, -17.0]:
		draw_rect(Rect2(-9.0, y, 18.0, 2.0), bone_light)
	draw_rect(Rect2(-17.0, -29.0, 6.0, 17.0), OUTLINE)
	draw_rect(Rect2(11.0, -29.0, 6.0, 17.0), OUTLINE)
	draw_rect(Rect2(-15.0, -27.0, 3.0, 13.0), bone)
	draw_rect(Rect2(12.0, -27.0, 3.0, 13.0), bone)
	draw_rect(Rect2(-20.0, -16.0, 8.0, 5.0), bone_light)
	draw_rect(Rect2(12.0, -16.0, 8.0, 5.0), bone_light)
	draw_rect(Rect2(-11.0, -51.0, 22.0, 20.0), OUTLINE)
	draw_rect(Rect2(-8.0, -49.0, 16.0, 15.0), bone_light)
	draw_rect(Rect2(-9.0, -51.0, 18.0, 4.0), bone)
	draw_rect(Rect2(-5.0, -43.0, 4.0, 4.0), Color("3c3942"))
	draw_rect(Rect2(1.0, -43.0, 4.0, 4.0), Color("3c3942"))
	draw_rect(Rect2(-2.0, -36.0, 4.0, 3.0), bone)
