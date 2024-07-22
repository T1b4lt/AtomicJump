class_name HUD
extends CanvasLayer


# Childs
@onready var game_seed = $seed_panel/MarginContainer/game_seed

@onready var altitude = $stats_panel/MarginContainer/GridContainer/altitude_data

@onready var coins = $stats_panel/MarginContainer/GridContainer/coins_data
@onready var keys = $stats_panel/MarginContainer/GridContainer/keys_data

# Protagonist stats
@onready var luck = $stats_panel/MarginContainer/GridContainer/luck_data
@onready var speed = $stats_panel/MarginContainer/GridContainer/speed_data
@onready var jump_force = $stats_panel/MarginContainer/GridContainer/jump_force_data
@onready var max_jumps = $stats_panel/MarginContainer/GridContainer/max_jumps_data
@onready var size = $stats_panel/MarginContainer/GridContainer/size_data
@onready var attack_power = $stats_panel/MarginContainer/GridContainer/attack_power_data
@onready var attack_haste = $stats_panel/MarginContainer/GridContainer/attack_haste_data
@onready var attack_distance = $stats_panel/MarginContainer/GridContainer/attack_distance_data
@onready var defense = $stats_panel/MarginContainer/GridContainer/defense_data

func _ready():
	# Set game seed
	game_seed.text = str(game.game_seed)

	# Set protagonist stats
	luck.text = "%.2f" % game.pr_luck + " %"
	speed.text = "%.2f" % game.pr_speed
	jump_force.text = "%.2f" % game.pr_jump_force
	max_jumps.text = str(game.pr_max_jumps)
	size.text = "%.2f" % game.pr_size
	attack_power.text = "%.2f" % game.pr_attack_power
	attack_haste.text = "%.2f" % game.pr_attack_haste
	attack_distance.text = "%.2f" % game.pr_attack_distance
	defense.text = "%.2f" % game.pr_defense

func _process(_delta):
	# Set stats from game values
	altitude.text = "%.2f" % game.altitude
	
	# Currencies
	coins.text = str(game.actual_coins)
	keys.text = str(game.actual_keys)

	# Protagonist stats
	luck.text = "%.2f" % game.pr_luck + " %"
	speed.text = "%.2f" % game.pr_speed
	jump_force.text = "%.2f" % game.pr_jump_force
	max_jumps.text = str(game.pr_max_jumps)
	size.text = "%.2f" % game.pr_size
	attack_power.text = "%.2f" % game.pr_attack_power
	attack_haste.text = "%.2f" % game.pr_attack_haste
	attack_distance.text = "%.2f" % game.pr_attack_distance
	defense.text = "%.2f" % game.pr_defense

	

