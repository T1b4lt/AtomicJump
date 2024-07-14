class_name Level
extends Node2D

const MAIN_MENU_SCENE = "res://screens/main_menu/main_menu.tscn"
const GAME_OVER_SCENE = "res://screens/game_over/game_over.tscn"

@onready var camera: Camera2D = $camera
@onready var protagonist: CharacterBody2D = $protagonist
@onready var pause_menu: CanvasLayer = $pause_menu

# Camara initial position
var camera_initial_pos

func _ready():
	# Save camara initial position
	camera_initial_pos = camera.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Check if protagonist fall off out of camara view
	if protagonist.position.y > camera.position.y + get_viewport().size[1]/2 + 50:
		# Go to game over screen
		get_tree().change_scene_to_file(GAME_OVER_SCENE)
		
	# Check if user press pause button
	if Input.is_action_just_pressed("pause"):
		# Pause everything in the scene
		get_tree().paused = true
		# Show pause menu
		pause_menu.visible = true


func _on_pause_menu_resume_button_pressed():
	# Hide pause menu
	pause_menu.visible = false
	# Resume activity in scene
	get_tree().paused = false


func _on_pause_menu_menu_button_pressed():
	# Resume activity in scene
	get_tree().paused = false
	# Go to game over screen
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_pause_menu_exit_button_pressed():
	# Exit game
	get_tree().quit()
