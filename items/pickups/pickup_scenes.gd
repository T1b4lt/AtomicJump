class_name PickupScenes
extends RefCounted
## Scenes of the pickups by object id (the ids of the slots, the loot tables
## and the drops). Containers spawn them from here; Chunk includes them in its
## OBJECT_SCENES.

const COIN: StringName = &"coin"
const COIN_5: StringName = &"coin_5"
const COIN_10: StringName = &"coin_10"
const KEY: StringName = &"key"
const HEAL: StringName = &"heal_pickup"
const HEAL_BIG: StringName = &"heal_pickup_big"
const SCENES: Dictionary[StringName, PackedScene] = {
	COIN: preload("res://items/pickups/coin/coin.tscn"),
	COIN_5: preload("res://items/pickups/coin/coin_5.tscn"),
	COIN_10: preload("res://items/pickups/coin/coin_10.tscn"),
	KEY: preload("res://items/pickups/key/key.tscn"),
	HEAL: preload("res://items/pickups/heal/heal_pickup.tscn"),
	HEAL_BIG: preload("res://items/pickups/heal/heal_pickup_big.tscn"),
}


static func has(object_id: StringName) -> bool:
	return SCENES.has(object_id)


static func instantiate(object_id: StringName) -> Pickup:
	return SCENES[object_id].instantiate() as Pickup
