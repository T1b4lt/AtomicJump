class_name HUD
extends CanvasLayer


# Childs
@onready var game_seed = $game_seed
@onready var altitude = $altitude/altitude_data

func _ready():
	# Set game seed
	game_seed.text = str(game.game_seed)

func _process(_delta):
	# Set stats from game values
	altitude.text = "%.2f" % game.altitude

