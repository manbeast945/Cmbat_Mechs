extends CanvasLayer
class_name CombatHUD

var health_bar: ProgressBar
var status_label: Label
var hint_label: Label
var defeat_overlay: ColorRect
var aim_feedback: CombatAimFeedback
var equipped_weapon_name := "MELEE"

func _ready() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(18.0, 16.0)
	panel.add_theme_constant_override("separation", 6)
	add_child(panel)
	aim_feedback = CombatAimFeedback.new()
	aim_feedback.name = "AimFeedback"
	add_child(aim_feedback)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(260.0, 22.0)
	health_bar.show_percentage = false
	panel.add_child(health_bar)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(status_label)

	hint_label = Label.new()
	hint_label.text = "WASD move   Mouse aim   LMB attack\n1 melee   2 gun   3 shotgun   4 RPG   ` dev console"
	hint_label.modulate = Color(0.78, 0.8, 0.81)
	hint_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(hint_label)

	defeat_overlay = ColorRect.new()
	defeat_overlay.color = Color(0.02, 0.025, 0.035, 0.78)
	defeat_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	defeat_overlay.visible = false
	defeat_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(defeat_overlay)
	var message := Label.new()
	message.text = "YOU ARE DOWN\nPress R to restart"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message.add_theme_font_size_override("font_size", 32)
	defeat_overlay.add_child(message)

func bind_player(player: CombatPlayer) -> void:
	aim_feedback.bind_player(player)
	player.health_changed.connect(_on_health_changed)
	player.weapon_changed.connect(_on_weapon_changed)
	player.defeated.connect(_on_defeated)
	_on_health_changed(player.health, player.max_health)
	_on_weapon_changed("MELEE")

func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	status_label.text = "HEALTH  %d / %d     EQUIPPED  %s" % [current, maximum, equipped_weapon_name]

func _on_weapon_changed(weapon_name: String) -> void:
	equipped_weapon_name = weapon_name
	_on_health_changed(int(health_bar.value), int(health_bar.max_value))

func _on_defeated() -> void:
	defeat_overlay.visible = true
