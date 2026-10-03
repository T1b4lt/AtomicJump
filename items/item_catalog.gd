class_name ItemCatalog
extends Resource
## Every item and transformation of the game (data/items/item_catalog.tres).
## Pools are read from here sorted by id, so the order of the list never
## changes a roll (docs/08-seeds.md#elección-dentro-de-un-pool).

@export var items: Array[ItemData] = []
@export var transformations: Array[TransformationData] = []


func get_item(id: StringName) -> ItemData:
	for item: ItemData in items:
		if item.id == id:
			return item
	return null


## Items of a pool and a kind, sorted by id.
func get_pool(pool: StringName, kind: ItemData.Kind = ItemData.Kind.PASSIVE) -> Array[ItemData]:
	var found: Array[ItemData] = []
	for item: ItemData in items:
		if item.kind == kind and item.is_in_pool(pool):
			found.append(item)
	found.sort_custom(func(a: ItemData, b: ItemData) -> bool: return String(a.id) < String(b.id))
	return found
