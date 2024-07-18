class_name MainMenu
extends CanvasLayer

# Scenes
const LEVEL_SCENE = "res://screens/level/level.tscn"
const SETTINGS_MENU_SCENE = "res://screens/settings_menu/settings_menu.tscn"

# Childs
@onready var game_seed_input = $VBoxContainer/HBoxContainer/game_seed_input

func _on_solo_mode_button_pressed():
	# Generate a game seed
	var game_seed = str(Time.get_unix_time_from_system()).hash()
	game.set_seed(game_seed)
	# Change to scene level
	get_tree().change_scene_to_file(LEVEL_SCENE)

func _on_seed_mode_button_pressed():
	# Check that game seed is correct
	if game_seed_input.text.length() != 9 or !game_seed_input.text.is_valid_int():
		# Reset input
		game_seed_input.text = ""
		return
	# Set game seed
	game.set_seed(int(game_seed_input.text))
	# Change to scene level
	get_tree().change_scene_to_file(LEVEL_SCENE)
	
func _on_settings_button_pressed():
	# Change to settings menu
	get_tree().change_scene_to_file(SETTINGS_MENU_SCENE)

func _on_exit_button_pressed():
	# Exit game
	get_tree().quit()
