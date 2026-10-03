class_name Chunk
extends Node2D
## Prototype chunk: a screen-high block of platforms with object placeholders.
## Phase 5 turns it into the real chunk format (docs/05-world.md).

signal screen_entered
signal screen_exited

## Height of every prototype chunk in px (the old 1160×670 viewport height).
const HEIGHT: float = 670.0
## Width of the playable area in px, walls included.
const WIDTH: float = 1160.0
## Object kinds a slot (object placeholder) can hold.
const SPIKE: StringName = &"spike"
const COIN: StringName = &"coin"
const KEY: StringName = &"key"
const OBJECT_SCENES: Dictionary[StringName, PackedScene] = {
	SPIKE: preload("res://world/hazards/spike/spike.tscn"),
	COIN: preload("res://items/pickups/coin/coin.tscn"),
	KEY: preload("res://items/pickups/key/key.tscn"),
}

@onready var _object_placeholders: Node2D = %ObjectPlaceholders


## Number of object slots (placeholders) of the chunk.
func get_slot_count() -> int:
	return _object_placeholders.get_child_count()


## Fills the slots with the plan from PrototypeGenerator.plan_objects(): one
## object kind per slot, in the placeholders' order (&"" leaves it empty).
func place_objects(plan: Array[StringName]) -> void:
	for slot: int in mini(plan.size(), get_slot_count()):
		if plan[slot].is_empty():
			continue
		var object: Node2D = OBJECT_SCENES[plan[slot]].instantiate() as Node2D
		object.position = (_object_placeholders.get_child(slot) as Node2D).position
		add_child(object)


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	screen_entered.emit()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	screen_exited.emit()
