class_name ScrollingCamera
extends Camera2D
## Prototype camera: scrolls upwards at a constant speed. Phase 4 replaces it
## with a camera that follows the player and the rising threat.

## Upward scroll speed in px/s.
@export var scroll_speed: float = 50.0


func _process(delta: float) -> void:
	position.y -= scroll_speed * delta
