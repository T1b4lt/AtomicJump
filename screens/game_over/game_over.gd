class_name GameOver
extends CanvasLayer

const MAIN_MENU_SCENE = "res://screens/main_menu/main_menu.tscn"

@onready var final_score = $VBoxContainer/final_score

func _ready():
	# Get altitude from global
	var final_score_string = "Score: " + str(global.altitude)
	final_score.text = final_score_string

func _on_menu_button_pressed():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
