class_name GoldenSeeds
extends RefCounted
## Golden seeds (docs/08-seeds.md): what a few fixed seeds generate, saved in a
## JSON file per generation version. generation_test.gd compares the current
## generation with it, or rewrites it when UPDATE_ENV is "1".

const SEEDS: Array[String] = [
	"K7QX-2MPA", "0000-0000", "ZZZZ-ZZZZ", "hola mundo", "AtomicJump", "ñandú 42"
]
## Chunks of the column saved per seed, initial chunk included.
const CHUNK_COUNT: int = 12
const FILE_PATH: String = "res://tests/golden/generation_g%d.json"
## Environment variable that makes the golden test rewrite the file.
const UPDATE_ENV: String = "UPDATE_GOLDEN_SEEDS"
const INITIAL_CHUNK_SCENE: PackedScene = preload("res://world/chunks/k/initial.tscn")
## One character per slot in the saved object plans.
const EMPTY_SLOT: String = "."


static func file_path() -> String:
	return FILE_PATH % WorldRng.GENERATION_VERSION


static func should_update() -> bool:
	return OS.get_environment(UPDATE_ENV) == "1"


static func save(snapshot: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(file_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshot, "  ", false) + "\n")
	file.close()


## What every golden seed generates, as JSON-ready data.
static func take_all() -> Dictionary:
	var snapshot: Dictionary = {}
	var slot_counts: Dictionary[StringName, int] = _slot_counts()
	for seed_text: String in SEEDS:
		snapshot[seed_text] = take(seed_text, slot_counts)
	return snapshot


## What one seed generates: its value (as text, JSON numbers are not 64-bit),
## the chunk ids of the column and their object plans, one character per slot.
static func take(seed_text: String, slot_counts: Dictionary[StringName, int]) -> Dictionary:
	var rng := WorldRng.new(SeedCode.to_int(seed_text))
	var chunks: Array[String] = []
	var objects: Array[String] = []
	for index: int in CHUNK_COUNT:
		var id: StringName = PrototypeGenerator.pick_chunk(rng, index)
		chunks.append(String(id))
		objects.append(plan_to_text(PrototypeGenerator.plan_objects(rng, index, slot_counts[id])))
	return {
		"code": SeedCode.from_text(seed_text),
		"value": str(rng.seed_value),
		"chunks": chunks,
		"objects": objects,
	}


static func plan_to_text(plan: Array[StringName]) -> String:
	var text: String = ""
	for kind: StringName in plan:
		text += EMPTY_SLOT if kind.is_empty() else String(kind).left(1)
	return text


## Slots of every chunk the generator can pick, read from the scenes.
static func _slot_counts() -> Dictionary[StringName, int]:
	var counts: Dictionary[StringName, int] = {}
	counts[PrototypeGenerator.INITIAL_CHUNK] = _count_slots(INITIAL_CHUNK_SCENE)
	for id: StringName in PrototypeGenerator.CHUNK_SCENES:
		counts[id] = _count_slots(PrototypeGenerator.CHUNK_SCENES[id])
	return counts


static func _count_slots(scene: PackedScene) -> int:
	var chunk: Node = scene.instantiate()
	var count: int = chunk.get_node(^"%ObjectPlaceholders").get_child_count()
	chunk.free()
	return count
