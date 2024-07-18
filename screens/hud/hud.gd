class_name HUD
extends CanvasLayer


# Childs
@onready var game_seed = $game_seed

@onready var altitude = $PanelContainer/VBoxContainer/altitude/altitude_data

@onready var coins = $PanelContainer/VBoxContainer/coins/coins_data
@onready var keys = $PanelContainer/VBoxContainer/keys/keys_data

func _ready():
	# Set game seed
	game_seed.text = str(game.seed)

func _process(_delta):
	# Set stats from game values
	altitude.text = "%.2f" % game.altitude
	
	# Currencies
	coins.text = str(game.actual_coins)
	keys.text = str(game.actual_keys)
	

