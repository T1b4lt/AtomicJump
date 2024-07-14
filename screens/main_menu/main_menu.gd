class_name MainMenu
extends CanvasLayer

const LEVEL_SCENE = "res://screens/level/level.tscn"

func _on_solo_mode_button_pressed():
	get_tree().change_scene_to_file(LEVEL_SCENE)


func _on_exit_button_pressed():
	get_tree().quit()
