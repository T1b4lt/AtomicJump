class_name LootContainer
extends Node2D
## Base of the objects that fill a container slot (a quantum well, a bound
## electron, a superposition). The chunk gives them the address of their slot
## and the run's LootRoller; they roll what they hold with them.

## Address of its slot ([layer, branch, index, slot]).
var address: Array = []
var roller: LootRoller = null
var layer_index: int = 0


func setup_slot(p_address: Array, p_roller: LootRoller, p_layer_index: int = 0) -> void:
	address = p_address
	roller = p_roller
	layer_index = p_layer_index
