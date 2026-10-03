extends GdUnitTestSuite

## Tests de reproducibilidad de la generación (docs/08-seeds.md): semillas
## doradas, monotonía e independencia del orden.

const SLOT_COUNT: int = 19
const CHUNKS: int = 30


func test_golden_seeds() -> void:
	var path: String = GoldenSeeds.file_path()
	if GoldenSeeds.should_update():
		GoldenSeeds.save(GoldenSeeds.take_all())
	if not FileAccess.file_exists(path):
		fail("Falta %s: genéralo con %s=1" % [path, GoldenSeeds.UPDATE_ENV])
		return
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	# Ida y vuelta por JSON para comparar los mismos tipos que el fichero
	var current: Dictionary = JSON.parse_string(JSON.stringify(GoldenSeeds.take_all()))
	assert_array(saved.keys()).contains_exactly_in_any_order(current.keys())
	for seed_text: String in current:
		(
			assert_dict(current[seed_text])
			. override_failure_message(
				(
					(
						"La semilla %s ya no genera lo mismo: si el cambio es intencionado, sube "
						+ "GENERATION_VERSION y regenera las semillas doradas"
					)
					% seed_text
				)
			)
			. is_equal(saved[seed_text])
		)


func test_same_seed_same_run() -> void:
	var first := RunState.new("K7QX-2MPA", RunManager.DEFAULT_CHARACTER)
	var second := RunState.new("k7qx2mpa", RunManager.DEFAULT_CHARACTER)
	assert_array(_column(first.world_rng)).is_equal(_column(second.world_rng))
	var other := RunState.new("K7QX-2MPB", RunManager.DEFAULT_CHARACTER)
	assert_array(_column(other.world_rng)).is_not_equal(_column(first.world_rng))


func test_generation_does_not_depend_on_the_order() -> void:
	var expected: Array = _column(WorldRng.new(99))
	var rng := WorldRng.new(99)
	var backwards: Array = []
	backwards.resize(CHUNKS)
	for index: int in range(CHUNKS - 1, -1, -1):
		# Tiradas ajenas entre medias (como haría una partícula) no desplazan nada
		rng.roll(&"combat", [index])
		rng.local_rng(&"ai", [index]).randi()
		backwards[index] = _chunk(rng, index)
	assert_array(backwards).is_equal(expected)


func test_global_rng_does_not_affect_generation() -> void:
	seed(1)
	var first: Array = _column(WorldRng.new(99))
	seed(2)
	randi()
	assert_array(_column(WorldRng.new(99))).is_equal(first)


func test_raising_a_probability_only_adds_active_slots() -> void:
	var rng := WorldRng.new(SeedCode.to_int("K7QX-2MPA"))
	var previous: Array[int] = []
	for probability: float in [0.0, 0.1, 0.25, 0.5, 0.9, 1.0]:
		var active: Array[int] = []
		for slot: int in 500:
			if rng.chance(probability, &"slot", ["K", "main", 3, slot]):
				active.append(slot)
		assert_array(active).contains(previous)
		assert_int(active.size()).is_greater_equal(previous.size())
		previous = active
	assert_int(previous.size()).is_equal(500)


func test_adding_a_candidate_only_changes_the_picks_it_wins() -> void:
	var rng := WorldRng.new(SeedCode.to_int("K7QX-2MPA"))
	var pool: Dictionary[StringName, float] = {&"a": 1.0, &"b": 2.0, &"c": 1.0}
	var bigger: Dictionary[StringName, float] = pool.duplicate()
	bigger[&"new"] = 1.0
	var changed: int = 0
	for slot: int in 500:
		var before: StringName = rng.pick_weighted(pool, &"loot", [slot])
		var after: StringName = rng.pick_weighted(bigger, &"loot", [slot])
		if after != before:
			assert_str(after).is_equal(&"new")
			changed += 1
	assert_int(changed).is_greater(0)


func test_object_plan_gives_each_object_its_own_slot() -> void:
	var rng := WorldRng.new(5)
	for index: int in CHUNKS:
		var plan: Array[StringName] = PrototypeGenerator.plan_objects(rng, index, SLOT_COUNT)
		assert_int(plan.size()).is_equal(SLOT_COUNT)
		assert_int(plan.count(Chunk.COIN)).is_between(1, 5)
		assert_int(plan.count(Chunk.SPIKE)).is_between(0, 1)
		assert_int(plan.count(Chunk.KEY)).is_between(0, 1)


func test_object_plan_with_fewer_slots_than_objects() -> void:
	var rng := WorldRng.new(5)
	for index: int in CHUNKS:
		assert_int(PrototypeGenerator.plan_objects(rng, index, 2).size()).is_equal(2)
		assert_array(PrototypeGenerator.plan_objects(rng, index, 0)).is_empty()


func test_every_chunk_can_be_picked() -> void:
	assert_array(PrototypeGenerator.CHUNK_WEIGHTS.keys()).contains_exactly_in_any_order(
		PrototypeGenerator.CHUNK_SCENES.keys()
	)
	var rng := WorldRng.new(5)
	var seen: Dictionary[StringName, bool] = {}
	for index: int in range(1, 200):
		seen[PrototypeGenerator.pick_chunk(rng, index)] = true
	assert_int(seen.size()).is_equal(PrototypeGenerator.CHUNK_SCENES.size())
	assert_str(PrototypeGenerator.pick_chunk(rng, 0)).is_equal(PrototypeGenerator.INITIAL_CHUNK)


func test_chunk_places_the_plan_on_its_slots() -> void:
	var chunk: Chunk = auto_free(PrototypeGenerator.CHUNK_SCENES[&"platform_1"].instantiate())
	add_child(chunk)
	var plan: Array[StringName] = []
	plan.resize(chunk.get_slot_count())
	plan.fill(&"")
	plan[0] = Chunk.COIN
	plan[2] = Chunk.KEY
	var before: int = chunk.get_child_count()
	chunk.place_objects(plan)
	assert_int(chunk.get_child_count()).is_equal(before + 2)
	var slot: Node2D = chunk.get_node(^"%ObjectPlaceholders").get_child(2)
	var key: Node2D = chunk.get_child(chunk.get_child_count() - 1)
	assert_vector(key.position).is_equal(slot.position)


## Chunk ids and object plans of the first CHUNKS chunks, in order.
func _column(rng: WorldRng) -> Array:
	var column: Array = []
	for index: int in CHUNKS:
		column.append(_chunk(rng, index))
	return column


func _chunk(rng: WorldRng, index: int) -> Array:
	return [
		PrototypeGenerator.pick_chunk(rng, index),
		PrototypeGenerator.plan_objects(rng, index, SLOT_COUNT),
	]
