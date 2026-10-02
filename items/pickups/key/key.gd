class_name KeyPickup
extends Area2D

# Children
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Start playing idle animation
	anim.play("idle")


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# Increase game keys
		game.actual_keys += 1
		game.total_keys += 1
		# Delete node
		queue_free()
