extends Control

@onready var b_play = $VBoxContainer/Play
@onready var b_opt = $VBoxContainer/Options
@onready var b_exit = $VBoxContainer/Exit

var original_text = {}

func _ready() -> void:
	config_sinal(b_play)
	config_sinal(b_opt)
	config_sinal(b_exit)
	
	original_text[b_play] = b_play.text
	original_text[b_opt] = b_opt.text
	original_text[b_exit] = b_exit.text

func config_sinal(bot: Button):
	bot.focus_entered.connect(func(): add_set(bot))
	bot.mouse_entered.connect(func(): bot.grab_focus())
	bot.focus_exited.connect(func(): del_set(bot))

func add_set(bot: Button):
	bot.text = "> " + original_text[bot]

func del_set(bot: Button):
	bot.text = original_text[bot]

# Funcionamento dos Botões:
func exit():
	get_tree().quit()

func play():
	get_tree().change_scene_to_file("res://Scene's/player.tscn")
