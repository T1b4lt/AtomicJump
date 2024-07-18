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
@onready var pause_menu = $pause_menu

# Variables
var camera_initial_y: int = 0
var added_platforms: int = 0
var is_platform_added: bool = false


func _ready():
	# Save camera initial position
	camera_initial_y = camera.position.y
	
	# Set game seed
	seed(game.game_seed)

func _process(_delta):
	# Check if protagonist fall off out of camera view
	if protagonist.position.y > camera.position.y + get_viewport().size[1]/2 + 50:
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
	game.set_altitude((camera_initial_y - camera.position.y) / (get_viewport().size[1]/11))
	
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
	# Set platform position (670 is viewport height in project settings)
	platform.position.y = -670 * added_platforms
	# Add new platform to scene
	add_child(platform)
	# Add signal observers
	platform.platform_enter_screen.connect(_add_platform)
	platform.platform_leave_screen.connect(_remove_platform)

func _remove_platform():
	if added_platforms >= 3:
		get_node("platform_" + str(added_platforms-3)).queue_free()

# Pause Menu Signals
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

# Initial Platform Signals
func _on_initial_platform_enter_screen():
	_add_platform()


func _on_initial_platform_leave_screen():
	get_node("initial").queue_free()
