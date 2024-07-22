class_name Game
extends Node

# Random number generator seed
var game_seed: int

# Protagonist stats
var pr_hp: float = 100.0 # Protagonist life
var pr_max_hp: float = 110.0 # Protagonist max life
var pr_luck: int = 1 # 1 to 100 % of luck
var pr_speed: float = 300.0 # Speed
var pr_jump_force: float = -450.0 # Jump force
var pr_max_jumps: int = 2  # Allow double jump
var pr_size: float = 1.0 # Protagonist size
var pr_attack_power: float = 5.0 # Base damage
var pr_attack_haste: float = 1.0 # Shoots per second
var pr_attack_distance: float = 5.0 # Distance shoot
var pr_defense: float = 1.0 # Protagonist damage reducer factor, decreasing to 0.5

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

	# Protagonist stats
	pr_hp = 100.0
	pr_max_hp = 110.0
	pr_luck = 1
	pr_speed = 300.0
	pr_jump_force = -450.0
	pr_max_jumps = 2
	pr_size = 1.0
	pr_attack_power = 5.0
	pr_attack_haste = 1.0
	pr_attack_distance = 5.0
	pr_defense = 1.0
	
	# Game stats
	altitude = 0.0
	jump_counter = 0
	
	# Currencies
	total_coins = 0
	actual_coins = 0
	total_keys = 0
	actual_keys = 0
