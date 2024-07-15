extends Node

# Random number generator seed
var game_seed: int

# Game stats
var altitude: float
var jump_counter: int

func set_seed(new_seed: int):
	# Set seed
	game_seed = new_seed

func set_altitude(new_altitude: float):
	# Set altitude
	altitude = new_altitude
	
func set_jump_counter(new_jump_counter: int):
	# Set jump counter
	jump_counter = new_jump_counter
