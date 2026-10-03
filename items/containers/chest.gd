class_name Chest
extends LootContainer
## Base of the containers that open once and spill what they hold
## (docs/06-economy.md#contenedores): the quantum well (CommonChest, paid with
## photons) and the bound electron (SpecialChest, opened with a positron).
## When it opens it rolls its LootTable at its slot's address (domain "loot"):
## pickups pop out above it and an item appears on a pedestal in its place.

signal opened

const ITEM_PEDESTAL_SCENE: PackedScene = preload("res://items/containers/item_pedestal.tscn")
## Prefix of the address of the loot roll (docs/08-seeds.md: ("loot", "chest", …)).
const ADDRESS_PREFIX: StringName = &"chest"

@export var loot: LootTable = null
## Px between the pickups that pop out, and how high they land.
@export var pickup_spread: float = 26.0
@export var pickup_height: float = 44.0
@export var pop_time: float = 0.3

var is_open: bool = false
## The pedestal of the item it held, once open.
var pedestal: ItemPedestal = null


## Address of its loot roll.
func get_loot_address() -> Array:
	return [ADDRESS_PREFIX] + address


## Opens it: rolls the loot and spills it. Only once.
func open() -> void:
	if is_open:
		return
	is_open = true
	var result: LootRoller.LootResult = LootRoller.LootResult.new()
	if roller != null and loot != null:
		result = roller.roll_loot(loot, get_loot_address())
	_play_open()
	# Opening can happen in a physics callback, when areas cannot be added
	_spill.call_deferred(result)
	opened.emit()


## The opening animation (subclasses).
func _play_open() -> void:
	pass


func _spill(result: LootRoller.LootResult) -> void:
	var count: int = result.objects.size()
	for i: int in count:
		if not PickupScenes.has(result.objects[i]):
			continue
		var pickup: Pickup = PickupScenes.instantiate(result.objects[i])
		var target := Vector2((i - (count - 1) / 2.0) * pickup_spread, -pickup_height)
		pickup.position = Vector2(0.0, -pickup_height / 3.0)
		add_child(pickup)
		var tween: Tween = pickup.create_tween().set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(pickup, ^"position", target, pop_time)
	if result.item != null:
		pedestal = ITEM_PEDESTAL_SCENE.instantiate()
		pedestal.set_item(result.item)
		add_child(pedestal)
