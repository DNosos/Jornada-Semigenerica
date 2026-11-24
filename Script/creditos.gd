extends Control

const TITLE_FONT = preload("res://Font's/upheavtt.ttf")
const BODY_FONT = preload("res://Font's/dogica.ttf")
const MENU_SCENE: String = "res://Scene's/menu.tscn"
const SCROLL_SPEED: float = 38.0
const SCROLL_BOOST: float = 4.5
const COLOR_TITLE: Color = Color(0.93, 0.88, 0.71, 1.0)
const COLOR_TITLE_OUTLINE: Color = Color(0.59, 0.21, 0.29, 1.0)
const COLOR_HEADING: Color = Color(0.85, 0.53, 0.39, 1.0)
const COLOR_TEXT: Color = Color(0.93, 0.82, 0.65, 1.0)

const ENTRIES: Array = [
	{"kind": "title", "text": "Jornada\nSemigenérica"},
	{"kind": "text", "text": "Plataforma 2D em pixel art"},
	{"kind": "gap", "size": 46},
	{"kind": "heading", "text": "Desenvolvimento"},
	{"kind": "text", "text": "Arthur Augusto"},
	{"kind": "text", "text": "Emanuel \"DNosos\" Nepomuceno"},
	{"kind": "gap", "size": 34},
	{"kind": "heading", "text": "Referência conceitual"},
	{"kind": "text", "text": "Jornada Genérica"},
	{"kind": "gap", "size": 34},
	{"kind": "heading", "text": "Elenco"},
	{"kind": "text", "text": "O Herói"},
	{"kind": "text", "text": "A Mestra"},
	{"kind": "text", "text": "O Ferreiro"},
	{"kind": "text", "text": "O Mago Viajante"},
	{"kind": "text", "text": "A Princesa"},
	{"kind": "text", "text": "Os Servos do Rei Demônio"},
	{"kind": "text", "text": "O Zumbi"},
	{"kind": "text", "text": "O Polvo"},
	{"kind": "text", "text": "A Morte"},
	{"kind": "gap", "size": 34},
	{"kind": "heading", "text": "Tecnologia"},
	{"kind": "text", "text": "Godot Engine 4"},
	{"kind": "gap", "size": 34},
	{"kind": "heading", "text": "Fontes"},
	{"kind": "text", "text": "Dogica"},
	{"kind": "text", "text": "Kiwi Soda"},
	{"kind": "text", "text": "Upheavtt"},
	{"kind": "gap", "size": 34},
	{"kind": "heading", "text": "Arte"},
	{"kind": "text", "text": "Sprites, tilesets e fundos\nincluídos no repositório do projeto"},
	{"kind": "gap", "size": 64},
	{"kind": "title_small", "text": "Obrigado por jogar!"},
	{"kind": "gap", "size": 20}
]

@onready var roll: Control = $Roll
@onready var content: VBoxContainer = $Roll/Content
@onready var back_button: Button = $Footer/Back
@onready var hint_label: Label = $Footer/Hint

var _started: bool = false
var _finished: bool = false
var _leaving: bool = false

func _ready() -> void:
	_style_footer()
	_build_content()
	back_button.pressed.connect(_go_back)
	back_button.focus_entered.connect(_on_back_focus_entered)
	back_button.focus_exited.connect(_on_back_focus_exited)
	back_button.mouse_entered.connect(back_button.grab_focus)
	back_button.grab_focus()
	roll.resized.connect(_fit_content)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.45)
	await get_tree().process_frame
	_fit_content()
	await get_tree().process_frame
	content.position.y = roll.size.y
	_started = true

func _build_content() -> void:
	for entry in ENTRIES:
		var data: Dictionary = entry
		var kind: String = data["kind"]
		if kind == "gap":
			var gap: Control = Control.new()
			gap.custom_minimum_size = Vector2(0.0, float(data["size"]))
			gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(gap)
			continue
		var label: Label = Label.new()
		label.text = data["text"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		match kind:
			"title":
				label.add_theme_font_override("font", TITLE_FONT)
				label.add_theme_font_size_override("font_size", 56)
				label.add_theme_color_override("font_color", COLOR_TITLE)
				label.add_theme_color_override("font_outline_color", COLOR_TITLE_OUTLINE)
				label.add_theme_constant_override("outline_size", 6)
			"title_small":
				label.add_theme_font_override("font", TITLE_FONT)
				label.add_theme_font_size_override("font_size", 38)
				label.add_theme_color_override("font_color", COLOR_TITLE)
				label.add_theme_color_override("font_outline_color", COLOR_TITLE_OUTLINE)
				label.add_theme_constant_override("outline_size", 5)
			"heading":
				label.add_theme_font_override("font", BODY_FONT)
				label.add_theme_font_size_override("font_size", 16)
				label.add_theme_color_override("font_color", COLOR_HEADING)
				label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.1, 1.0))
				label.add_theme_constant_override("outline_size", 5)
			_:
				label.add_theme_font_override("font", BODY_FONT)
				label.add_theme_font_size_override("font_size", 13)
				label.add_theme_color_override("font_color", COLOR_TEXT)
				label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.1, 1.0))
				label.add_theme_constant_override("outline_size", 4)
		content.add_child(label)

func _style_footer() -> void:
	back_button.add_theme_font_override("font", BODY_FONT)
	back_button.add_theme_color_override("font_color", COLOR_HEADING)
	back_button.add_theme_color_override("font_hover_color", Color(0.93, 0.82, 0.65, 1.0))
	back_button.add_theme_color_override("font_focus_color", Color(0.93, 0.82, 0.65, 1.0))
	back_button.add_theme_color_override("font_pressed_color", Color(0.89, 0.75, 0.56, 1.0))
	back_button.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.1, 1.0))
	back_button.add_theme_constant_override("outline_size", 5)
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "focus"]:
		back_button.add_theme_stylebox_override(style_name, empty)
	hint_label.add_theme_font_override("font", BODY_FONT)
	hint_label.add_theme_font_size_override("font_size", 9)
	hint_label.add_theme_color_override("font_color", Color(0.72, 0.66, 0.63, 1.0))

func _fit_content() -> void:
	content.size.x = roll.size.x
	content.custom_minimum_size.x = roll.size.x

func _on_back_focus_entered() -> void:
	if not back_button.text.begins_with("> "):
		back_button.text = "> " + back_button.text

func _on_back_focus_exited() -> void:
	back_button.text = back_button.text.trim_prefix("> ")

func _process(delta: float) -> void:
	if not _started or _finished or _leaving:
		return
	var boosted: bool = Input.is_action_pressed("Space") or Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_down") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var speed: float = SCROLL_SPEED * (SCROLL_BOOST if boosted else 1.0)
	content.position.y -= speed * delta
	if content.position.y + content.size.y <= roll.size.y * 0.58:
		content.position.y = roll.size.y * 0.58 - content.size.y
		_finished = true
		hint_label.text = "ESC volta"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()

func _go_back() -> void:
	if _leaving:
		return
	_leaving = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(get_tree().change_scene_to_file.bind(MENU_SCENE))
