extends CanvasLayer

signal dialogue_finished(actor: Node)

var _panel: PanelContainer
var _name_label: Label
var _text_label: Label
var _hint_label: Label
var _lines: PackedStringArray = PackedStringArray()
var _line_index: int = 0
var _actor: Node
var is_open: bool = false

func _ready() -> void:
	layer = 20
	_build_interface()
	visible = false


func _build_interface() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.04
	_panel.anchor_right = 0.96
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_top = -166
	_panel.offset_bottom = -22
	_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 20)
	_name_label.add_theme_color_override("font_color", Color("#f6ce78"))
	column.add_child(_name_label)

	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 16)
	_text_label.add_theme_color_override("font_color", Color("#f4eee2"))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(0, 62)
	column.add_child(_text_label)

	_hint_label = Label.new()
	_hint_label.text = "F / ENTER  —  continuar"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.add_theme_font_size_override("font_size", 12)
	_hint_label.add_theme_color_override("font_color", Color("#b6aaa0"))
	column.add_child(_hint_label)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#241d2b")
	style.border_color = Color("#d7a85d")
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 10
	return style

func start_dialogue(speaker: String, lines: PackedStringArray, actor: Node = null) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_line_index = 0
	_actor = actor
	_name_label.text = speaker
	_text_label.text = _lines[0]
	is_open = true
	visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("F") or event.is_action_pressed("ui_accept"):
		if event is InputEventKey and event.echo:
			return
		advance()
		get_viewport().set_input_as_handled()

func advance() -> void:
	if not is_open:
		return
	_line_index += 1
	if _line_index >= _lines.size():
		var finished_actor := _actor
		close_dialogue()
		dialogue_finished.emit(finished_actor)
		return
	_text_label.text = _lines[_line_index]

func close_dialogue() -> void:
	is_open = false
	visible = false
	_lines.clear()
	_actor = null
