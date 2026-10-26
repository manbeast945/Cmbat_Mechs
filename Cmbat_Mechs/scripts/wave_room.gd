extends CombatTestRoom
class_name CombatWaveRoom

@export_range(2, 5, 1) var minimum_enemies_per_wave := 6
@export_range(2, 5, 1) var maximum_enemies_per_wave := 15
@export_range(0.1, 10.0, 0.1) var next_wave_delay_seconds := 1.5

const SPAWN_BOUNDS := Rect2(Vector2(176.0, 176.0), Vector2(928.0, 352.0))
const PLAYER_CLEARANCE := 150.0
const ENEMY_CLEARANCE := 48.0
const MAX_POSITION_ATTEMPTS := 100

var enemy_scenes: Dictionary = {}
var actor_layer: Node2D
var player: CombatPlayer
var current_wave_enemies: Array[CombatEnemy] = []
var batch_started := false
var waiting_for_next_wave := false
var next_wave_time_left := 0.0

func configure(available_enemy_scenes: Dictionary, actors: Node2D, combat_player: CombatPlayer) -> void:
	enemy_scenes = available_enemy_scenes
	actor_layer = actors
	player = combat_player
	_spawn_wave()

func _process(delta: float) -> void:
	if not batch_started or player == null or not is_instance_valid(player) or player.is_defeated:
		return
	_prune_enemy_list()
	if not current_wave_enemies.is_empty():
		return
	if not waiting_for_next_wave:
		waiting_for_next_wave = true
		next_wave_time_left = maxf(0.0, next_wave_delay_seconds)
		return
	next_wave_time_left -= delta
	if next_wave_time_left <= 0.0:
		waiting_for_next_wave = false
		_spawn_wave()

func _spawn_wave() -> void:
	if enemy_scenes.is_empty() or actor_layer == null or player == null or not is_instance_valid(player):
		return
	var enemy_names: Array = enemy_scenes.keys()
	if enemy_names.is_empty():
		return
	var low_count := mini(minimum_enemies_per_wave, maximum_enemies_per_wave)
	var high_count := maxi(minimum_enemies_per_wave, maximum_enemies_per_wave)
	var group_size := randi_range(low_count, high_count)
	var placed_positions: Array[Vector2] = []
	current_wave_enemies.clear()
	for _index in range(group_size):
		var enemy_name := String(enemy_names[randi_range(0, enemy_names.size() - 1)])
		var enemy_scene: PackedScene = enemy_scenes[enemy_name]
		var enemy := enemy_scene.instantiate() as CombatEnemy
		if enemy == null:
			push_warning("Wave room could not instantiate enemy '%s'." % enemy_name)
			continue
		enemy.player = player
		if enemy is CombatSlime:
			(enemy as CombatSlime).skip_initial_spawn_spacing = true
		enemy.position = _choose_spawn_position(placed_positions)
		placed_positions.append(enemy.position)
		actor_layer.add_child(enemy)
		current_wave_enemies.append(enemy)
	batch_started = not current_wave_enemies.is_empty()
	waiting_for_next_wave = false

func _choose_spawn_position(placed_positions: Array[Vector2]) -> Vector2:
	var best_candidate := SPAWN_BOUNDS.get_center()
	var best_clearance := -1.0
	for _attempt in range(MAX_POSITION_ATTEMPTS):
		var candidate := Vector2(
			randf_range(SPAWN_BOUNDS.position.x, SPAWN_BOUNDS.end.x),
			randf_range(SPAWN_BOUNDS.position.y, SPAWN_BOUNDS.end.y)
		)
		var player_distance := candidate.distance_to(player.global_position)
		var nearest_enemy_distance := INF
		for placed_position: Vector2 in placed_positions:
			nearest_enemy_distance = minf(nearest_enemy_distance, candidate.distance_to(placed_position))
		var clearance := minf(player_distance, nearest_enemy_distance)
		if clearance > best_clearance:
			best_clearance = clearance
			best_candidate = candidate
		if player_distance >= PLAYER_CLEARANCE and nearest_enemy_distance >= ENEMY_CLEARANCE:
			return candidate
	return best_candidate

func _prune_enemy_list() -> void:
	for index in range(current_wave_enemies.size() - 1, -1, -1):
		var enemy := current_wave_enemies[index]
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			current_wave_enemies.remove_at(index)
