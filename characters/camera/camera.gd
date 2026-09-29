class_name Camera
extends Camera2D

# Parameters
const CAMERA_SPEED: float = 50.0  # camera speed attribute


func _process(delta: float) -> void:
	# Move camera upwards
	position.y -= CAMERA_SPEED * delta
