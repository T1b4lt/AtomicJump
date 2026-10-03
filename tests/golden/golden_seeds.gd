class_name GoldenSeeds
extends RefCounted
## Golden seeds (docs/08-seeds.md): what a few fixed seeds generate in Layer K,
## saved in a JSON file per generation version. generation_test.gd compares the
## current generation with it, or rewrites it when UPDATE_ENV is "1".

const SEEDS: Array[String] = [
	"K7QX-2MPA", "0000-0000", "ZZZZ-ZZZZ", "hola mundo", "AtomicJump", "ñandú 42"
]
const FILE_PATH: String = "res://tests/golden/generation_g%d.json"
## Environment variable that makes the golden test rewrite the file.
const UPDATE_ENV: String = "UPDATE_GOLDEN_SEEDS"
const LAYER: LayerData = preload("res://data/layers/layer_k.tres")
## Suffix of a mirrored chunk in the saved sequences.
const MIRRORED: String = "~m"
## One character per slot in the saved slot plans.
const EMPTY_SLOT: String = "."
## Character of each object in the saved slot plans (otherwise its first letter).
const SYMBOLS: Dictionary[StringName, String] = {
	&"coin_5": "v",
	&"coin_10": "x",
	&"chest": "w",
	&"chest_special": "b",
	&"choice_pedestal": "p",
}


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
	var library: ChunkLibrary = ChunkLibrary.from_layers([LAYER])
	var snapshot: Dictionary = {}
	for seed_text: String in SEEDS:
		snapshot[seed_text] = take(seed_text, library)
	return snapshot


## What one seed generates: its value (as text, JSON numbers are not 64-bit),
## the main path and the branches of Layer K, the fork rewards, and the slots
## and optional parts of every chunk.
static func take(seed_text: String, library: ChunkLibrary) -> Dictionary:
	var rng := WorldRng.new(SeedCode.to_int(seed_text))
	var plan: LayerPlan = LayerGenerator.new(library).generate(LAYER, rng)
	var branches: Dictionary = {}
	for branch: String in plan.branches:
		branches[branch] = describe(plan.branches[branch], library, rng)
	var rewards: Dictionary = {}
	for branch: String in plan.rewards:
		rewards[branch] = String(plan.rewards[branch])
	return {
		"code": SeedCode.from_text(seed_text),
		"value": str(rng.seed_value),
		"main": describe(plan.main, library, rng),
		"branches": branches,
		"rewards": rewards,
	}


## One line per chunk: "id[~m] slots [optional parts]".
static func describe(placements: Array, library: ChunkLibrary, rng: WorldRng) -> Array[String]:
	var lines: Array[String] = []
	for placement: ChunkPlacement in placements:
		var info: ChunkInfo = library.get_info(placement.chunk_id)
		var plan: Dictionary[StringName, StringName] = SlotFiller.plan(
			rng, LAYER, placement.key(), info.slots
		)
		var parts: Array[StringName] = LayerGenerator.pick_optional_parts(
			rng, placement.key(), info.optional_parts, LAYER.optional_part_chance
		)
		(
			lines
			. append(
				(
					(
						"%s%s %s %s"
						% [
							placement.chunk_id,
							MIRRORED if placement.mirrored else "",
							slots_to_text(info.slots, plan),
							",".join(parts),
						]
					)
					. strip_edges()
				)
			)
		)
	return lines


## One character per slot, in name order: the symbol of its object or EMPTY_SLOT.
static func slots_to_text(
	slots: Dictionary[StringName, StringName], plan: Dictionary[StringName, StringName]
) -> String:
	var text: String = ""
	for slot_name: StringName in slots:
		text += symbol(plan[slot_name]) if plan.has(slot_name) else EMPTY_SLOT
	return text


static func symbol(object_id: StringName) -> String:
	return SYMBOLS.get(object_id, String(object_id).left(1))
