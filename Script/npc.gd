extends StaticBody2D

const VISUAL_SCRIPT = preload("res://Script/character_visual.gd")

var npc_id: String = ""
var display_name: String = "Morador"
var dialogue_lines: PackedStringArray = PackedStringArray()
var visual
var _player: Node2D

func configure(id: String, title: String, lines: PackedStringArray) -> void:
	npc_id = id
	display_name = title
	dialogue_lines = lines

func setup_visual(texture: Texture2D, style: String = "bob", fps: float = 1.6) -> void:
	visual = VISUAL_SCRIPT.new()
	add_child(visual)
	visual.setup(texture, style, 1.0, fps)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(maxf(float(visual.body_width) * 0.6, 20.0), maxf(float(visual.feet_height) * 0.9, 24.0))
	collision.shape = shape
	collision.position = Vector2(0.0, -shape.size.y * 0.5)
	add_child(collision)

func _process(_delta: float) -> void:
	if visual == null:
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return
	var distance_x: float = _player.global_position.x - global_position.x
	if absf(distance_x) < 190.0:
		visual.face(signf(distance_x))

func get_dialogue() -> PackedStringArray:
	return dialogue_lines
