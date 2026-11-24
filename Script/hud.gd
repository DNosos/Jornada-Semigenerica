extends CanvasLayer

var _status_label: Label
var _level_label: Label
var _boss_panel: PanelContainer
var _boss_label: Label
var _boss_bar: ProgressBar
var _notice: Label
var _ending_panel: PanelContainer

func _ready() -> void:
	_build_hud()
	refresh()

func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	panel.add_theme_stylebox_override("panel", _small_panel_style())
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)

	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 14)
	_level_label.add_theme_color_override("font_color", Color("#f6ce78"))
	column.add_child(_level_label)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color("#ffffff"))
	column.add_child(_status_label)

	_notice = Label.new()
	_notice.anchor_left = 0.5
	_notice.anchor_right = 0.5
	_notice.anchor_top = 0.0
	_notice.anchor_bottom = 0.0
	_notice.offset_left = -220
	_notice.offset_right = 220
	_notice.offset_top = 34
	_notice.offset_bottom = 64
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.add_theme_font_size_override("font_size", 16)
	_notice.add_theme_color_override("font_color", Color("#ffe7a5"))
	add_child(_notice)

	_boss_panel = PanelContainer.new()
	_boss_panel.anchor_left = 0.5
	_boss_panel.anchor_right = 0.5
	_boss_panel.anchor_top = 0.0
	_boss_panel.anchor_bottom = 0.0
	_boss_panel.offset_left = -170
	_boss_panel.offset_right = 170
	_boss_panel.offset_top = 18
	_boss_panel.offset_bottom = 76
	_boss_panel.add_theme_stylebox_override("panel", _small_panel_style())
	add_child(_boss_panel)
	var boss_column := VBoxContainer.new()
	boss_column.add_theme_constant_override("separation", 4)
	_boss_panel.add_child(boss_column)
	_boss_label = Label.new()
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_label.text = "REI DEMÔNIO"
	boss_column.add_child(_boss_label)
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(300, 16)
	_boss_bar.show_percentage = false
	boss_column.add_child(_boss_bar)
	_boss_panel.visible = false

func _small_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.13, 0.88)
	style.border_color = Color("#b98a50")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func refresh() -> void:
	if not is_instance_valid(_status_label):
		return
	var hearts := "♥".repeat(GameState.health) + "♡".repeat(GameState.max_health - GameState.health)
	_status_label.text = "Vida: %s   Moedas: %d   Espada: +%d" % [hearts, GameState.coins, GameState.weapon_level]

func set_level_name(title: String) -> void:
	_level_label.text = title

func set_boss_health(current: int, maximum: int) -> void:
	_boss_panel.visible = true
	_boss_bar.max_value = maximum
	_boss_bar.value = current
	_boss_label.text = "REI DEMÔNIO  %d / %d" % [current, maximum]

func hide_boss_health() -> void:
	_boss_panel.visible = false

func notify(message: String) -> void:
	_notice.text = message
	_notice.visible = true
	_notice.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.3)
	tween.tween_property(_notice, "modulate:a", 0.0, 0.5)

func show_victory() -> void:
	if is_instance_valid(_ending_panel):
		return
	_ending_panel = PanelContainer.new()
	_ending_panel.anchor_left = 0.5
	_ending_panel.anchor_right = 0.5
	_ending_panel.anchor_top = 0.5
	_ending_panel.anchor_bottom = 0.5
	_ending_panel.offset_left = -235
	_ending_panel.offset_right = 235
	_ending_panel.offset_top = -120
	_ending_panel.offset_bottom = 120
	_ending_panel.add_theme_stylebox_override("panel", _small_panel_style())
	add_child(_ending_panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	_ending_panel.add_child(column)
	var title := Label.new()
	title.text = "FIM DE JOGO!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#f6ce78"))
	column.add_child(title)
	var message := Label.new()
	message.text = "A princesa foi salva e o reino está livre!\nA jornada do herói chegou ao fim."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)
	var button := Button.new()
	button.text = "Voltar ao menu"
	button.pressed.connect(_return_to_menu)
	column.add_child(button)

func _return_to_menu() -> void:
	GameState.start_new_game()
	get_tree().change_scene_to_file("res://Scene's/menu.tscn")
