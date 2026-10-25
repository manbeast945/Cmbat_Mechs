extends Node2D

enum Appearance { ZOMBIE, SKELETON, RUNNER, BRUTE, JUMPER, STICKER }

@export var appearance := Appearance.ZOMBIE

const OUTLINE := Color("292533")

var enemy: CombatEnemy

func _ready() -> void:
	enemy = get_parent() as CombatEnemy

func _process(_delta: float) -> void:
	if enemy != null:
		var jumper := enemy as CombatJumper
		var sticker := enemy as CombatSticker
		var lift: float = jumper.visual_lift if jumper != null else sticker.visual_lift if sticker != null else 0.0
		position = Vector2(0.0, -lift)
		var flash_ratio := enemy.hit_flash_left / (0.12 if enemy.reaction_strength >= 1.0 else 0.08)
		modulate = Color.WHITE.lerp(Color(1.0, 0.52, 0.30), clampf(flash_ratio, 0.0, 1.0))
		var stagger_ratio := enemy.stagger_left / (0.30 if enemy.reaction_strength >= 1.0 else 0.12)
		var stagger_scale := Vector2.ONE.lerp(Vector2(1.25, 0.78), clampf(stagger_ratio, 0.0, 1.0) * enemy.reaction_strength * 0.55)
		var flinch_scale := Vector2.ONE.lerp(Vector2(1.08, 0.92), clampf(flash_ratio, 0.0, 1.0) * enemy.reaction_strength * 0.35)
		var facing_x := 1.0
		var appearance_scale := Vector2.ONE
		if appearance == Appearance.SKELETON and enemy is CombatSkeleton:
			facing_x = -1.0 if (enemy as CombatSkeleton).bow.aim_direction.x < 0.0 else 1.0
		elif appearance == Appearance.STICKER and enemy is CombatSticker:
			facing_x = -1.0 if sticker.facing_direction.x < 0.0 else 1.0
			appearance_scale = Vector2.ONE * (0.48 if sticker.attack_state == CombatSticker.AttackState.LATCHED else 0.72)
		scale = Vector2(facing_x, 1.0) * enemy.visual_scale * stagger_scale * flinch_scale * appearance_scale
	queue_redraw()

func _draw() -> void:
	if enemy == null:
		return
	var jumper := enemy as CombatJumper
	var sticker := enemy as CombatSticker
	if jumper != null and jumper.landing_telegraph_visible:
		_draw_jumper_telegraph(jumper)
	var shadow_y: float = jumper.visual_lift if jumper != null else 0.0
	draw_rect(Rect2(-17.0, shadow_y, 34.0, 7.0), Color("292632", 0.54))
	if appearance == Appearance.SKELETON:
		_draw_skeleton()
	elif appearance == Appearance.JUMPER:
		_draw_jumper()
	elif appearance == Appearance.STICKER:
		_draw_sticker(sticker)
	else:
		_draw_zombie()
	draw_rect(Rect2(-18.0, -55.0, 36.0, 5.0), OUTLINE)
	draw_rect(Rect2(-17.0, -54.0, 34.0, 3.0), Color("4a3038"))
	var health_ratio := float(enemy.health) / float(enemy.max_health)
	draw_rect(Rect2(-17.0, -54.0, 34.0 * health_ratio, 3.0), Color("d76352"))

func _draw_jumper_telegraph(jumper: CombatJumper) -> void:
	var center := to_local(jumper.landing_position)
	var warning := Color("e9a34d", 0.82)
	var inverse_scale := Vector2(1.0 / maxf(absf(scale.x), 0.001), 1.0 / maxf(absf(scale.y), 0.001))
	draw_set_transform(center, 0.0, inverse_scale)
	draw_arc(Vector2.ZERO, jumper.landing_aoe_radius, 0.0, TAU, 36, warning, 2.0, true)
	draw_arc(Vector2.ZERO, 4.0, 0.0, TAU, 16, warning, 2.0, true)
	draw_line(Vector2(-7.0, 0.0), Vector2(7.0, 0.0), warning, 1.5)
	draw_line(Vector2(0.0, -7.0), Vector2(0.0, 7.0), warning, 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_jumper() -> void:
	var shell := enemy.enemy_color
	var shell_light := shell.lightened(0.24)
	draw_rect(Rect2(-14.0, -11.0, 11.0, 11.0), OUTLINE)
	draw_rect(Rect2(3.0, -11.0, 11.0, 11.0), OUTLINE)
	draw_rect(Rect2(-11.0, -9.0, 7.0, 7.0), Color("54483f"))
	draw_rect(Rect2(6.0, -9.0, 7.0, 7.0), Color("54483f"))
	draw_rect(Rect2(-17.0, -34.0, 34.0, 26.0), OUTLINE)
	draw_rect(Rect2(-14.0, -32.0, 28.0, 21.0), shell)
	draw_rect(Rect2(-20.0, -27.0, 8.0, 14.0), OUTLINE)
	draw_rect(Rect2(12.0, -27.0, 8.0, 14.0), OUTLINE)
	draw_rect(Rect2(-17.0, -25.0, 5.0, 10.0), shell_light)
	draw_rect(Rect2(12.0, -25.0, 5.0, 10.0), shell)
	draw_rect(Rect2(-12.0, -51.0, 24.0, 20.0), OUTLINE)
	draw_rect(Rect2(-9.0, -48.0, 18.0, 14.0), shell_light)
	draw_rect(Rect2(-5.0, -42.0, 3.0, 3.0), Color("352d34"))
	draw_rect(Rect2(3.0, -42.0, 3.0, 3.0), Color("352d34"))

func _draw_sticker(sticker: CombatSticker) -> void:
	var fur := enemy.enemy_color
	var light_fur := fur.lightened(0.22)
	var latched := sticker != null and sticker.attack_state == CombatSticker.AttackState.LATCHED
	var crouched := latched or (sticker != null and sticker.attack_state == CombatSticker.AttackState.RECOVERY)
	var body_y := -25.0 if not crouched else -19.0
	draw_rect(Rect2(-19.0, -7.0, 12.0, 7.0), OUTLINE)
	draw_rect(Rect2(8.0, -7.0, 12.0, 7.0), OUTLINE)
	draw_rect(Rect2(-16.0, -6.0, 8.0, 4.0), fur.darkened(0.16))
	draw_rect(Rect2(10.0, -6.0, 5.0, 4.0), fur)
	draw_rect(Rect2(-19.0, body_y - 4.0, 39.0, 21.0), OUTLINE)
	draw_rect(Rect2(-16.0, body_y, 33.0, 14.0), fur)
	draw_rect(Rect2(-9.0, body_y + 2.0, 17.0, 7.0), light_fur)
	draw_rect(Rect2(12.0, body_y - 12.0, 18.0, 16.0), OUTLINE)
	draw_rect(Rect2(14.0, body_y - 10.0, 14.0, 12.0), light_fur)
	draw_rect(Rect2(20.0, body_y - 7.0, 3.0, 3.0), Color("332832"))
	draw_rect(Rect2(24.0, body_y - 3.0, 8.0, 4.0), Color("a85f4c"))
	draw_rect(Rect2(13.0, body_y - 15.0, 7.0, 8.0), OUTLINE)
	draw_rect(Rect2(22.0, body_y - 14.0, 7.0, 7.0), OUTLINE)
	draw_rect(Rect2(15.0, body_y - 13.0, 4.0, 5.0), fur.darkened(0.2))
	draw_rect(Rect2(23.0, body_y - 12.0, 4.0, 4.0), fur.darkened(0.2))
	draw_rect(Rect2(-18.0, body_y + 12.0, 6.0, 10.0), OUTLINE)
	draw_rect(Rect2(10.0, body_y + 12.0, 6.0, 10.0), OUTLINE)
	draw_rect(Rect2(-17.0, body_y + 13.0, 3.0, 7.0), fur)
	draw_rect(Rect2(11.0, body_y + 13.0, 3.0, 7.0), fur)

func _draw_zombie() -> void:
	var skin := enemy.enemy_color
	var runner := appearance == Appearance.RUNNER
	var brute := appearance == Appearance.BRUTE
	var torso_half_width := 18.0 if brute else 11.0 if runner else 16.0
	var head_half_width := 12.0 if brute else 8.0 if runner else 12.0
	var cloth := Color("987642") if runner else Color("51443c") if brute else Color("465849")
	var torso_left := -torso_half_width
	var torso_width := torso_half_width * 2.0
	var head_left := -head_half_width
	var head_width := head_half_width * 2.0
	draw_rect(Rect2(-14.0, -8.0, 11.0, 8.0), OUTLINE)
	draw_rect(Rect2(3.0, -8.0, 11.0, 8.0), OUTLINE)
	draw_rect(Rect2(-11.0, -7.0, 7.0, 5.0), Color("6a5948"))
	draw_rect(Rect2(6.0, -7.0, 7.0, 5.0), Color("6a5948"))
	draw_rect(Rect2(torso_left - 2.0, -32.0, torso_width + 4.0, 25.0), OUTLINE)
	draw_rect(Rect2(torso_left, -30.0, torso_width, 22.0), cloth)
	var arm_half_width := 4.0 if runner else 6.0
	var left_arm_x := torso_left - arm_half_width
	var right_arm_x := torso_half_width
	draw_rect(Rect2(left_arm_x, -27.0, arm_half_width, 15.0), OUTLINE)
	draw_rect(Rect2(right_arm_x, -27.0, arm_half_width, 15.0), OUTLINE)
	draw_rect(Rect2(left_arm_x + 2.0, -25.0, maxf(2.0, arm_half_width - 3.0), 11.0), skin.darkened(0.12))
	draw_rect(Rect2(right_arm_x + 2.0, -25.0, maxf(2.0, arm_half_width - 3.0), 11.0), skin)
	draw_rect(Rect2(-3.0, -29.0, 6.0, 19.0), Color("a69c69"))
	draw_rect(Rect2(head_left, -49.0, head_width, 21.0), OUTLINE)
	draw_rect(Rect2(head_left + 3.0, -48.0, head_width - 6.0, 16.0), skin)
	draw_rect(Rect2(head_left + 3.0, -52.0, head_width - 6.0, 6.0), Color("564333"))
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
