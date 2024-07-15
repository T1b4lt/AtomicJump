class_name GameOver
extends CanvasLayer


# Scenes
const MAIN_MENU_SCENE = "res://screens/main_menu/main_menu.tscn"

# Childs
@onready var game_seed = $VBoxContainer/game_seed
@onready var final_score = $VBoxContainer/final_score
@onready var jump_counter = $VBoxContainer/jump_counter


func _ready():
	# Fill seed with global value
	var game_seed_string = "Seed: " + str(global.game_seed)
	game_seed.text = game_seed_string
	# Fill stats with global values
	var final_score_string = "Score: " + ("%.2f" % global.altitude)
	final_score.text = final_score_string
	var jump_counter_string = "Jumps: " + str(global.jump_counter)
	jump_counter.text = jump_counter_string

func _on_menu_button_pressed():
	# Navigate to Main Menu scene
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
