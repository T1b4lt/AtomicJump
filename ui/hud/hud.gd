class_name HUD
extends CanvasLayer

# Children
@onready var game_seed: Label = $seed_panel/MarginContainer/game_seed

@onready var altitude: Label = $stats_panel/MarginContainer/GridContainer/altitude_data

@onready var coins: Label = $stats_panel/MarginContainer/GridContainer/coins_data
@onready var keys: Label = $stats_panel/MarginContainer/GridContainer/keys_data

# Player stats
@onready var luck: Label = $stats_panel/MarginContainer/GridContainer/luck_data
@onready var speed: Label = $stats_panel/MarginContainer/GridContainer/speed_data
@onready var jump_force: Label = $stats_panel/MarginContainer/GridContainer/jump_force_data
@onready var max_jumps: Label = $stats_panel/MarginContainer/GridContainer/max_jumps_data
@onready var size: Label = $stats_panel/MarginContainer/GridContainer/size_data
@onready var attack_power: Label = $stats_panel/MarginContainer/GridContainer/attack_power_data
@onready var attack_haste: Label = $stats_panel/MarginContainer/GridContainer/attack_haste_data
# gdlint:ignore = max-line-length
@onready var attack_distance: Label = $stats_panel/MarginContainer/GridContainer/attack_distance_data
@onready var defense: Label = $stats_panel/MarginContainer/GridContainer/defense_data


func _ready() -> void:
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


func _process(_delta: float) -> void:
	# Set stats from game values
	altitude.text = "%.2f" % game.altitude

	# Currencies
	coins.text = str(game.actual_coins)
	keys.text = str(game.actual_keys)

	# Player stats
	luck.text = "%.2f" % game.pr_luck + " %"
	speed.text = "%.2f" % game.pr_speed
	jump_force.text = "%.2f" % game.pr_jump_force
	max_jumps.text = str(game.pr_max_jumps)
	size.text = "%.2f" % game.pr_size
	attack_power.text = "%.2f" % game.pr_attack_power
	attack_haste.text = "%.2f" % game.pr_attack_haste
	attack_distance.text = "%.2f" % game.pr_attack_distance
	defense.text = "%.2f" % game.pr_defense
