extends CanvasLayer
class_name CombatDevConsole

var enemy_scenes: Dictionary = {}
var actor_container: Node2D
var player: CombatPlayer

var console_panel: PanelContainer
var command_input: LineEdit
var output_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	set_process_input(true)

func configure(available_enemy_scenes: Dictionary, actors: Node2D, combat_player: CombatPlayer) -> void:
	enemy_scenes = available_enemy_scenes
	actor_container = actors
	player = combat_player

func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	if key_event.keycode == KEY_QUOTELEFT:
		_set_open(not console_panel.visible)
		get_viewport().set_input_as_handled()
	elif not console_panel.visible and (key_event.unicode == 47 or key_event.keycode == KEY_SLASH):
		_set_open(true)
		command_input.text = "/"
		command_input.caret_column = command_input.text.length()
		get_viewport().set_input_as_handled()
	elif console_panel.visible and key_event.keycode == KEY_ESCAPE:
		_set_open(false)
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	console_panel = PanelContainer.new()
	console_panel.position = Vector2(18.0, 104.0)
	console_panel.custom_minimum_size = Vector2(440.0, 0.0)
	console_panel.visible = false
	root.add_child(console_panel)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 5)
	console_panel.add_child(contents)

	var instructions := Label.new()
	instructions.text = "DEV CONSOLE  |  / or ` opens, Esc closes, Tab completes\nspawn <slime|zombie|runner|brute|skeleton|jumper> [count]\nweapon <name>"
	instructions.add_theme_font_size_override("font_size", 14)
	contents.add_child(instructions)

	command_input = LineEdit.new()
	command_input.placeholder_text = "Enter command and press Enter"
	command_input.text_submitted.connect(_on_command_submitted)
	command_input.gui_input.connect(_on_command_input_gui_input)
	contents.add_child(command_input)

	output_label = Label.new()
	output_label.text = "Ready."
	output_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contents.add_child(output_label)

func _set_open(is_open: bool) -> void:
	console_panel.visible = is_open
	get_tree().paused = is_open
	if player != null and is_instance_valid(player):
		player.dev_console_open = is_open
	if is_open:
		command_input.clear()
		command_input.grab_focus()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		command_input.release_focus()

func _on_command_submitted(raw_command: String) -> void:
	var command_text := raw_command.strip_edges()
	command_input.clear()
	if command_text.begins_with("/"):
		command_text = command_text.substr(1).strip_edges()
	if command_text.is_empty():
		return

	var command_parts := command_text.split(" ", false, 1)
	var command_name := String(command_parts[0]).to_lower()
	var arguments := String(command_parts[1]).strip_edges() if command_parts.size() > 1 else ""
	match command_name:
		"spawn":
			_execute_spawn(arguments)
		"weapon":
			_execute_weapon(arguments)
		_:
			_set_output("Unknown command. Use: spawn or weapon.")

func _execute_spawn(arguments: String) -> void:
	var parts := arguments.split(" ", false)
	if parts.is_empty() or parts.size() > 2:
		_set_output("Usage: spawn <enemy> [count]")
		return

	var enemy_name := String(parts[0]).to_lower()
	var available_names := PackedStringArray()
	for key in enemy_scenes.keys():
		available_names.append(String(key))
	if not enemy_scenes.has(enemy_name):
		_set_output("Unknown enemy '%s'. Available: %s" % [enemy_name, ", ".join(available_names)])
		return

	var count := 1
	if parts.size() == 2:
		var count_text := String(parts[1])
		if not count_text.is_valid_int():
			_set_output("Count must be a positive whole number.")
			return
		count = count_text.to_int()
		if count < 1:
			_set_output("Count must be a positive whole number.")
			return

	if actor_container == null or player == null or not is_instance_valid(player):
		_set_output("Cannot spawn: the test arena is not ready.")
		return

	var world_position := get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	var enemy_scene: PackedScene = enemy_scenes[enemy_name]
	for index in range(count):
		var enemy := enemy_scene.instantiate() as CombatEnemy
		if enemy == null:
			_set_output("Could not create enemy '%s'." % enemy_name)
			return
		enemy.player = player
		if enemy is CombatSlime:
			(enemy as CombatSlime).skip_initial_spawn_spacing = true
		actor_container.add_child(enemy)
		# Bodies spawned at precisely one point can violently depenetrate each
		# other on their first move. Keep each group close to the cursor in a
		# compact spiral, with the first enemy exactly at the cursor.
		var spawn_offset := Vector2.ZERO
		if index > 0:
			var spiral_angle := float(index) * 2.39996323
			var spiral_radius := 22.0 * sqrt(float(index))
			spawn_offset = Vector2.RIGHT.rotated(spiral_angle) * spiral_radius
		enemy.global_position = world_position + spawn_offset
	_set_output("Spawned %d %s at the cursor." % [count, enemy_name])

func _on_command_input_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_TAB:
		_autocomplete_command()
		command_input.accept_event()

func _autocomplete_command() -> void:
	var original_text := command_input.text
	var has_slash_prefix := original_text.begins_with("/")
	var text := original_text.substr(1) if has_slash_prefix else original_text
	var prefix := "/" if has_slash_prefix else ""
	var space_index := text.rfind(" ")
	var completion := ""

	if text.is_empty():
		completion = "spawn "
	elif space_index < 0:
		var command_word := text.to_lower()
		if command_word == "spawn" or command_word == "weapon":
			completion = command_word + " "
		else:
			var matching_commands := _matching_values(PackedStringArray(["spawn", "weapon"]), command_word)
			if not matching_commands.is_empty():
				completion = matching_commands[0] + " "
	else:
		var command_name := text.substr(0, space_index).to_lower()
		var argument_prefix := text.substr(space_index + 1).to_lower()
		var candidates := PackedStringArray()
		if command_name == "spawn":
			for enemy_name: String in enemy_scenes.keys():
				candidates.append(enemy_name)
		elif command_name == "weapon" and player != null and is_instance_valid(player):
			for weapon_name in player.available_weapon_names():
				candidates.append(weapon_name.to_lower())
		var matches := _matching_values(candidates, argument_prefix)
		if not matches.is_empty():
			completion = text.substr(0, space_index + 1) + matches[0] + " "

	if completion.is_empty():
		return
	var completed_text := prefix + completion
	command_input.text = completed_text
	command_input.caret_column = completed_text.length()

func _matching_values(values: PackedStringArray, prefix: String) -> PackedStringArray:
	var matches := PackedStringArray()
	for value: String in values:
		if value.begins_with(prefix):
			matches.append(value)
	return matches

func _execute_weapon(weapon_name: String) -> void:
	if weapon_name.is_empty():
		_set_output("Usage: weapon <name>")
		return
	if player == null or not is_instance_valid(player):
		_set_output("Cannot equip: the player is unavailable.")
		return
	if player.equip_weapon_by_name(weapon_name):
		_set_output("Equipped %s." % player.active_weapon.display_name())
	else:
		_set_output("Unknown weapon '%s'. Available: %s" % [weapon_name, ", ".join(player.available_weapon_names())])

func _set_output(message: String) -> void:
	output_label.text = message
