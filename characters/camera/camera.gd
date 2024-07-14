class_name Camera
extends Camera2D

var CAMERA_SPEED: float = 50.0 # camera speed attribute


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# move camera upwards
	position.y -= CAMERA_SPEED * delta
