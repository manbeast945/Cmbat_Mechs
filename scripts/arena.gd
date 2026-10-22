extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/hud.tscn")

@onready var test_room: CombatTestRoom = $TestRoom

var actor_layer: Node2D

func _ready() -> void:
	actor_layer = test_room.actor_container()
	var player: CombatPlayer = PLAYER_SCENE.instantiate()
	player.position = Vector2(190.0, 360.0)
	actor_layer.add_child(player)

	for spawn in [Vector2(710.0, 205.0), Vector2(970.0, 355.0), Vector2(735.0, 510.0)]:
		var enemy: CombatEnemy = ENEMY_SCENE.instantiate()
		enemy.position = spawn
		enemy.player = player
		actor_layer.add_child(enemy)

	var hud: CombatHUD = HUD_SCENE.instantiate()
	add_child(hud)
	hud.bind_player(player)
