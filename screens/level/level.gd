class_name Level
extends Node2D


# Scenes
const MAIN_MENU_SCENE = "res://screens/main_menu/main_menu.tscn"
const GAME_OVER_SCENE = "res://screens/game_over/game_over.tscn"

# Parameters
const BASE_PLATFORM_RES = "res://platforms/platform_%s.tscn"
const NUM_PLATFORMS = 2

# Childs
@onready var camera = $camera
@onready var protagonist = $protagonist
@onready var hud = $hud
@onready var pause_menu = $pause_menu

# Variables
var camera_initial_y = 0
var added_platforms = 0
var is_platform_added = false

# Game values
var altitude = 0
var jump_counter = 0


func _ready():
	# Save camera initial position
	camera_initial_y = camera.position.y
	
	# Set game seed
	seed(global.game_seed)
	hud.set_game_seed(global.game_seed)
	
	# Set first platform randomly
	# _add_platform()
	

func _process(delta):
	# Check if protagonist fall off out of camera view
	if protagonist.position.y > camera.position.y + get_viewport().size[1]/2 + 50:
		# Set final global variables
		global.set_altitude(altitude)
		global.set_jump_counter(jump_counter)
		# Go to game over screen
		get_tree().change_scene_to_file(GAME_OVER_SCENE)
		return
	
	# Check if its time to add a new platform
	if altitude % 11 == 0 and !is_platform_added:
		# Remove passed platform if exist
		_remove_platform()
		# Add new platform
		_add_platform()
		is_platform_added = true
	if altitude % 11 != 0 and is_platform_added:
		is_platform_added = false
		
	# Check if user press pause button
	if Input.is_action_just_pressed("pause"):
		# Pause everything in the scene
		get_tree().paused = true
		# Show pause menu
		pause_menu.visible = true
		
	# Update altitude
	altitude = int((camera_initial_y - camera.position.y) / (get_viewport().size[1]/11))
	hud.set_altitude(altitude)
	
func _add_platform():
	# Get a random number
	var platform_idx = randi_range(1, NUM_PLATFORMS)
	# Instantiate the platform
	var platform_name = BASE_PLATFORM_RES % str(platform_idx)
	var platform = load(platform_name).instantiate()
	# Give name to new platform
	platform.name = "platform_" + str(added_platforms)
	# Add 1 to platform counter
	added_platforms += 1
	# Set platform position
	platform.position.y = -(get_viewport().size[1]) * added_platforms
	# Add new platform to scene
	add_child(platform)

func _remove_platform():
	if altitude == 0:
		return
	elif altitude == 11:
		get_node("initial").queue_free() 
	else:
		get_node("platform_" + str(added_platforms-2)).queue_free()

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
