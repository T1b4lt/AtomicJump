class_name Level
extends Node2D

# Scenes
const MAIN_MENU_SCENE = "res://screens/main_menu/main_menu.tscn"
const GAME_OVER_SCENE = "res://screens/game_over/game_over.tscn"

# Parameters
const BASE_PLATFORM_RES = "res://platforms/platform_%s.tscn"
const NUM_PLATFORMS = 2

# Variables
var camera_initial_y: int = 0
var added_platforms: int = 0
var is_platform_added: bool = false

# Children
@onready var camera: Camera = $camera
@onready var protagonist: Protagonist = $protagonist


func _ready() -> void:
	# Save camera initial position
	camera_initial_y = int(camera.position.y)

	# Set game seed
	seed(game.game_seed)


func _process(_delta: float) -> void:
	# Check if protagonist falls out of the camera view
	if protagonist.position.y > camera.position.y + int(get_viewport_rect().size.y) / 2 + 50:
		# Go to game over screen
		get_tree().change_scene_to_file(GAME_OVER_SCENE)
		return

	# Check if protagonist runs out of hp
	if game.pr_hp <= 0:
		# Go to game over screen
		get_tree().change_scene_to_file(GAME_OVER_SCENE)
		return

	# Update altitude
	game.altitude = (camera_initial_y - camera.position.y) / (int(get_viewport_rect().size.y) / 11)


func _add_platform() -> void:
	# Get a random number
	var platform_idx: int = randi_range(1, NUM_PLATFORMS)
	# Instantiate the platform
	var platform_name: String = BASE_PLATFORM_RES % str(platform_idx)
	var platform_scene: PackedScene = load(platform_name)
	var platform: Platform = platform_scene.instantiate() as Platform
	# Give name to new platform
	platform.name = "platform_" + str(added_platforms)
	# Add 1 to platform counter
	added_platforms += 1
	# Set platform position (670 is viewport height in project settings)
	platform.position.y = -670 * added_platforms
	# Add new platform to scene
	add_child(platform)
	# Place objects in the platform
	platform.place_objects()
	# Add signal observers
	platform.platform_enter_screen.connect(_add_platform)
	platform.platform_leave_screen.connect(_remove_platform)


func _remove_platform() -> void:
	if added_platforms >= 3:
		get_node("platform_" + str(added_platforms - 3)).queue_free()


# Pause Menu Signals
func _on_pause_menu_menu_button_pressed() -> void:
	# Go back to main menu (the next run starts from a clean state)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_pause_menu_exit_button_pressed() -> void:
	# Exit game
	get_tree().quit()


# Initial Platform Signals
func _on_initial_platform_enter_screen() -> void:
	# Add second platform
	_add_platform()
	# Place objects in initial platform
	(get_node("initial") as Platform).place_objects()


func _on_initial_platform_leave_screen() -> void:
	# Delete initial platform
	get_node("initial").queue_free()
