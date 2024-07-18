class_name Key
extends Area2D

# Childs
@onready var anim = $AnimatedSprite2D

func _ready():
	# Start playing idle animation
	anim.play("idle")

func _on_body_entered(body):
	# Increase game keys
	game.actual_keys += 1
	game.total_keys += 1
	# Delete node
	queue_free()
