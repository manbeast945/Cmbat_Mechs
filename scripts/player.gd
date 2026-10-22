extends CharacterBody2D
class_name CombatPlayer

signal health_changed(current: int, maximum: int)
signal weapon_changed(weapon_name: String)
signal defeated

@export var move_speed := 245.0
@export var max_health := 100

var health := 100
var is_defeated := false
var active_weapon_index := 0
var was_attack_down := false

@onready var melee_weapon: CombatWeapon = $MeleeWeapon
@onready var gun_weapon: CombatWeapon = $GunWeapon

func _ready() -> void:
	add_to_group("player")
	health = max_health
	_sync_weapons()
	health_changed.emit(health, max_health)

func _physics_process(_delta: float) -> void:
	if is_defeated:
		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	var movement := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	).normalized()
	velocity = movement * move_speed
	move_and_slide()

	if Input.is_key_pressed(KEY_1):
		equip(0)
	elif Input.is_key_pressed(KEY_2):
		equip(1)

	var attack_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if attack_down and not was_attack_down:
		var weapon: CombatWeapon = melee_weapon if active_weapon_index == 0 else gun_weapon
		weapon.use(self, get_global_mouse_position())
	was_attack_down = attack_down

func equip(index: int) -> void:
	var next_index := clampi(index, 0, 1)
	if next_index == active_weapon_index:
		return
	active_weapon_index = next_index
	_sync_weapons()

func _sync_weapons() -> void:
	if not is_node_ready():
		return
	melee_weapon.visible = active_weapon_index == 0
	gun_weapon.visible = active_weapon_index == 1
	weapon_changed.emit("MELEE" if active_weapon_index == 0 else "GUN")

func take_damage(amount: int) -> void:
	if is_defeated:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		is_defeated = true
		defeated.emit()

