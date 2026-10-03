extends GdUnitTestSuite

## Tests de las rarezas (docs/07-items.md#rareza): probabilidades base y efecto
## monótono de la Amplitud.


func test_base_chances_match_the_design() -> void:
	assert_float(ItemRarity.chance_at_least(ItemData.Rarity.COMMON)).is_equal(1.0)
	assert_float(ItemRarity.chance_at_least(ItemData.Rarity.RARE)).is_equal_approx(0.35, 1e-6)
	assert_float(ItemRarity.chance_at_least(ItemData.Rarity.EPIC)).is_equal_approx(0.08, 1e-6)
	assert_float(ItemRarity.chance_at_least(ItemData.Rarity.LEGENDARY)).is_equal_approx(0.01, 1e-6)


func test_rolls_split_by_the_base_chances() -> void:
	assert_int(ItemRarity.from_roll(0.005)).is_equal(ItemData.Rarity.LEGENDARY)
	assert_int(ItemRarity.from_roll(0.05)).is_equal(ItemData.Rarity.EPIC)
	assert_int(ItemRarity.from_roll(0.2)).is_equal(ItemData.Rarity.RARE)
	assert_int(ItemRarity.from_roll(0.5)).is_equal(ItemData.Rarity.COMMON)
	assert_int(ItemRarity.from_roll(0.999)).is_equal(ItemData.Rarity.COMMON)


func test_luck_only_improves_the_same_roll() -> void:
	for step: int in 200:
		var roll: float = step / 200.0
		var previous: int = ItemRarity.from_roll(roll, 0.0)
		for luck: float in [10.0, 25.0, 50.0, 100.0]:
			var rarity: int = ItemRarity.from_roll(roll, luck)
			assert_int(rarity).is_greater_equal(previous)
			previous = rarity


func test_luck_raises_every_chance() -> void:
	for rarity: int in [ItemData.Rarity.RARE, ItemData.Rarity.EPIC, ItemData.Rarity.LEGENDARY]:
		var base: float = ItemRarity.chance_at_least(rarity as ItemData.Rarity, 0.0)
		var lucky: float = ItemRarity.chance_at_least(rarity as ItemData.Rarity, 50.0)
		assert_float(lucky).is_greater(base)
		assert_float(lucky).is_less(1.0)
