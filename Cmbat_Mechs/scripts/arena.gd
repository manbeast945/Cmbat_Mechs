extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const SLIME_SCENE: PackedScene = preload("res://scenes/slime.tscn")
const SKELETON_SCENE: PackedScene = preload("res://scenes/skeleton.tscn")
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/zombie.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/runner.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/brute.tscn")
const JUMPER_SCENE: PackedScene = preload("res://scenes/jumper.tscn")
const STICKER_SCENE: PackedScene = preload("res://scenes/sticker.tscn")
const TEST_ROOM_SCENE: PackedScene = preload("res://scenes/test_room.tscn")
const WAVE_ROOM_SCENE: PackedScene = preload("res://scenes/wave_room.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/hud.tscn")
const DEV_CONSOLE_SCRIPT = preload("res://Cmbat_Mechs/scripts/dev_console.gd")

@export_range(0.1, 4.0, 0.1) var prototype_time_scale := 2.0

var actor_layer: Node2D
var room_container: Node2D
var front_wall: Node2D
var current_room: CombatTestRoom
var player: CombatPlayer
var enemy_scenes: Dictionary = {}
var console: CombatDevConsole
var transition_pending := false
var previous_time_scale := 1.0

func _ready() -> void:
	previous_time_scale = Engine.time_scale
	Engine.time_scale = prototype_time_scale
	room_container = $RoomContainer
	actor_layer = $Actors
	front_wall = $Actors/FrontWall
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(190.0, 360.0)
	actor_layer.add_child(player)

	enemy_scenes = {
		"slime": SLIME_SCENE,
		"zombie": ZOMBIE_SCENE,
		"runner": RUNNER_SCENE,
		"brute": BRUTE_SCENE,
		"skeleton": SKELETON_SCENE,
		"jumper": JUMPER_SCENE,
		"sticker": STICKER_SCENE,
	}

	var hud: CombatHUD = HUD_SCENE.instantiate()
	add_child(hud)
	hud.bind_player(player)

	console = DEV_CONSOLE_SCRIPT.new()
	add_child(console)
	console.configure(enemy_scenes, actor_layer, player)
	_activate_room(TEST_ROOM_SCENE, Vector2(190.0, 360.0))

func _activate_room(room_scene: PackedScene, player_position: Vector2) -> void:
	var room := room_scene.instantiate() as CombatTestRoom
	if room == null:
		push_error("Could not instantiate combat room scene.")
		return
	current_room = room
	room_container.add_child(current_room)
	current_room.doorway_entered.connect(_on_doorway_entered)
	player.position = player_position
	if current_room is CombatWaveRoom:
		(current_room as CombatWaveRoom).configure(enemy_scenes, actor_layer, player)
	console.configure(enemy_scenes, actor_layer, player)

func _on_doorway_entered(door_side: int) -> void:
	if transition_pending:
		return
	transition_pending = true
	var entering_wave_room := door_side == CombatTestRoom.DoorSide.RIGHT
	call_deferred("_swap_room", entering_wave_room)

func _swap_room(entering_wave_room: bool) -> void:
	if current_room == null or not is_instance_valid(current_room):
		transition_pending = false
		return
	_clear_room_actors()
	room_container.remove_child(current_room)
	current_room.queue_free()
	var destination_scene := WAVE_ROOM_SCENE if entering_wave_room else TEST_ROOM_SCENE
	var destination_position := Vector2(180.0, 360.0) if entering_wave_room else Vector2(1100.0, 360.0)
	_activate_room(destination_scene, destination_position)
	transition_pending = false

func _clear_room_actors() -> void:
	for actor: Node in actor_layer.get_children():
		if actor == player or actor == front_wall:
			continue
		actor_layer.remove_child(actor)
		actor.queue_free()

func _exit_tree() -> void:
	Engine.time_scale = previous_time_scale
