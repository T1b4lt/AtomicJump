class_name Game
extends Node

# Random number generator seed
var game_seed: int

# Game stats
var altitude: float
var jump_counter: int

func reset_game():
	game_seed = 0
	
	altitude = 0.0
	jump_counter = 0

func set_seed(new_seed: int):
	# Set seed
	game_seed = new_seed

func set_altitude(new_altitude: float):
	# Set altitude
	altitude = new_altitude
	
func inc_jump_counter():
	# Set jump counter
	jump_counter += 1
