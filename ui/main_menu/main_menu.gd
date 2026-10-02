class_name MainMenu
extends CanvasLayer

# Scenes
const LEVEL_SCENE = "res://world/level/level.tscn"
const SETTINGS_MENU_SCENE = "res://ui/settings_menu/settings_menu.tscn"

# Children
@onready var game_seed_input: LineEdit = $VBoxContainer/HBoxContainer/game_seed_input


func _on_solo_mode_button_pressed() -> void:
	# Start a new run with a seed that can be typed back later
	game.start_run(Game.generate_seed())
	# Change to scene level
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _on_seed_mode_button_pressed() -> void:
	# Check that game seed is correct
	if not Game.is_valid_seed_text(game_seed_input.text):
		# Reset input
		game_seed_input.text = ""
		return
	# Start a new run with the typed seed
	game.start_run(game_seed_input.text.strip_edges().to_int())
	# Change to scene level
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _on_settings_button_pressed() -> void:
	# Change to settings menu
	get_tree().change_scene_to_file(SETTINGS_MENU_SCENE)


func _on_exit_button_pressed() -> void:
	# Exit game
	get_tree().quit()
