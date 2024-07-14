class_name Camera
extends Camera2D


# Parameters
var CAMERA_SPEED: float = 50.0 # camera speed attribute


func _process(delta):
	# Move camera upwards
	position.y -= CAMERA_SPEED * delta
