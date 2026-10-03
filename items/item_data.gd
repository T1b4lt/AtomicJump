class_name ItemData
extends Resource
## An item of the run (docs/07-items.md): an observable (passive) or an
## operator (active). Its behaviour is a list of ItemEffect resources, so a
## simple new item needs no code. The visible name and description are the
## translation keys ITEM_<ID>_NAME and ITEM_<ID>_DESC. The resources live in
## data/items/ and the catalog (ItemCatalog) lists them.

enum Kind { PASSIVE, ACTIVE }
## In game: Fundamental, Excitado, Resonante, Unificado (docs/07-items.md#rareza).
enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

## Pools (docs/07-items.md#pools): where the item can appear.
const POOL_CONTAINER: StringName = &"pool_container"
const POOL_SHOP: StringName = &"pool_shop"
const POOL_SPECIAL: StringName = &"pool_special"
const POOL_SECRET: StringName = &"pool_secret"
const POOL_BOSS: StringName = &"pool_boss"
const POOLS: Array[StringName] = [POOL_CONTAINER, POOL_SHOP, POOL_SPECIAL, POOL_SECRET, POOL_BOSS]
const NAME_KEY_FORMAT: String = "ITEM_%s_NAME"
const DESCRIPTION_KEY_FORMAT: String = "ITEM_%s_DESC"

## Stable code name (effective_mass…): saved, compared and used in the rolls.
@export var id: StringName = &""
@export var kind: Kind = Kind.PASSIVE
@export var rarity: Rarity = Rarity.COMMON
@export var pools: Array[StringName] = []
## Synergy tags (wave, photon, mass…): 3 with the same one give a transformation.
@export var tags: Array[StringName] = []
@export var icon: Texture2D = null
@export var effects: Array[ItemEffect] = []
## Relative chance among the items of its rarity in a pool.
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
## Whether it can appear again once owned (most items appear once per run).
@export var stackable: bool = false
## Operators: chunks to climb to recharge it after a use.
@export_range(0, 12) var charge_chunks: int = 0


func get_name_key() -> String:
	return NAME_KEY_FORMAT % String(id).to_upper()


func get_description_key() -> String:
	return DESCRIPTION_KEY_FORMAT % String(id).to_upper()


func is_active() -> bool:
	return kind == Kind.ACTIVE


func is_in_pool(pool: StringName) -> bool:
	return pool in pools
