class_name Spike
extends Area2D

# Parameters
const spike_damage: float = 10.0

func _on_body_entered(body):
	if body is Protagonist:
		# Damage protagonist (use game.pr_defense as damage reducer factor)
		game.pr_hp = max(0, game.pr_hp - spike_damage * game.pr_defense)
