extends Area2D

signal activated

var level_index: int = 0
var spawn_position: Vector2 = Vector2.ZERO
var already_activated: bool = false

func configure(p_level: int, p_spawn: Vector2) -> void:
	level_index = p_level
	spawn_position = p_spawn

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if already_activated or not body.is_in_group("player"):
		return
	already_activated = true
	GameState.activate_checkpoint(level_index, spawn_position)
	activated.emit()
