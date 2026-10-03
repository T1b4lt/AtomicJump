class_name LootTable
extends Resource
## What a container can hold (docs/06-economy.md#contenedores): outcomes with
## their weights, picked with an addressed roll. An outcome is a Chunk object
## id (coin, key, heal_pickup…), ITEM (an observable from `item_pool`) or
## ACTIVE_ITEM (an operator from `item_pool`). The resources live in data/loot/.

const ITEM: StringName = &"item"
const ACTIVE_ITEM: StringName = &"active_item"
## Photons given instead of an item when the pool is empty (Chunk.COIN: the
## Chunk script loads the container scenes, so it is not referenced here).
const FALLBACK_OBJECT: StringName = &"coin"

@export var outcomes: Dictionary[StringName, float] = {}
## How many of a pickup outcome appear, rolled in [x, y] (1 if missing).
@export var counts: Dictionary[StringName, Vector2i] = {}
@export var item_pool: StringName = ItemData.POOL_CONTAINER
## Lowest rarity of the observables (the bound electron gives rare or better).
@export var min_rarity: ItemData.Rarity = ItemData.Rarity.COMMON


func get_count_range(outcome: StringName) -> Vector2i:
	return counts.get(outcome, Vector2i.ONE)
