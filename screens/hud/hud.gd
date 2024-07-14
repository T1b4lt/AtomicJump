extends CanvasLayer

@onready var altitude = $altitude/altitude_data

func update_altitude(new_altitude: int):
	altitude.text = str(new_altitude)

