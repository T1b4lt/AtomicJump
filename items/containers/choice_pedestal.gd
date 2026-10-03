class_name ChoicePedestal
extends LootContainer
## Superposition (docs/06-economy.md#contenedores, `choice_pedestal`): two
## observables on two pedestals under |ψ⟩. Taking one collapses the other.
## In a container slot it rolls its two items from `item_pool` (domain "loot",
## address ("choice", …slot, "a"/"b")); a reward chunk gives it its items.

signal chosen(item: ItemData)

const ITEM_PEDESTAL_SCENE: PackedScene = preload("res://items/containers/item_pedestal.tscn")
const ADDRESS_PREFIX: StringName = &"choice"
const SIDES: Array[StringName] = [&"a", &"b"]

@export var item_pool: StringName = ItemData.POOL_CONTAINER
## Px from the center to each pedestal.
@export var spacing: float = 48.0

var pedestals: Array[ItemPedestal] = []

@onready var _wave: Sprite2D = %Wave


func setup_slot(p_address: Array, p_roller: LootRoller, p_layer_index: int = 0) -> void:
	super(p_address, p_roller, p_layer_index)
	if roller == null:
		return
	var items: Array[ItemData] = []
	var exclude: Array[StringName] = []
	for side: StringName in SIDES:
		var item: ItemData = roller.roll_item(
			item_pool,
			[ADDRESS_PREFIX] + address + [side],
			ItemData.Kind.PASSIVE,
			ItemData.Rarity.COMMON,
			exclude
		)
		if item != null:
			items.append(item)
			exclude.append(item.id)
	set_items(items)


## Puts the items on the pedestals (one per item, up to two).
func set_items(items: Array[ItemData]) -> void:
	for pedestal: ItemPedestal in pedestals:
		pedestal.queue_free()
	pedestals.clear()
	for i: int in mini(items.size(), SIDES.size()):
		var pedestal: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate()
		pedestal.position = Vector2((i * 2 - 1) * spacing, 0.0)
		pedestal.set_item(items[i])
		pedestal.taken.connect(_on_pedestal_taken.bind(pedestal))
		add_child(pedestal)
		pedestals.append(pedestal)


func get_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for pedestal: ItemPedestal in pedestals:
		if pedestal.item != null:
			items.append(pedestal.item)
	return items


func _on_pedestal_taken(item: ItemData, taken_from: ItemPedestal) -> void:
	for pedestal: ItemPedestal in pedestals:
		if pedestal != taken_from:
			pedestal.collapse()
	_wave.visible = false
	chosen.emit(item)
