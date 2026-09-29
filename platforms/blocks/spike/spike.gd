class_name Spike
extends Area2D

# Parameters
const SPIKE_DAMAGE: float = 10.0


func _on_body_entered(body: Node2D) -> void:
	if body is Protagonist:
		# Damage protagonist (use game.pr_defense as damage reducer factor)
		game.pr_hp = maxf(0.0, game.pr_hp - SPIKE_DAMAGE * game.pr_defense)
