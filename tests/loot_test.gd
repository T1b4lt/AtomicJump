extends GdUnitTestSuite

## Tests del catálogo de objetos y de las tiradas de botín (docs/07-items.md y
## docs/08-seeds.md): datos válidos, determinismo, pools, rarezas y monotonía.

const CATALOG: ItemCatalog = preload("res://data/items/item_catalog.tres")
const WILAS: CharacterData = preload("res://data/characters/wilas.tres")
const CHEST_COMMON: LootTable = preload("res://data/loot/chest_common.tres")
const CHEST_SPECIAL: LootTable = preload("res://data/loot/chest_special.tres")
const ADDRESSES: int = 300


func after_test() -> void:
	TranslationServer.set_locale(Settings.language)


func test_catalog_items_are_valid() -> void:
	TranslationServer.set_locale("es")
	var ids: Array[StringName] = []
	var passives: int = 0
	var actives: int = 0
	for item: ItemData in CATALOG.items:
		assert_bool(item.id.is_empty()).is_false()
		assert_bool(item.id in ids).override_failure_message("Repetido: %s" % item.id).is_false()
		ids.append(item.id)
		assert_object(item.icon).override_failure_message("%s sin icono" % item.id).is_not_null()
		assert_array(item.pools).is_not_empty()
		for pool: StringName in item.pools:
			assert_bool(pool in ItemData.POOLS).is_true()
		assert_array(item.effects).is_not_empty()
		for key: String in [item.get_name_key(), item.get_description_key()]:
			assert_str(tr(key)).override_failure_message(key).is_not_equal(key)
		if item.is_active():
			actives += 1
			assert_int(item.charge_chunks).is_greater(0)
		else:
			passives += 1
	assert_int(passives).is_greater_equal(15)
	assert_int(actives).is_greater_equal(2)


func test_catalog_has_a_transformation_reachable_by_tag() -> void:
	TranslationServer.set_locale("es")
	assert_array(CATALOG.transformations).is_not_empty()
	for transformation: TransformationData in CATALOG.transformations:
		var tagged: int = 0
		for item: ItemData in CATALOG.items:
			if transformation.tag in item.tags:
				tagged += 1
		assert_int(tagged).is_greater_equal(transformation.required)
		assert_str(tr(transformation.get_name_key())).is_not_equal(transformation.get_name_key())


func test_pools_are_sorted_by_id() -> void:
	var pool: Array[ItemData] = CATALOG.get_pool(ItemData.POOL_CONTAINER)
	assert_array(pool).is_not_empty()
	for i: int in range(1, pool.size()):
		assert_bool(String(pool[i - 1].id) < String(pool[i].id)).is_true()
		assert_bool(pool[i].is_active()).is_false()
	for item: ItemData in CATALOG.get_pool(ItemData.POOL_SHOP, ItemData.Kind.ACTIVE):
		assert_bool(item.is_active()).is_true()


func test_same_address_same_item() -> void:
	var first := LootRoller.new(WorldRng.new(42), CATALOG)
	var second := LootRoller.new(WorldRng.new(42), CATALOG)
	for i: int in 50:
		assert_object(first.roll_item(ItemData.POOL_CONTAINER, ["K", "main", i])).is_same(
			second.roll_item(ItemData.POOL_CONTAINER, ["K", "main", i])
		)


func test_rolled_items_come_from_the_pool_and_respect_the_minimum() -> void:
	var roller := LootRoller.new(WorldRng.new(7), CATALOG)
	for i: int in ADDRESSES:
		var item: ItemData = roller.roll_item(
			ItemData.POOL_SPECIAL, [i], ItemData.Kind.PASSIVE, ItemData.Rarity.RARE
		)
		assert_bool(item.is_in_pool(ItemData.POOL_SPECIAL)).is_true()
		assert_int(item.rarity).is_greater_equal(ItemData.Rarity.RARE)


func test_carried_and_excluded_items_are_left_out() -> void:
	var run := RunState.new("A", WILAS, CATALOG)
	var roller := LootRoller.new(run.world_rng, CATALOG, run)
	var mass: ItemData = CATALOG.get_item(&"effective_mass")
	run.add_item(mass)
	var exclude: Array[StringName] = [&"planck_constant"]
	for i: int in ADDRESSES:
		var item: ItemData = roller.roll_item(
			ItemData.POOL_CONTAINER, [i], ItemData.Kind.PASSIVE, ItemData.Rarity.COMMON, exclude
		)
		assert_str(item.id).is_not_equal(&"effective_mass")
		assert_str(item.id).is_not_equal(&"planck_constant")


func test_empty_pool_gives_nothing() -> void:
	var roller := LootRoller.new(WorldRng.new(1), CATALOG)
	assert_object(roller.roll_item(ItemData.POOL_BOSS, [1])).is_null()


func test_luck_only_improves_the_rarity_of_the_same_address() -> void:
	var unlucky := RunState.new("LUCK", WILAS, CATALOG)
	var lucky := RunState.new("LUCK", WILAS, CATALOG)
	lucky.stats.add_modifier(StatModifier.create(Stats.LUCK, StatModifier.Type.ADD, 60.0, &"t"))
	var base := LootRoller.new(unlucky.world_rng, CATALOG, unlucky)
	var better := LootRoller.new(lucky.world_rng, CATALOG, lucky)
	var improved: int = 0
	for i: int in ADDRESSES:
		var before: int = base.roll_rarity([i])
		var after: int = better.roll_rarity([i])
		assert_int(after).is_greater_equal(before)
		if after > before:
			improved += 1
	assert_int(improved).is_greater(0)


func test_common_chest_loot_is_deterministic_and_valid() -> void:
	var first := LootRoller.new(WorldRng.new(3), CATALOG)
	var second := LootRoller.new(WorldRng.new(3), CATALOG)
	var items: int = 0
	for i: int in ADDRESSES:
		var a: LootRoller.LootResult = first.roll_loot(CHEST_COMMON, ["chest", i])
		var b: LootRoller.LootResult = second.roll_loot(CHEST_COMMON, ["chest", i])
		assert_array(a.objects).is_equal(b.objects)
		assert_object(a.item).is_same(b.item)
		assert_bool(a.objects.is_empty() and a.item == null).is_false()
		for object_id: StringName in a.objects:
			assert_bool(PickupScenes.has(object_id)).is_true()
		if a.item != null:
			items += 1
			assert_bool(a.item.is_active()).is_false()
	assert_int(items).is_greater(0)


func test_special_chest_gives_a_rare_item_or_an_operator() -> void:
	var roller := LootRoller.new(WorldRng.new(5), CATALOG)
	var actives: int = 0
	for i: int in ADDRESSES:
		var result: LootRoller.LootResult = roller.roll_loot(CHEST_SPECIAL, ["chest", i])
		assert_object(result.item).is_not_null()
		assert_int(result.item.rarity).is_greater_equal(ItemData.Rarity.RARE)
		if result.item.is_active():
			actives += 1
	assert_int(actives).is_greater(0)
