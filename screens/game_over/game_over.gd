class_name GameOver
extends CanvasLayer


# Scenes
const MAIN_MENU_SCENE = "res://screens/main_menu/main_menu.tscn"

# Childs
@onready var game_seed = $VBoxContainer/game_seed

@onready var final_score = $VBoxContainer/final_score
@onready var jump_counter = $VBoxContainer/jump_counter

@onready var total_coins = $VBoxContainer/total_coins
@onready var total_keys = $VBoxContainer/total_keys


func _ready():
	# Fill seed with game value
	var game_seed_string = "Seed: " + str(game.game_seed)
	game_seed.text = game_seed_string
	
	# Fill stats with game values
	var final_score_string = "Score: " + ("%.2f" % game.altitude)
	final_score.text = final_score_string
	var jump_counter_string = "Jumps: " + str(game.jump_counter)
	jump_counter.text = jump_counter_string
	
	# Fill currencies with game values
	var total_coins_string = "Coins: " + str(game.total_coins)
	total_coins.text = total_coins_string
	var total_keys_string = "Keys: " + str(game.total_keys)
	total_keys.text = total_keys_string

func _on_menu_button_pressed():
	# Reset game values
	game.reset_game()
	# Navigate to Main Menu scene
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
