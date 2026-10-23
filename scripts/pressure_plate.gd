extends Area2D
class_name CombatEnemyDispenser

@export var display_label := "ENEMY"
@export var indicator_color := Color.WHITE
@export var spawn_offset := Vector2(0.0, 68.0)

var enemy_scene: PackedScene
var player: CombatPlayer
var player_inside := false
var activation_flash_left := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 25.0
	shape_node.shape = shape
	add_child(shape_node)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	activation_flash_left = maxf(0.0, activation_flash_left - delta)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or player_inside:
		return
	player_inside = true
	call_deferred("_spawn_enemy")
	activation_flash_left = 0.28

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _spawn_enemy() -> void:
	if enemy_scene == null or player == null or not is_instance_valid(player):
		return
	var enemy: CombatEnemy = enemy_scene.instantiate()
	enemy.player = player
	enemy.position = position + spawn_offset
	get_parent().add_child(enemy)

func _draw() -> void:
	var plate_color := indicator_color
	if activation_flash_left > 0.0:
		plate_color = plate_color.lightened(0.45)
	# Recessed stone plate with stepped pixel edges; trigger and label logic are unchanged.
	draw_rect(Rect2(Vector2(-28.0, -16.0), Vector2(56.0, 34.0)), Color("28272d"))
	draw_rect(Rect2(Vector2(-25.0, -16.0), Vector2(50.0, 3.0)), Color("8a8275"))
	draw_rect(Rect2(Vector2(-25.0, 13.0), Vector2(50.0, 3.0)), Color("4c4947"))
	draw_rect(Rect2(Vector2(-25.0, -13.0), Vector2(50.0, 26.0)), Color("4c4947"))
	draw_rect(Rect2(Vector2(-21.0, -9.0), Vector2(42.0, 18.0)), plate_color.darkened(0.32))
	draw_rect(Rect2(Vector2(-18.0, -6.0), Vector2(36.0, 12.0)), plate_color)
	draw_rect(Rect2(Vector2(-14.0, -4.0), Vector2(8.0, 2.0)), plate_color.lightened(0.24))
	var font := ThemeDB.fallback_font
	var label_size := font.get_string_size(display_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	draw_string(font, Vector2(-label_size.x * 0.5, -31.0), display_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.97, 0.95, 0.89))
	if activation_flash_left > 0.0:
		var flash_radius := lerpf(15.0, 31.0, 1.0 - activation_flash_left / 0.28)
		draw_arc(Vector2.ZERO, flash_radius, 0.0, TAU, 32, plate_color.lightened(0.5), 3.0, true)
