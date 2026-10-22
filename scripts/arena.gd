extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const SLIME_SCENE: PackedScene = preload("res://scenes/slime.tscn")
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/zombie.tscn")
const SKELETON_SCENE: PackedScene = preload("res://scenes/skeleton.tscn")
const DISPENSER_SCENE: PackedScene = preload("res://scenes/pressure_plate.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/hud.tscn")

@onready var test_room: CombatTestRoom = $TestRoom

var actor_layer: Node2D

func _ready() -> void:
	actor_layer = test_room.actor_container()
	var player: CombatPlayer = PLAYER_SCENE.instantiate()
	player.position = Vector2(190.0, 360.0)
	actor_layer.add_child(player)

	_add_dispenser("SLIME", Color(0.30, 0.78, 0.35), SLIME_SCENE, Vector2(330.0, 220.0), Vector2(0.0, 68.0), player)
	_add_dispenser("ZOMBIE", Color(0.78, 0.28, 0.27), ZOMBIE_SCENE, Vector2(640.0, 220.0), Vector2(0.0, 68.0), player)
	_add_dispenser("SKELETON", Color(0.82, 0.84, 0.80), SKELETON_SCENE, Vector2(950.0, 220.0), Vector2(0.0, 68.0), player)

	var hud: CombatHUD = HUD_SCENE.instantiate()
	add_child(hud)
	hud.bind_player(player)

func _add_dispenser(label: String, indicator_color: Color, enemy_scene: PackedScene, spawn_position: Vector2, spawn_offset: Vector2, player: CombatPlayer) -> void:
	var dispenser: CombatEnemyDispenser = DISPENSER_SCENE.instantiate()
	dispenser.display_label = label
	dispenser.indicator_color = indicator_color
	dispenser.enemy_scene = enemy_scene
	dispenser.spawn_offset = spawn_offset
	dispenser.player = player
	dispenser.position = spawn_position
	actor_layer.add_child(dispenser)
