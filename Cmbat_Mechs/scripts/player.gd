extends CharacterBody2D
class_name CombatPlayer

signal health_changed(current: int, maximum: int)
signal weapon_changed(weapon_name: String)
signal defeated
signal hit_confirmed(impact_position: Vector2, heavy: bool)

@export var move_speed := 245.0
@export var max_health := 100
@export var dash_speed := 650.0
@export var dash_duration := 0.16
@export var dash_cooldown := 2.0

var health := 100
var is_defeated := false
var active_weapon_index := 0
var active_weapon: CombatWeapon
var registered_weapons: Array[CombatWeapon] = []
var was_attack_down := false
var dev_console_open := false
var dash_time_left := 0.0
var dash_cooldown_left := 0.0
var dash_direction := Vector2.ZERO

@onready var melee_weapon: CombatWeapon = $MeleeWeapon
@onready var gun_weapon: CombatWeapon = $GunWeapon

func _ready() -> void:
	add_to_group("player")
	health = max_health
	_register_child_weapons()
	_sync_weapons()
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if dev_console_open:
		velocity = Vector2.ZERO
		was_attack_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		return

	if is_defeated:
		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	var movement := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	).normalized()
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	if dash_time_left > 0.0:
		dash_time_left = maxf(0.0, dash_time_left - delta)
		velocity = dash_direction * dash_speed
	elif Input.is_key_pressed(KEY_SPACE) and movement != Vector2.ZERO and dash_cooldown_left <= 0.0:
		dash_direction = movement
		dash_time_left = maxf(0.0, dash_duration - delta)
		dash_cooldown_left = maxf(0.0, dash_cooldown)
		velocity = dash_direction * dash_speed
	else:
		velocity = movement * move_speed
	move_and_slide()

	if Input.is_key_pressed(KEY_1):
		equip_weapon_by_name("melee")
	elif Input.is_key_pressed(KEY_2):
		equip_weapon_by_name("gun")
	elif Input.is_key_pressed(KEY_3):
		equip_weapon_by_name("shotgun")
	elif Input.is_key_pressed(KEY_4):
		equip_weapon_by_name("rpg")

	var attack_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if attack_down and not was_attack_down:
		if active_weapon != null:
			active_weapon.use(self, get_global_mouse_position())
	was_attack_down = attack_down

func equip(index: int) -> void:
	if registered_weapons.is_empty():
		return
	equip_weapon(registered_weapons[clampi(index, 0, registered_weapons.size() - 1)])

func equip_weapon_by_name(weapon_name: String) -> bool:
	var requested_name := _normalize_weapon_name(weapon_name)
	for weapon: CombatWeapon in registered_weapons:
		if _normalize_weapon_name(weapon.display_name()) == requested_name or _normalize_weapon_name(weapon.name) == requested_name:
			equip_weapon(weapon)
			return true
	return false

func available_weapon_names() -> PackedStringArray:
	var names := PackedStringArray()
	for weapon: CombatWeapon in registered_weapons:
		names.append(weapon.display_name())
	return names

func equip_weapon(weapon: CombatWeapon) -> void:
	if weapon == null or not registered_weapons.has(weapon):
		return
	if active_weapon == weapon:
		return
	active_weapon = weapon
	active_weapon_index = registered_weapons.find(weapon)
	_sync_weapons()

func _register_child_weapons() -> void:
	registered_weapons.clear()
	for child: Node in get_children():
		if child is CombatWeapon:
			registered_weapons.append(child as CombatWeapon)
	active_weapon = registered_weapons[0] if not registered_weapons.is_empty() else null
	active_weapon_index = 0

func _normalize_weapon_name(weapon_name: String) -> String:
	var normalized := weapon_name.strip_edges().to_lower().replace(" ", "_")
	if normalized.ends_with("_weapon"):
		normalized = normalized.trim_suffix("_weapon")
	elif normalized.ends_with("weapon"):
		normalized = normalized.trim_suffix("weapon")
	return normalized

func _sync_weapons() -> void:
	if not is_node_ready():
		return
	for weapon: CombatWeapon in registered_weapons:
		weapon.visible = weapon == active_weapon
	if active_weapon != null:
		weapon_changed.emit(active_weapon.display_name())

func take_damage(amount: int) -> void:
	if is_defeated:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		is_defeated = true
		defeated.emit()

func notify_combat_hit(impact_position: Vector2, heavy: bool) -> void:
	hit_confirmed.emit(impact_position, heavy)
	var impact_audio := AudioStreamPlayer2D.new()
	impact_audio.stream = CombatSounds.make_impact()
	impact_audio.volume_db = -4.0
	get_parent().add_child(impact_audio)
	impact_audio.global_position = impact_position
	impact_audio.finished.connect(impact_audio.queue_free)
	impact_audio.play()
	var effect := CombatHitEffect.new()
	effect.heavy = heavy
	get_parent().add_child(effect)
	effect.global_position = impact_position
