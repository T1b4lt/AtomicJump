class_name HUD
extends CanvasLayer


# Childs
@onready var game_seed = $PanelContainer2/MarginContainer/game_seed

@onready var altitude = $PanelContainer/MarginContainer/VBoxContainer/altitude/altitude_data

@onready var coins = $PanelContainer/MarginContainer/VBoxContainer/coins/coins_data
@onready var keys = $PanelContainer/MarginContainer/VBoxContainer/keys/keys_data

func _ready():
	# Set game seed
	game_seed.text = str(game.game_seed)

func _process(_delta):
	# Set stats from game values
	altitude.text = "%.2f" % game.altitude
	
	# Currencies
	coins.text = str(game.actual_coins)
	keys.text = str(game.actual_keys)
	

