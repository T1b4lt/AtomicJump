class_name Game
extends Node

# Random number generator seed
var game_seed: int

# Protagonist stats
var pr_walk_velocity = 300.0
var pr_jump_velocity = -450.0
var pr_max_jumps = 2  # Allow double jump

# Game stats
var altitude: float = 0.0
var jump_counter: int = 0

# Currencies
var total_coins: int = 0
var actual_coins: int = 0
var total_keys: int = 0
var actual_keys: int = 0

func reset_game():
	# Seed
	game_seed = 0
	
	# Game stats
	altitude = 0.0
	jump_counter = 0
	
	# Currencies
	total_coins = 0
	actual_coins = 0
	total_keys = 0
	actual_keys = 0
