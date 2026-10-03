class_name SlotFiller
extends RefCounted
## What appears in the spawn slots of a chunk (docs/08-seeds.md#modificadores-y-monotonía):
## whether a slot is filled is a "slot" roll against the kind's chance (raising
## the chance only adds objects) and what fills it is a "slot_kind" pick among
## the layer's objects for that kind ("enemy" for the enemy slots, the domain
## that Entropy will change). Both are addressed by the chunk's key plus the
## slot name, so the order of the slots does not matter.

const ENEMY_SLOT_KINDS: Array[StringName] = [Chunk.SLOT_ENEMY_GROUND, Chunk.SLOT_ENEMY_AIR]


## {slot name: object id} for the slots ({name: kind}) of the chunk at `key`.
## `chance_multiplier` is where upgrades will raise the chances.
static func plan(
	rng: WorldRng,
	layer: LayerData,
	key: Array,
	slots: Dictionary[StringName, StringName],
	chance_multiplier: float = 1.0
) -> Dictionary[StringName, StringName]:
	var result: Dictionary[StringName, StringName] = {}
	for slot_name: StringName in slots:
		var kind: StringName = slots[slot_name]
		var objects: Dictionary[StringName, float] = layer.get_slot_objects(kind)
		if objects.is_empty():
			continue
		var chance: float = layer.slot_chances.get(kind, 0.0) * chance_multiplier
		var address: Array = key + [slot_name]
		if rng.chance(chance, &"slot", address):
			result[slot_name] = rng.pick_weighted(objects, kind_domain(kind), address)
	return result


## Domain of the roll that picks what fills a slot kind.
static func kind_domain(kind: StringName) -> StringName:
	return &"enemy" if kind in ENEMY_SLOT_KINDS else &"slot_kind"
