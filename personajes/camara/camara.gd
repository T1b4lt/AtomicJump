class_name Camara
extends Camera2D

@export var speed: float = 20.0 # speed attribute


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# move camera upwards
	position.y -= speed * delta
