class_name KeyPickup
extends Pickup
## Positron pickup: adds its value to the run (through Events.key_collected).

## Positrons added to the run.
@export var value: int = 1


func _apply(_player: Player) -> void:
	Events.key_collected.emit(value)
