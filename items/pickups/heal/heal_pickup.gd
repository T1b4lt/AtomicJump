class_name HealPickup
extends Pickup
## Energy quantum (cuanto de energía): restores coherence. It is not taken
## while the coherence is full; it waits until it is not.

## Coherence restored (+20, or +50 the big one).
@export var amount: float = 20.0


func can_collect(player: Player) -> bool:
	return player.run != null and not player.run.is_hp_full() and not player.run.is_dead()


func _apply(player: Player) -> void:
	player.run.heal(amount)
