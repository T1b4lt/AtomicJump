class_name Game
extends Node

# Provisional seed format until Phase 3: always a positive 9-digit number
const SEED_MIN: int = 100_000_000
const SEED_MAX: int = 999_999_999
const SEED_DIGITS: int = 9

# Random number generator seed
var game_seed: int

# Player stats
var pr_hp: float = 100.0  # Player life
var pr_max_hp: float = 100.0  # Player max life (runs start at full hp)
var pr_luck: int = 1  # 1 to 100 % of luck
var pr_speed: float = 300.0  # Speed
var pr_jump_force: float = -450.0  # Jump force
var pr_max_jumps: int = 2  # Chained jumps, ground jump included (2 = double jump)
var pr_size: float = 1.0  # Player size
var pr_attack_power: float = 5.0  # Base damage
var pr_attack_haste: float = 1.0  # Shots per second
var pr_attack_distance: float = 5.0  # Shot distance
var pr_defense: float = 1.0  # Damage taken multiplier (1 = full damage), down to 0.5

# Game stats
var altitude: float = 0.0
var jump_counter: int = 0

# Currencies
var total_coins: int = 0
var actual_coins: int = 0
var total_keys: int = 0
var actual_keys: int = 0


## Generates a random seed that can be typed back in the main menu.
static func generate_seed() -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(SEED_MIN, SEED_MAX)


## Returns whether the text is a seed the player can type in the main menu.
static func is_valid_seed_text(text: String) -> bool:
	var trimmed: String = text.strip_edges()
	if trimmed.length() != SEED_DIGITS or not trimmed.is_valid_int():
		return false
	var value: int = trimmed.to_int()
	return value >= SEED_MIN and value <= SEED_MAX


## Starts a new run from a clean state, whatever screen the previous run ended on.
func start_run(new_seed: int) -> void:
	reset_game()
	game_seed = new_seed


func reset_game() -> void:
	# Seed
	game_seed = 0

	# Player stats
	pr_hp = 100.0
	pr_max_hp = 100.0
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
