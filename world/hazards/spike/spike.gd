class_name Spike
extends Area2D
## Hurts the protagonist while in contact. The protagonist's invulnerability
## window sets the rate, so standing on the spikes keeps hurting.

# Parameters
const SPIKE_DAMAGE: float = 10.0

# Variables
var _protagonist: Player = null  # Player in contact, if any


func _ready() -> void:
	# Only process while the protagonist is in contact
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if is_instance_valid(_protagonist):
		_protagonist.take_damage(SPIKE_DAMAGE)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_protagonist = body as Player
		_protagonist.take_damage(SPIKE_DAMAGE)
		set_physics_process(true)


func _on_body_exited(body: Node2D) -> void:
	if body == _protagonist:
		_protagonist = null
		set_physics_process(false)
