extends Node

signal changed

const LAST_LEVEL := 2

var max_health: int = 5
var health: int = 5
var coins: int = 0
var weapon_level: int = 0
var current_level: int = 0
var checkpoint_level: int = -1
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_active: bool = false

func start_new_game() -> void:
	max_health = 5
	health = max_health
	coins = 0
	weapon_level = 0
	current_level = 0
	checkpoint_level = -1
	checkpoint_position = Vector2.ZERO
	checkpoint_active = false
	changed.emit()

func set_level(level: int) -> void:
	current_level = clampi(level, 0, LAST_LEVEL)
	health = max_health
	checkpoint_level = -1
	checkpoint_position = Vector2.ZERO
	checkpoint_active = false
	changed.emit()

func advance_level() -> void:
	if current_level < LAST_LEVEL:
		set_level(current_level + 1)

func add_coins(amount: int) -> void:
	coins += maxi(amount, 0)
	changed.emit()

func heal(amount: int) -> void:
	health = mini(max_health, health + maxi(amount, 0))
	changed.emit()

func damage(amount: int) -> void:
	health = maxi(0, health - maxi(amount, 0))
	changed.emit()

func restore_health() -> void:
	health = max_health
	changed.emit()

func get_attack_damage() -> int:
	return 1 + weapon_level

func get_upgrade_cost() -> int:
	return 5 + weapon_level * 5

func buy_weapon_upgrade() -> bool:
	var cost := get_upgrade_cost()
	if coins < cost:
		return false
	coins -= cost
	weapon_level += 1
	changed.emit()
	return true

func activate_checkpoint(level: int, position: Vector2) -> void:
	if level != current_level:
		return
	checkpoint_level = level
	checkpoint_position = position
	checkpoint_active = true
	changed.emit()

func get_spawn_position(default_position: Vector2) -> Vector2:
	if checkpoint_active and checkpoint_level == current_level:
		return checkpoint_position
	return default_position
