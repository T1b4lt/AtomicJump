class_name Coin
extends Area2D

# Children
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Start playing idle animation
	anim.play("idle")


func _on_body_entered(body: Node2D) -> void:
	if body is Protagonist:
		# Increase game coins
		game.actual_coins += 1
		game.total_coins += 1
		# Delete node
		queue_free()
