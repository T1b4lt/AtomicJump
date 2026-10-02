class_name Coin
extends Area2D
## Photon pickup: adds its value to the run when the player touches it.

## Coins added to the run.
@export var value: int = 1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_sprite.play(&"idle")


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		Events.coin_collected.emit(value)
		queue_free()
