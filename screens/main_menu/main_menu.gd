class_name MainMenu
extends CanvasLayer

# Scenes
const LEVEL_SCENE = "res://screens/level/level.tscn"

func _on_solo_mode_button_pressed():
	# Generate a game seed
	var game_seed = str(Time.get_unix_time_from_system()).hash()
	global.set_seed(game_seed)
	# Change to scene level
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _on_exit_button_pressed():
	# Exit game
	get_tree().quit()
