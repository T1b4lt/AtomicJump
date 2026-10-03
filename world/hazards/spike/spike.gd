class_name Spike
extends Area2D
## Hurts the player while in contact. The player's invulnerability window sets
## the rate, so standing on the spikes keeps hurting.

## Damage of each hit, before defense.
@export var damage: float = 10.0

## Player in contact, if any.
var _player: Player = null


func _ready() -> void:
	# Only process while the player is in contact
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if is_instance_valid(_player):
		_player.take_damage(damage)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body as Player
		_player.take_damage(damage)
		set_physics_process(true)


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		set_physics_process(false)
