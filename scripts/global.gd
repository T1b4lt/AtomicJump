extends Node

var altitude: int

func reset_global():
	# Method to reset all global variables to default
	altitude = 0

func update_global_altitude(new_altitude: int):
	# Update altitude
	altitude = new_altitude
