class_name Shop
extends Node2D
## The Exchange (Intercambio, docs/06-economy.md#intercambio-tienda): the Pión
## and a row of ShopStands with the ShopInventory of its chunk. Buying pays
## photons from the player's run: an item goes to the build (an operator
## bought while carrying one leaves the old one on a pedestal), the energy
## quantum heals (only when hurt) and the positron adds one. The reroll rolls
## the unsold items again and doubles its price. The chunk calls setup()
## before it enters the tree; its origin is on the shelf's surface.

signal bought(offer: ShopInventory.Offer)
signal rerolled(count: int)

const STAND_SCENE: PackedScene = preload("res://items/shop/shop_stand.tscn")
const ITEM_PEDESTAL_SCENE: PackedScene = preload("res://items/containers/item_pedestal.tscn")

## Px between stands.
@export var spacing: float = 88.0
## Px from the first stand to the Pión.
@export var shopkeeper_gap: float = 84.0

var key: Array = []
var roller: LootRoller = null
var layer_index: int = 0
var rerolls: int = 0
var stands: Array[ShopStand] = []
var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	var breathe: float = 1.0 + 0.04 * sin(TAU * _time / 1.4)
	get_shopkeeper().scale = Vector2(breathe, 1.0 / breathe) * 0.5


## The Pión's sprite (also reachable before the shop enters the tree).
func get_shopkeeper() -> Sprite2D:
	return get_node(^"%Shopkeeper") as Sprite2D


## Rolls the inventory of the shop at `key` and puts its stands.
func setup(p_key: Array, p_roller: LootRoller, p_layer_index: int = 0) -> void:
	key = p_key
	roller = p_roller
	layer_index = p_layer_index
	rerolls = 0
	set_offers(ShopInventory.roll(roller, key, layer_index))


func set_offers(offers: Array[ShopInventory.Offer]) -> void:
	for stand: ShopStand in stands:
		stand.queue_free()
	stands.clear()
	var first_x: float = -(offers.size() - 1) * spacing / 2.0
	for i: int in offers.size():
		var stand: ShopStand = STAND_SCENE.instantiate()
		stand.position = Vector2(first_x + i * spacing, 0.0)
		stand.set_offer(offers[i])
		stand.buy_requested.connect(_on_buy_requested)
		add_child(stand)
		stands.append(stand)
	get_shopkeeper().position.x = first_x - shopkeeper_gap


func get_offers() -> Array[ShopInventory.Offer]:
	var offers: Array[ShopInventory.Offer] = []
	for stand: ShopStand in stands:
		offers.append(stand.offer)
	return offers


## Buys the goods of a stand for the player. Returns whether it was bought.
func buy(stand: ShopStand, player: Player) -> bool:
	var offer: ShopInventory.Offer = stand.offer
	var run: RunState = player.run
	if offer == null or offer.sold or run == null:
		return false
	if offer.goods == ShopInventory.Goods.HEAL and run.is_hp_full():
		stand.flash_price()
		return false
	if not run.spend_coins(offer.price):
		stand.flash_price()
		return false
	match offer.goods:
		ShopInventory.Goods.ITEM:
			stand.mark_sold()
			var replaced: ItemData = run.add_item(offer.item)
			if replaced != null:
				_drop_item(replaced, stand.position)
		ShopInventory.Goods.HEAL:
			stand.mark_sold()
			run.heal(ShopInventory.HEAL_AMOUNT)
		ShopInventory.Goods.KEY:
			stand.mark_sold()
			run.add_keys(1)
		ShopInventory.Goods.REROLL:
			_reroll(stand)
	bought.emit(offer)
	return true


## New items for the unsold item stands; the reroll costs double next time.
func _reroll(reroll_stand: ShopStand) -> void:
	rerolls += 1
	var fresh: Array[ShopInventory.Offer] = ShopInventory.roll_items(
		roller, key, layer_index, rerolls
	)
	var index: int = 0
	for stand: ShopStand in stands:
		if stand.offer.goods != ShopInventory.Goods.ITEM or stand.offer.sold:
			continue
		if index < fresh.size():
			stand.set_offer(fresh[index])
			index += 1
	var next := ShopInventory.Offer.create(
		ShopInventory.Goods.REROLL, ShopInventory.reroll_price(rerolls)
	)
	reroll_stand.set_offer(next)
	rerolled.emit(rerolls)


## The operator replaced by one bought waits on a pedestal in front of the stand.
func _drop_item(item: ItemData, at: Vector2) -> void:
	var pedestal: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate()
	pedestal.set_item(item)
	pedestal.position = at
	add_child.call_deferred(pedestal)


func _on_buy_requested(stand: ShopStand, player: Player) -> void:
	buy(stand, player)
