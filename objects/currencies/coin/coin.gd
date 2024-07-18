class_name Coin
extends Area2D

# Childs
@onready var anim = $AnimatedSprite2D

func _ready():
	# Start playing idle animation
	anim.play("idle")

func _on_body_entered(body):
	if body is Protagonist:
		# Increase game coins
		game.actual_coins += 1
		game.total_coins += 1
		# Delete node
		queue_free()
