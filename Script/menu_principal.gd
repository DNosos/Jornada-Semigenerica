extends Control

func add_set(bot: Button) -> void:
	if not bot.text.begins_with("> "):
		bot.text = "> " + bot.text

func del_set(bot: Button) -> void:
	bot.text = bot.text.trim_prefix("> ")

func exit() -> void:
	get_tree().quit()

func play() -> void:
	GameState.start_new_game()
	get_tree().change_scene_to_file("res://Scene's/tutorial.tscn")

func options() -> void:
	_show_info("Controles", "A / D  —  Andar\nW ou Espaço  —  Pular\nS  —  Descer\nBotão esquerdo do mouse  —  Atacar\nF  —  Conversar / interagir\nEsc  —  Fechar esta janela")

func credits() -> void:
	get_tree().change_scene_to_file("res://Scene's/creditos.tscn")

func _show_info(title: String, message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.ok_button_text = "Entendi"
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(460, 260))
