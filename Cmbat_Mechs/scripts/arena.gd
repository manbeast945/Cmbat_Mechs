extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const SLIME_SCENE: PackedScene = preload("res://scenes/slime.tscn")
const SKELETON_SCENE: PackedScene = preload("res://scenes/skeleton.tscn")
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/zombie.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/runner.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/brute.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/hud.tscn")
const DEV_CONSOLE_SCRIPT = preload("res://Cmbat_Mechs/scripts/dev_console.gd")

@onready var test_room: CombatTestRoom = $TestRoom

var actor_layer: Node2D

func _ready() -> void:
	actor_layer = test_room.actor_container()
	var player: CombatPlayer = PLAYER_SCENE.instantiate()
	player.position = Vector2(190.0, 360.0)
	actor_layer.add_child(player)

	var enemy_scenes := {
		"slime": SLIME_SCENE,
		"zombie": ZOMBIE_SCENE,
		"runner": RUNNER_SCENE,
		"brute": BRUTE_SCENE,
		"skeleton": SKELETON_SCENE,
	}

	var hud: CombatHUD = HUD_SCENE.instantiate()
	add_child(hud)
	hud.bind_player(player)

	var console = DEV_CONSOLE_SCRIPT.new()
	add_child(console)
	console.configure(enemy_scenes, actor_layer, player)
