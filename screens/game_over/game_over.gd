class_name GameOver
extends CanvasLayer

const MAIN_MENU_SCENE = "res://screens/main_menu/main_menu.tscn"

func _on_menu_button_pressed():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
