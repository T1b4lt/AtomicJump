class_name HUD
extends CanvasLayer


# Childs
@onready var game_seed = $seed_panel/MarginContainer/game_seed

@onready var altitude = $stats_panel/MarginContainer/GridContainer/altitude_data

@onready var coins = $stats_panel/MarginContainer/GridContainer/coins_data
@onready var keys = $stats_panel/MarginContainer/GridContainer/keys_data

func _ready():
	# Set game seed
	game_seed.text = str(game.game_seed)

func _process(_delta):
	# Set stats from game values
	altitude.text = "%.2f" % game.altitude
	
	# Currencies
	coins.text = str(game.actual_coins)
	keys.text = str(game.actual_keys)
	

