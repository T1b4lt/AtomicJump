class_name ShopInventory
extends RefCounted
## What an Exchange (Intercambio) sells (docs/06-economy.md#intercambio-tienda),
## from addressed rolls in the "shop" domain at the shop chunk's key: 2–3
## observables, an operator half of the times, an energy quantum, a positron
## and the reroll. Rerolling rolls the items again with the reroll count in
## their address, so the n-th reroll of a shop is the same in every run with
## the seed (for the same Amplitude and items carried).

enum Goods { ITEM, HEAL, KEY, REROLL }

## Prices of an observable and of an operator by rarity (ItemData.Rarity order).
const ITEM_PRICES: Array[int] = [15, 20, 25, 30]
const ACTIVE_PRICES: Array[int] = [25, 30, 35, 40]
## What every price grows per layer index.
const PRICE_PER_LAYER: int = 5
const HEAL_PRICE: int = 8
const KEY_PRICE: int = 12
## First reroll; every use doubles it.
const REROLL_PRICE: int = 5
const ITEM_COUNT: Vector2i = Vector2i(2, 3)
const ACTIVE_CHANCE: float = 0.5
const DOMAIN: StringName = &"shop"
## Coherence of the energy quantum sold.
const HEAL_AMOUNT: float = 20.0


## One thing on sale.
class Offer:
	extends RefCounted
	var goods: Goods = Goods.ITEM
	var item: ItemData = null
	var price: int = 0
	var sold: bool = false

	static func create(p_goods: Goods, p_price: int, p_item: ItemData = null) -> Offer:
		var offer := Offer.new()
		offer.goods = p_goods
		offer.price = p_price
		offer.item = p_item
		return offer


static func item_price(item: ItemData, layer_index: int = 0) -> int:
	var prices: Array[int] = ACTIVE_PRICES if item.is_active() else ITEM_PRICES
	return prices[item.rarity] + PRICE_PER_LAYER * layer_index


static func reroll_price(rerolls: int) -> int:
	return REROLL_PRICE * (1 << rerolls)


## Everything on sale at the shop of `key`: the items first, then the energy
## quantum, the positron and the reroll.
static func roll(roller: LootRoller, key: Array, layer_index: int = 0) -> Array[Offer]:
	var offers: Array[Offer] = roll_items(roller, key, layer_index)
	offers.append(Offer.create(Goods.HEAL, HEAL_PRICE + PRICE_PER_LAYER * layer_index))
	offers.append(Offer.create(Goods.KEY, KEY_PRICE + PRICE_PER_LAYER * layer_index))
	offers.append(Offer.create(Goods.REROLL, reroll_price(0)))
	return offers


## The observables and the operator, for `rerolls` rerolls done (0: the first stock).
static func roll_items(
	roller: LootRoller, key: Array, layer_index: int = 0, rerolls: int = 0
) -> Array[Offer]:
	var offers: Array[Offer] = []
	var rng: WorldRng = roller.rng
	var reroll_key: Array = [&"reroll", rerolls] if rerolls > 0 else []
	var count: int = rng.roll_range(ITEM_COUNT.x, ITEM_COUNT.y, DOMAIN, key + [&"count"])
	var exclude: Array[StringName] = []
	for i: int in count:
		var item: ItemData = roller.roll_item(
			ItemData.POOL_SHOP,
			key + [&"item", i] + reroll_key,
			ItemData.Kind.PASSIVE,
			ItemData.Rarity.COMMON,
			exclude,
			DOMAIN
		)
		if item != null:
			exclude.append(item.id)
			offers.append(Offer.create(Goods.ITEM, item_price(item, layer_index), item))
	if rng.chance(ACTIVE_CHANCE, DOMAIN, key + [&"active"]):
		var active: ItemData = roller.roll_item(
			ItemData.POOL_SHOP,
			key + [&"active"] + reroll_key,
			ItemData.Kind.ACTIVE,
			ItemData.Rarity.COMMON,
			[],
			DOMAIN
		)
		if active != null:
			offers.append(Offer.create(Goods.ITEM, item_price(active, layer_index), active))
	return offers
