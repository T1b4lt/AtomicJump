class_name LootRoller
extends RefCounted
## Addressed rolls of items and loot for a run (docs/08-seeds.md): which
## rarity (domain "rarity", improved by Amplitude without changing anything
## else), which item of a pool (rendezvous hashing among the items of that
## rarity, so unlocking an item only changes the rolls it wins) and what a
## container holds (domain "loot"). Items the player already carries are left
## out unless they are stackable. Chunks, containers and shops get one from
## the level.

var rng: WorldRng
var catalog: ItemCatalog
## The run, for its Amplitude and the items it carries (null: luck 0, nothing owned).
var run: RunState = null


## What a container gives: pickups (Chunk object ids) and maybe an item.
class LootResult:
	extends RefCounted
	var objects: Array[StringName] = []
	var item: ItemData = null


func _init(p_rng: WorldRng, p_catalog: ItemCatalog, p_run: RunState = null) -> void:
	rng = p_rng
	catalog = p_catalog
	run = p_run


func get_luck() -> float:
	return run.stats.get_value(Stats.LUCK) if run != null else 0.0


## Rarity of the roll at `address` with the run's Amplitude, at least `min_rarity`.
func roll_rarity(
	address: Array, min_rarity: ItemData.Rarity = ItemData.Rarity.COMMON
) -> ItemData.Rarity:
	var rarity: ItemData.Rarity = ItemRarity.from_roll(rng.roll(&"rarity", address), get_luck())
	return maxi(rarity, min_rarity) as ItemData.Rarity


## An item of `pool` and `kind` for the roll at `address` (domain `domain`),
## leaving out the carried ones and `exclude`. If no item of the rolled rarity
## is left it tries the rarities below it, then the ones above. Null if the
## pool is empty.
func roll_item(
	pool: StringName,
	address: Array,
	kind: ItemData.Kind = ItemData.Kind.PASSIVE,
	min_rarity: ItemData.Rarity = ItemData.Rarity.COMMON,
	exclude: Array[StringName] = [],
	domain: StringName = &"loot"
) -> ItemData:
	if catalog == null:
		return null
	var owned: Array[StringName] = []
	if run != null:
		owned = run.build.get_owned_ids()
	var candidates: Array[ItemData] = []
	for item: ItemData in catalog.get_pool(pool, kind):
		if item.id in exclude or (item.id in owned and not item.stackable):
			continue
		candidates.append(item)
	if candidates.is_empty():
		return null
	var rarity: ItemData.Rarity = roll_rarity(address, min_rarity)
	for tier: int in _rarity_order(rarity):
		var weights: Dictionary[StringName, float] = {}
		for item: ItemData in candidates:
			if item.rarity == tier:
				weights[item.id] = item.weight
		if not weights.is_empty():
			return catalog.get_item(rng.pick_weighted(weights, domain, address))
	return null


## What a container with `table` holds, for the roll at `address`.
func roll_loot(table: LootTable, address: Array) -> LootResult:
	var result := LootResult.new()
	var outcome: StringName = rng.pick_weighted(table.outcomes, &"loot", address)
	match outcome:
		LootTable.ITEM, LootTable.ACTIVE_ITEM:
			var kind: ItemData.Kind = (
				ItemData.Kind.ACTIVE if outcome == LootTable.ACTIVE_ITEM else ItemData.Kind.PASSIVE
			)
			result.item = roll_item(table.item_pool, address + [outcome], kind, table.min_rarity)
			if result.item == null:
				# Nothing left in the pool: the container gives photons instead
				result.objects.append(LootTable.FALLBACK_OBJECT)
		&"":
			pass
		_:
			var counts: Vector2i = table.get_count_range(outcome)
			var count: int = rng.roll_range(counts.x, counts.y, &"loot", address + [&"count"])
			for _i: int in count:
				result.objects.append(outcome)
	return result


## Rarities to try for a rolled one: itself, the ones below it, then the ones above.
static func _rarity_order(rarity: ItemData.Rarity) -> Array[int]:
	var order: Array[int] = []
	for tier: int in range(rarity, -1, -1):
		order.append(tier)
	for tier: int in range(rarity + 1, ItemData.Rarity.size()):
		order.append(tier)
	return order
