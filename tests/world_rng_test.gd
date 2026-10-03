extends GdUnitTestSuite

## Tests de las tiradas direccionadas: deterministas, en rango e independientes.

## Samples of the statistical checks; the bounds below are for 2000.
const SAMPLES: int = 2000


func test_rolls_are_pure_functions_of_seed_and_address() -> void:
	var a := WorldRng.new(42)
	var b := WorldRng.new(42)
	assert_float(a.roll(&"layout", ["K", 1])).is_equal(b.roll(&"layout", ["K", 1]))
	assert_int(a.roll_int(&"slot", ["K", 1, "x"])).is_equal(b.roll_int(&"slot", ["K", 1, "x"]))
	# Otra semilla, otro dominio u otra clave dan otra tirada
	var base: int = a.roll_int(&"layout", ["K", 1])
	assert_int(WorldRng.new(43).roll_int(&"layout", ["K", 1])).is_not_equal(base)
	assert_int(a.roll_int(&"slot", ["K", 1])).is_not_equal(base)
	assert_int(a.roll_int(&"layout", ["K", 2])).is_not_equal(base)


func test_roll_is_in_unit_range_and_spread() -> void:
	var rng := WorldRng.new(7)
	var below_half: int = 0
	for i: int in SAMPLES:
		var value: float = rng.roll(&"test", [i])
		assert_float(value).is_greater_equal(0.0)
		assert_float(value).is_less(1.0)
		if value < 0.5:
			below_half += 1
	assert_int(below_half).is_between(900, 1100)


func test_roll_range_covers_the_whole_range() -> void:
	var rng := WorldRng.new(7)
	var seen: Dictionary[int, bool] = {}
	for i: int in SAMPLES:
		var value: int = rng.roll_range(-2, 3, &"test", [i])
		assert_int(value).is_between(-2, 3)
		seen[value] = true
	assert_int(seen.size()).is_equal(6)
	assert_int(rng.roll_range(5, 5, &"test")).is_equal(5)


func test_pick_weighted_follows_the_weights() -> void:
	var rng := WorldRng.new(7)
	var weights: Dictionary[StringName, float] = {&"a": 3.0, &"b": 1.0, &"never": 0.0}
	var counts: Dictionary[StringName, int] = {&"a": 0, &"b": 0}
	for i: int in SAMPLES:
		counts[rng.pick_weighted(weights, &"test", [i])] += 1
	assert_int(counts.size()).is_equal(2)
	assert_int(counts[&"a"]).is_between(1400, 1600)


func test_pick_weighted_ignores_the_dictionary_order() -> void:
	var rng := WorldRng.new(7)
	var forward: Dictionary[StringName, float] = {&"a": 1.0, &"b": 2.0, &"c": 0.5}
	var backward: Dictionary[StringName, float] = {&"c": 0.5, &"b": 2.0, &"a": 1.0}
	for i: int in 200:
		assert_str(rng.pick_weighted(forward, &"test", [i])).is_equal(
			rng.pick_weighted(backward, &"test", [i])
		)


func test_pick_weighted_without_candidates() -> void:
	var rng := WorldRng.new(7)
	var empty: Dictionary[StringName, float] = {}
	var zero: Dictionary[StringName, float] = {&"a": 0.0}
	assert_str(rng.pick_weighted(empty, &"test")).is_empty()
	assert_str(rng.pick_weighted(zero, &"test")).is_empty()


func test_local_rng_is_stable() -> void:
	var first: RandomNumberGenerator = WorldRng.new(7).local_rng(&"shop", ["K", 1])
	var second: RandomNumberGenerator = WorldRng.new(7).local_rng(&"shop", ["K", 1])
	for i: int in 20:
		assert_int(first.randi()).is_equal(second.randi())


func test_shuffled_is_a_stable_permutation() -> void:
	var rng := WorldRng.new(7)
	var items: Array = range(20)
	var shuffled: Array = rng.shuffled(items, &"test")
	assert_array(shuffled).is_equal(rng.shuffled(items, &"test"))
	assert_array(shuffled).contains_exactly_in_any_order(items)
	assert_array(shuffled).is_not_equal(items)
	assert_array(items).is_equal(range(20))
