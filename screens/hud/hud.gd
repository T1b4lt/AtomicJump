class_name HUD
extends CanvasLayer


# Childs
@onready var game_seed = $game_seed
@onready var altitude = $altitude/altitude_data

func set_game_seed(new_seed):
	game_seed.text = str(new_seed)

func set_altitude(new_altitude: float):
	altitude.text = "%.2f" % new_altitude

