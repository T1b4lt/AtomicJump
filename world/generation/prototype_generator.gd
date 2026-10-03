class_name PrototypeGenerator
extends RefCounted
## Generation of the prototype level with addressed rolls (docs/08-seeds.md):
## which chunk goes at each height and which objects fill its slots. Pure
## functions of the run's WorldRng. Provisional: Phase 5 replaces it with
## LayerGenerator and ChunkLibrary (docs/05-world.md).

const LAYER: String = "K"
## Branch of the prototype's single column (forks arrive in Phase 5).
const BRANCH: String = "main"
## Index 0 of the column is always the initial chunk of the level scene.
const INITIAL_CHUNK: StringName = &"initial"
const CHUNK_SCENES: Dictionary[StringName, PackedScene] = {
	&"platform_1": preload("res://world/chunks/k/platform_1.tscn"),
	&"platform_2": preload("res://world/chunks/k/platform_2.tscn"),
}
## Weight of each chunk of CHUNK_SCENES in the column.
const CHUNK_WEIGHTS: Dictionary[StringName, float] = {
	&"platform_1": 1.0,
	&"platform_2": 1.0,
}
## Object kinds, in the order they take the shuffled slots of a chunk.
const OBJECT_KINDS: Array[StringName] = [Chunk.SPIKE, Chunk.COIN, Chunk.KEY]
## How many objects of each kind a chunk gets: rolled in [x, y].
const OBJECT_COUNTS: Dictionary[StringName, Vector2i] = {
	Chunk.SPIKE: Vector2i(0, 1),
	Chunk.COIN: Vector2i(1, 5),
	Chunk.KEY: Vector2i(0, 1),
}


## Address key of the chunk at the index of the column.
static func chunk_key(index: int) -> Array:
	return [LAYER, BRANCH, index]


## Id of the chunk at the index of the column.
static func pick_chunk(rng: WorldRng, index: int) -> StringName:
	if index == 0:
		return INITIAL_CHUNK
	return rng.pick_weighted(CHUNK_WEIGHTS, &"layout", chunk_key(index))


## Object kind of each slot of the chunk at the index (&"" if it stays empty).
## The slots are shuffled once and each kind takes the next ones, so there are
## no retries and every object gets its own slot.
static func plan_objects(rng: WorldRng, index: int, slot_count: int) -> Array[StringName]:
	var key: Array = chunk_key(index)
	var plan: Array[StringName] = []
	plan.resize(slot_count)
	plan.fill(&"")
	var order: Array = rng.shuffled(range(slot_count), &"slot_order", key)
	var next: int = 0
	for kind: StringName in OBJECT_KINDS:
		var count_range: Vector2i = OBJECT_COUNTS[kind]
		var count: int = rng.roll_range(count_range.x, count_range.y, &"slot_count", key + [kind])
		for _i: int in mini(count, slot_count - next):
			var slot: int = order[next]
			plan[slot] = kind
			next += 1
	return plan
