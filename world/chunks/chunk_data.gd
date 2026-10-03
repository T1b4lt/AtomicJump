@tool
class_name ChunkData
extends Resource
## Metadata of a chunk (docs/05-world.md#reglas-de-diseño-de-un-tramo), saved
## in its scene as the `data` of the Chunk root. The layers a chunk appears in
## are the LayerData that list it; its entries, exits, slots and optional parts
## are read from the scene's markers and nodes (see Chunk).

enum Type { NORMAL, LAYER_START, FORK, REWARD, SHOP, REST, CHALLENGE, SECRET, BOSS }

## Types where the Decoherence stops (docs/03-run.md).
const SAFE_TYPES: Array[Type] = [Type.LAYER_START, Type.SHOP, Type.REST, Type.BOSS]
const MIN_DIFFICULTY: int = 1
const MAX_DIFFICULTY: int = 5
## Rows of a chunk one screen high (22 × 32 px = 704 px).
const DEFAULT_HEIGHT_TILES: int = 22

## Stable id: it is part of the generation, so renaming the file changes nothing.
@export var id: StringName = &""
@export var type: Type = Type.NORMAL
@export_range(MIN_DIFFICULTY, MAX_DIFFICULTY) var difficulty: int = MIN_DIFFICULTY
## Relative chance of being picked among the valid chunks of a position.
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
## Whether the generator may mirror it horizontally.
@export var mirrorable: bool = true
## Height in tiles of 32 px (bosses may be taller than a screen).
@export_range(1, 64) var height_tiles: int = DEFAULT_HEIGHT_TILES


func is_safe() -> bool:
	return type in SAFE_TYPES
