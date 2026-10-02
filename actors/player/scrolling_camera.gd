class_name ScrollingCamera
extends Camera2D

# Parameters
const CAMERA_SPEED: float = 50.0  # Upward scroll speed in px/s


func _process(delta: float) -> void:
	# Move camera upwards
	position.y -= CAMERA_SPEED * delta
