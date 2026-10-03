class_name Coin
extends Pickup
## Photon pickup (×1, ×5 or ×10): adds its value to the run (through
## Events.coin_collected) and flies to the player when it gets close.

## Photons added to the run.
@export var value: int = 1


func _apply(_player: Player) -> void:
	Events.coin_collected.emit(value)
