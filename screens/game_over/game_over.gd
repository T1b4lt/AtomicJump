class_name GameOver
extends CanvasLayer

# Scenes
const MAIN_MENU_SCENE = "res://screens/main_menu/main_menu.tscn"

# Childs
@onready var game_seed: Label = $VBoxContainer/game_seed

@onready var final_score: Label = $VBoxContainer/final_score
@onready var jump_counter: Label = $VBoxContainer/jump_counter

@onready var total_coins: Label = $VBoxContainer/total_coins
@onready var total_keys: Label = $VBoxContainer/total_keys


func _ready() -> void:
	# Fill seed with game value
	var game_seed_string: String = "Seed: " + str(game.game_seed)
	game_seed.text = game_seed_string

	# Fill stats with game values
	var final_score_string: String = "Score: " + ("%.2f" % game.altitude)
	final_score.text = final_score_string
	var jump_counter_string: String = "Jumps: " + str(game.jump_counter)
	jump_counter.text = jump_counter_string

	# Fill currencies with game values
	var total_coins_string: String = "Coins: " + str(game.total_coins)
	total_coins.text = total_coins_string
	var total_keys_string: String = "Keys: " + str(game.total_keys)
	total_keys.text = total_keys_string


func _on_menu_button_pressed() -> void:
	# Reset game values
	game.reset_game()
	# Navigate to Main Menu scene
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
