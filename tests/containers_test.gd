extends "res://tests/support/player_suite.gd"

## Tests de los contenedores, la tienda y el Estado fundamental
## (docs/06-economy.md): pozo cuántico, electrón ligado, pedestal, Superposición,
## Intercambio con reintento y la elección de descanso; y la interacción del
## jugador con ellos.

const CATALOG: ItemCatalog = preload("res://data/items/item_catalog.tres")
const COMMON_CHEST: PackedScene = preload("res://items/containers/common_chest.tscn")
const SPECIAL_CHEST: PackedScene = preload("res://items/containers/special_chest.tscn")
const ITEM_PEDESTAL: PackedScene = preload("res://items/containers/item_pedestal.tscn")
const CHOICE_PEDESTAL: PackedScene = preload("res://items/containers/choice_pedestal.tscn")
const SHOP_SCENE: PackedScene = preload("res://items/shop/shop.tscn")
const REST_SHRINE: PackedScene = preload("res://items/rest/rest_shrine.tscn")
const SHOP_KEY: Array = ["K", "main", 6]


func test_common_chest_costs_photons_by_layer_and_spills_its_loot() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var run: RunState = player.run
	var chest: CommonChest = _chest(COMMON_CHEST, run, 1)
	assert_int(chest.get_cost()).is_equal(chest.base_cost + chest.cost_per_layer)
	assert_bool(chest.try_open(player)).is_false()
	assert_bool(chest.is_open).is_false()
	run.add_coins(20)
	assert_bool(chest.try_open(player)).is_true()
	assert_int(run.coins).is_equal(20 - chest.get_cost())
	assert_bool(chest.try_open(player)).is_false()
	await get_tree().process_frame
	var expected: LootRoller.LootResult = LootRoller.new(run.world_rng, CATALOG, run).roll_loot(
		chest.loot, chest.get_loot_address()
	)
	var pickups: Array[Node] = chest.get_children().filter(
		func(node: Node) -> bool: return node is Pickup
	)
	assert_int(pickups.size()).is_equal(expected.objects.size())
	assert_bool(chest.pedestal != null).is_equal(expected.item != null)


func test_special_chest_needs_a_positron() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var run: RunState = player.run
	var chest: SpecialChest = _chest(SPECIAL_CHEST, run)
	assert_bool(chest.try_open(player)).is_false()
	run.add_keys(1)
	assert_bool(chest.try_open(player)).is_true()
	assert_int(run.keys).is_equal(0)
	await get_tree().process_frame
	assert_object(chest.pedestal).is_not_null()
	assert_int(chest.pedestal.item.rarity).is_greater_equal(ItemData.Rarity.RARE)


func test_pedestal_gives_its_item_and_keeps_a_swapped_operator() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var run: RunState = player.run
	var pedestal: ItemPedestal = ITEM_PEDESTAL.instantiate()
	pedestal.set_item(CATALOG.get_item(&"effective_mass"))
	_world.add_child(pedestal)
	pedestal.take(player)
	assert_bool(run.build.has_item(&"effective_mass")).is_true()
	assert_bool(pedestal.is_empty()).is_true()
	assert_bool(pedestal.get_interactable().enabled).is_false()
	run.add_item(CATALOG.get_item(&"zeno_effect"))
	var other: ItemPedestal = ITEM_PEDESTAL.instantiate()
	other.set_item(CATALOG.get_item(&"collapse"))
	_world.add_child(other)
	other.take(player)
	assert_object(run.build.active_item).is_same(CATALOG.get_item(&"collapse"))
	assert_object(other.item).is_same(CATALOG.get_item(&"zeno_effect"))
	assert_bool(other.get_interactable().enabled).is_true()


func test_superposition_collapses_the_other_item() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var run: RunState = player.run
	var choice: ChoicePedestal = CHOICE_PEDESTAL.instantiate()
	choice.setup_slot(["K", "main", 2, "slot_container_1"], _roller(run))
	_world.add_child(choice)
	var items: Array[ItemData] = choice.get_items()
	assert_int(items.size()).is_equal(2)
	assert_str(items[0].id).is_not_equal(items[1].id)
	choice.pedestals[1].take(player)
	assert_bool(run.build.has_item(items[1].id)).is_true()
	assert_bool(choice.pedestals[0].collapsed).is_true()
	assert_bool(choice.pedestals[0].get_interactable().enabled).is_false()
	assert_bool(run.build.has_item(items[0].id)).is_false()


func test_shop_inventory_follows_the_design() -> void:
	var roller: LootRoller = _roller(RunState.new("SHOP", WILAS, CATALOG))
	for index: int in 40:
		var key: Array = ["K", "main", index]
		var offers: Array[ShopInventory.Offer] = ShopInventory.roll(roller, key)
		var items: Array[ShopInventory.Offer] = offers.filter(
			func(o: ShopInventory.Offer) -> bool: return o.goods == ShopInventory.Goods.ITEM
		)
		var passives: int = (
			items.filter(func(o: ShopInventory.Offer) -> bool: return not o.item.is_active()).size()
		)
		assert_int(passives).is_between(ShopInventory.ITEM_COUNT.x, ShopInventory.ITEM_COUNT.y)
		assert_int(items.size() - passives).is_between(0, 1)
		var ids: Array[StringName] = []
		for offer: ShopInventory.Offer in items:
			assert_bool(offer.item.id in ids).is_false()
			ids.append(offer.item.id)
			assert_bool(offer.item.is_in_pool(ItemData.POOL_SHOP)).is_true()
			assert_int(offer.price).is_between(15, 40)
		var tail: Array = offers.slice(items.size()).map(
			func(o: ShopInventory.Offer) -> int: return o.goods
		)
		assert_array(tail).is_equal(
			[ShopInventory.Goods.HEAL, ShopInventory.Goods.KEY, ShopInventory.Goods.REROLL]
		)
		# The same shop of the same seed sells the same
		var again: Array[ShopInventory.Offer] = ShopInventory.roll(roller, key)
		for i: int in offers.size():
			assert_object(again[i].item).is_same(offers[i].item)


func test_buying_pays_and_gives_the_goods() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var run: RunState = player.run
	var shop: Shop = _shop(run)
	var item_stand: ShopStand = shop.stands[0]
	assert_bool(shop.buy(item_stand, player)).is_false()
	run.add_coins(100)
	var price: int = item_stand.offer.price
	assert_bool(shop.buy(item_stand, player)).is_true()
	assert_int(run.coins).is_equal(100 - price)
	assert_bool(run.build.has_item(item_stand.offer.item.id)).is_true()
	assert_bool(item_stand.offer.sold).is_true()
	assert_bool(shop.buy(item_stand, player)).is_false()
	var heal_stand: ShopStand = _stand(shop, ShopInventory.Goods.HEAL)
	assert_bool(shop.buy(heal_stand, player)).is_false()
	run.take_damage(50.0)
	assert_bool(shop.buy(heal_stand, player)).is_true()
	assert_float(run.hp).is_equal(50.0 + ShopInventory.HEAL_AMOUNT)
	assert_bool(shop.buy(_stand(shop, ShopInventory.Goods.KEY), player)).is_true()
	assert_int(run.keys).is_equal(1)


func test_reroll_changes_the_unsold_items_and_doubles_its_price() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var run: RunState = player.run
	run.add_coins(500)
	var shop: Shop = _shop(run)
	var reroll: ShopStand = _stand(shop, ShopInventory.Goods.REROLL)
	assert_int(reroll.offer.price).is_equal(ShopInventory.REROLL_PRICE)
	var before: Array = shop.get_offers().map(
		func(o: ShopInventory.Offer) -> Variant: return o.item
	)
	assert_bool(shop.buy(reroll, player)).is_true()
	assert_int(shop.rerolls).is_equal(1)
	assert_int(reroll.offer.price).is_equal(ShopInventory.REROLL_PRICE * 2)
	assert_bool(reroll.offer.sold).is_false()
	var after: Array = shop.get_offers().map(func(o: ShopInventory.Offer) -> Variant: return o.item)
	assert_array(after).is_not_equal(before)
	# The first reroll of this shop is always the same for the seed
	var expected: Array[ShopInventory.Offer] = ShopInventory.roll_items(
		_roller(run), SHOP_KEY, 0, 1
	)
	assert_object(shop.stands[0].offer.item).is_same(expected[0].item)


func test_rest_shrine_heals_or_raises_the_max_coherence() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var run: RunState = player.run
	run.take_damage(60.0)
	var shrine: RestShrine = REST_SHRINE.instantiate()
	_world.add_child(shrine)
	assert_bool(shrine.choose(RestShrine.HEAL, player)).is_true()
	assert_float(run.hp).is_equal(40.0 + 100.0 * RestShrine.HEAL_FRACTION)
	assert_bool(shrine.choose(RestShrine.MAX_HP, player)).is_false()
	assert_bool(shrine.get_choice_node(RestShrine.MAX_HP).used).is_true()
	var other: RestShrine = REST_SHRINE.instantiate()
	_world.add_child(other)
	other.choose(RestShrine.MAX_HP, player)
	assert_float(run.get_max_hp()).is_equal(110.0)
	assert_float(run.hp).is_equal(90.0)


func test_player_interacts_with_the_closest_interactable() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var near: ItemPedestal = ITEM_PEDESTAL.instantiate()
	near.set_item(CATALOG.get_item(&"effective_mass"))
	near.position = player.position + Vector2(10.0, 20.0)
	_world.add_child(near)
	var far: ItemPedestal = ITEM_PEDESTAL.instantiate()
	far.set_item(CATALOG.get_item(&"linear_momentum"))
	far.position = player.position + Vector2(36.0, 20.0)
	_world.add_child(far)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_step(player)
	assert_object(player.focused_interactable).is_same(near.get_interactable())
	assert_str(near.get_interactable().get_prompt_text()).contains(tr(&"ITEM_EFFECTIVE_MASS_NAME"))
	assert_str(far.get_interactable().get_prompt_text()).is_empty()
	var input := PlayerInput.new()
	input.interact_pressed = true
	_step(player, input)
	assert_bool(player.run.build.has_item(&"effective_mass")).is_true()
	assert_bool(player.run.build.has_item(&"linear_momentum")).is_false()
	# The used pedestal is empty: the focus goes to the other one
	assert_object(player.focused_interactable).is_same(far.get_interactable())


func _roller(run: RunState) -> LootRoller:
	return LootRoller.new(run.world_rng, CATALOG, run)


func _chest(scene: PackedScene, run: RunState, layer_index: int = 0) -> Chest:
	var chest: Chest = scene.instantiate()
	chest.setup_slot(["K", "main", 1, "slot_container_1"], _roller(run), layer_index)
	_world.add_child(chest)
	return chest


func _shop(run: RunState) -> Shop:
	var shop: Shop = SHOP_SCENE.instantiate()
	shop.setup(SHOP_KEY, _roller(run))
	_world.add_child(shop)
	return shop


func _stand(shop: Shop, goods: ShopInventory.Goods) -> ShopStand:
	for stand: ShopStand in shop.stands:
		if stand.offer.goods == goods:
			return stand
	return null


func test_chunk_fills_container_slots_with_their_address() -> void:
	var run := RunState.new("SLOTS", WILAS, CATALOG)
	var chunk: Chunk = auto_free(Chunk.new())
	var slot := Marker2D.new()
	slot.name = "slot_container_1"
	var slots := Node2D.new()
	slots.name = "Slots"
	slots.add_child(slot)
	chunk.add_child(slots)
	var plan: Dictionary[StringName, StringName] = {&"slot_container_1": Chunk.CHEST}
	chunk.fill_slots(plan, ["K", "main", 3], run.world_rng, 2, _roller(run))
	var chest: CommonChest = chunk.get_child(chunk.get_child_count() - 1) as CommonChest
	assert_object(chest).is_not_null()
	assert_array(chest.address).is_equal(["K", "main", 3, &"slot_container_1"])
	assert_int(chest.layer_index).is_equal(2)
	assert_object(chest.roller).is_not_null()


func test_item_reward_is_a_pedestal_or_a_superposition() -> void:
	var run := RunState.new("REWARDS", WILAS, CATALOG)
	var kinds: Dictionary[String, int] = {}
	for index: int in 30:
		var chunk: Chunk = auto_free(Chunk.new())
		var markers := Node2D.new()
		markers.name = "Markers"
		var marker := Marker2D.new()
		marker.name = String(Chunk.REWARD_MARKER)
		markers.add_child(marker)
		chunk.add_child(markers)
		chunk.set_rolls(run.world_rng, 0, _roller(run))
		chunk.spawn_reward(LayerData.REWARD_ITEM, ["K", "1/L", index])
		var reward: Node = chunk.get_child(chunk.get_child_count() - 1)
		assert_bool(reward is ItemPedestal or reward is ChoicePedestal).is_true()
		kinds[reward.get_class() + str(reward is ChoicePedestal)] = 1
		if reward is ItemPedestal:
			assert_object((reward as ItemPedestal).item).is_not_null()
	assert_int(kinds.size()).is_equal(2)
