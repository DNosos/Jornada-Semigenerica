extends StaticBody2D

var npc_id: String = ""
var display_name: String = "Morador"
var dialogue_lines: PackedStringArray = PackedStringArray()

func configure(id: String, title: String, lines: PackedStringArray) -> void:
	npc_id = id
	display_name = title
	dialogue_lines = lines

func get_dialogue() -> PackedStringArray:
	return dialogue_lines
