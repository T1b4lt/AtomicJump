class_name LayerData
extends Resource
## Template of a layer (docs/05-world.md#generación-de-una-capa): its chunks,
## the sequence of chunk types of its main path, how its branches and its
## difficulty grow, the rewards of its forks, what fills its slots and the
## speed of the Decoherence. LayerGenerator turns it into a LayerPlan.

## Fork rewards that exist so far (the rest arrive with their systems,
## docs/03-run.md#tipos-de-recompensa-de-rama).
const REWARD_COINS: StringName = &"reward_coins"
const REWARD_KEY: StringName = &"reward_key"
const REWARD_ITEM: StringName = &"reward_item"

## Letter of the layer in the addresses of the rolls ("K").
@export var code: String = "K"
@export var name_key: String = ""
## Every chunk the layer can use (its ChunkLibrary).
@export var chunks: Array[PackedScene] = []
## Chunk type of each position of the main path, from the bottom up.
@export var template: Array[ChunkData.Type] = []
## Normal chunks of a branch before its reward chunk, rolled in [x, y].
@export var branch_length: Vector2i = Vector2i(1, 2)
## Difficulty of the first and the last position: it grows linearly between them.
@export var difficulty_range: Vector2i = Vector2i(1, 3)
## Weight of each fork reward. The two branches of a fork never share it.
@export var fork_rewards: Dictionary[StringName, float] = {}
## Chance that each optional part of a chunk appears.
@export_range(0.0, 1.0) var optional_part_chance: float = 0.5
## Chance that a slot of each kind is filled (Chunk.SLOT_*).
@export var slot_chances: Dictionary[StringName, float] = {}
## Weight of each object (Chunk.COIN…) in pickup and hazard slots.
@export var pickup_weights: Dictionary[StringName, float] = {}
@export var hazard_weights: Dictionary[StringName, float] = {}
## Weight of each container (Chunk.CHEST…) in container slots.
@export var container_weights: Dictionary[StringName, float] = {}
## Weight of each enemy (Chunk.ORBITAL_ELECTRON…) in ground and air enemy slots.
@export var enemy_ground_weights: Dictionary[StringName, float] = {}
@export var enemy_air_weights: Dictionary[StringName, float] = {}
## Base speed of the Decoherence in px/s (docs/03-run.md).
@export var threat_speed: float = 45.0


## Objects that can fill a slot kind, with their weights (empty: never filled yet).
func get_slot_objects(kind: StringName) -> Dictionary[StringName, float]:
	match kind:
		Chunk.SLOT_PICKUP:
			return pickup_weights
		Chunk.SLOT_HAZARD:
			return hazard_weights
		Chunk.SLOT_CONTAINER:
			return container_weights
		Chunk.SLOT_ENEMY_GROUND:
			return enemy_ground_weights
		Chunk.SLOT_ENEMY_AIR:
			return enemy_air_weights
	return {}


## Target difficulty of the main path position `index`.
func difficulty_at(index: int) -> int:
	if template.size() <= 1:
		return difficulty_range.x
	var progress: float = float(index) / (template.size() - 1)
	return roundi(lerpf(difficulty_range.x, difficulty_range.y, progress))
