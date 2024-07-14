class_name Level
extends Node2D

const MAIN_MENU_SCENE = "res://screens/main_menu/main_menu.tscn"
const GAME_OVER_SCENE = "res://screens/game_over/game_over.tscn"

@onready var camera = $camera
@onready var protagonist = $protagonist
@onready var hud = $hud
@onready var pause_menu = $pause_menu

# Camera initial position
var camera_initial_y

# Game values
var altitude = 0
var jump_counter = 0

func _ready():
	# Save camera initial position
	camera_initial_y = camera.position.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Check if protagonist fall off out of camera view
	if protagonist.position.y > camera.position.y + get_viewport().size[1]/2 + 50:
		# Set fina global variables
		global.set_altitude(altitude)
		global.set_jump_counter(jump_counter)
		# Go to game over screen
		get_tree().change_scene_to_file(GAME_OVER_SCENE)
		return
		
	# Check if user press pause button
	if Input.is_action_just_pressed("pause"):
		# Pause everything in the scene
		get_tree().paused = true
		# Show pause menu
		pause_menu.visible = true
		
	# Update altitude
	altitude = int((camera_initial_y - camera.position.y) / (get_viewport().size[1]/11))
	hud.update_altitude(altitude)

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


func _on_protagonist_jump():
	jump_counter = jump_counter + 1
