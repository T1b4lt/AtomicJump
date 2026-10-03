extends GdUnitTestSuite

## Tests de la generación de capas (docs/05-world.md y docs/08-seeds.md): semillas
## doradas, determinismo, independencia del orden, monotonía, plantilla y
## compatibilidad de entradas y salidas.

const LAYER: LayerData = preload("res://data/layers/layer_k.tres")
## Seeds checked by the structural tests.
const SEEDS: int = 150

var _library: ChunkLibrary = null
var _generator: LayerGenerator = null


func before() -> void:
	_library = ChunkLibrary.from_layers([LAYER])
	_generator = LayerGenerator.new(_library)


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


func test_same_seed_same_layer() -> void:
	var first := RunState.new("K7QX-2MPA", RunManager.DEFAULT_CHARACTER)
	var second := RunState.new("k7qx2mpa", RunManager.DEFAULT_CHARACTER)
	assert_array(_signature(first.world_rng)).is_equal(_signature(second.world_rng))
	var other := RunState.new("K7QX-2MPB", RunManager.DEFAULT_CHARACTER)
	assert_array(_signature(other.world_rng)).is_not_equal(_signature(first.world_rng))


func test_generation_does_not_depend_on_other_rolls() -> void:
	var expected: Array = _signature(WorldRng.new(99))
	var rng := WorldRng.new(99)
	# Rolls of other domains before generating (a particle, an enemy) shift nothing
	for i: int in 50:
		rng.roll(&"combat", [i])
		rng.local_rng(&"ai", [i]).randi()
	assert_array(_signature(rng)).is_equal(expected)


func test_slot_plans_do_not_depend_on_the_order() -> void:
	var rng := WorldRng.new(7)
	var plan: LayerPlan = _generator.generate(LAYER, rng)
	var forwards: Array = []
	for placement: ChunkPlacement in plan.main:
		forwards.append(_slots_of(rng, placement))
	var backwards: Array = []
	backwards.resize(plan.main.size())
	for index: int in range(plan.main.size() - 1, -1, -1):
		backwards[index] = _slots_of(rng, plan.main[index])
	assert_array(backwards).is_equal(forwards)


func test_global_rng_does_not_affect_generation() -> void:
	seed(1)
	var first: Array = _signature(WorldRng.new(99))
	seed(2)
	randi()
	assert_array(_signature(WorldRng.new(99))).is_equal(first)


func test_raising_a_slot_chance_only_adds_objects() -> void:
	var rng := WorldRng.new(SeedCode.to_int("K7QX-2MPA"))
	var slots: Dictionary[StringName, StringName] = {}
	for i: int in 300:
		slots[StringName("slot_pickup_%d" % i)] = Chunk.SLOT_PICKUP
	var previous: Dictionary[StringName, StringName] = {}
	for multiplier: float in [0.0, 0.5, 1.0, 1.5, 3.0]:
		var filled: Dictionary[StringName, StringName] = SlotFiller.plan(
			rng, LAYER, ["K", "main", 3], slots, multiplier
		)
		for slot_name: StringName in previous:
			# Same slots, same objects: the kind roll does not depend on the chance
			assert_str(filled.get(slot_name, &"")).is_equal(previous[slot_name])
		assert_int(filled.size()).is_greater_equal(previous.size())
		previous = filled
	assert_int(previous.size()).is_equal(300)


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


func test_main_path_follows_the_template() -> void:
	for seed_value: int in SEEDS:
		var plan: LayerPlan = _generator.generate(LAYER, WorldRng.new(seed_value))
		assert_int(plan.main.size()).is_equal(LAYER.template.size())
		for index: int in plan.main.size():
			var placement: ChunkPlacement = plan.main[index]
			assert_int(placement.type).is_equal(LAYER.template[index])
			assert_int(_library.get_info(placement.chunk_id).data.type).is_equal(placement.type)
			assert_str(placement.branch).is_equal(LayerPlan.MAIN_BRANCH)
			assert_int(placement.index).is_equal(index)


func test_every_fork_has_two_branches_ending_in_a_reward() -> void:
	for seed_value: int in SEEDS:
		var plan: LayerPlan = _generator.generate(LAYER, WorldRng.new(seed_value))
		assert_int(plan.branches.size()).is_equal(plan.get_fork_count() * 2)
		for fork: int in range(1, plan.get_fork_count() + 1):
			var rewards: Array[StringName] = plan.get_fork_rewards(fork)
			assert_str(rewards[0]).is_not_equal(rewards[1])
			for side: String in LayerPlan.SIDES:
				var branch: Array = plan.branches[LayerPlan.branch_id(fork, side)]
				var normal: int = branch.size() - 1
				assert_int(normal).is_between(LAYER.branch_length.x, LAYER.branch_length.y)
				for index: int in branch.size():
					var placement: ChunkPlacement = branch[index]
					var expected: ChunkData.Type = (
						ChunkData.Type.REWARD if index == normal else ChunkData.Type.NORMAL
					)
					assert_int(placement.type).is_equal(expected)
				var last: ChunkPlacement = branch.back()
				assert_str(last.reward).is_equal(plan.rewards[LayerPlan.branch_id(fork, side)])


func test_every_column_fits_entries_and_exits() -> void:
	for seed_value: int in SEEDS:
		var plan: LayerPlan = _generator.generate(LAYER, WorldRng.new(seed_value))
		for choices: PackedStringArray in _all_choices(plan.get_fork_count()):
			var column: Array[ChunkPlacement] = plan.column(choices)
			assert_bool(plan.is_complete(choices)).is_true()
			for index: int in range(1, column.size()):
				var below: ChunkPlacement = column[index - 1]
				var above: ChunkPlacement = column[index]
				var exits: int = _library.get_info(below.chunk_id).get_exits(below.mirrored)
				if below.type == ChunkData.Type.FORK:
					# A branch starts at the exit of its side
					var side: int = LayerPlan.SIDES.find(choices[below.fork - 1])
					exits = (
						_library.get_info(below.chunk_id).get_exit_openings(below.mirrored)[side]
					)
				var entries: int = _library.get_info(above.chunk_id).get_entries(above.mirrored)
				(
					assert_int(exits & entries)
					. override_failure_message(
						(
							"%s no encaja con %s (semilla %d)"
							% [above.label(), below.label(), seed_value]
						)
					)
					. is_not_equal(0)
				)
				assert_str(above.chunk_id).is_not_equal(below.chunk_id)


func test_main_difficulty_follows_the_curve() -> void:
	for seed_value: int in SEEDS:
		var plan: LayerPlan = _generator.generate(LAYER, WorldRng.new(seed_value))
		for placement: ChunkPlacement in plan.main:
			if placement.type != ChunkData.Type.NORMAL:
				continue
			var difficulty: int = _library.get_info(placement.chunk_id).data.difficulty
			assert_int(absi(difficulty - LAYER.difficulty_at(placement.index))).is_less_equal(
				LayerGenerator.DIFFICULTY_TOLERANCE
			)


func test_only_mirrorable_chunks_are_mirrored() -> void:
	var mirrored: int = 0
	for seed_value: int in SEEDS:
		var plan: LayerPlan = _generator.generate(LAYER, WorldRng.new(seed_value))
		for placement: ChunkPlacement in plan.column(PackedStringArray(["L", "R"])):
			if placement.mirrored:
				mirrored += 1
				assert_bool(_library.get_info(placement.chunk_id).data.mirrorable).is_true()
	assert_int(mirrored).is_greater(0)


func test_column_stops_at_the_first_undecided_fork() -> void:
	var plan: LayerPlan = _generator.generate(LAYER, WorldRng.new(3))
	var column: Array[ChunkPlacement] = plan.column(PackedStringArray())
	assert_int(column.back().type).is_equal(ChunkData.Type.FORK)
	assert_bool(plan.is_complete(PackedStringArray())).is_false()
	var longer: Array[ChunkPlacement] = plan.column(PackedStringArray(["R"]))
	assert_int(longer.size()).is_greater(column.size())
	assert_str(longer[column.size()].branch).is_equal("1/R")
	# The column only grows: the chunks below stay the same
	for index: int in column.size():
		assert_object(longer[index]).is_same(column[index])


func test_layer_difficulty_curve() -> void:
	assert_int(LAYER.difficulty_at(0)).is_equal(LAYER.difficulty_range.x)
	assert_int(LAYER.difficulty_at(LAYER.template.size() - 1)).is_equal(LAYER.difficulty_range.y)


## Chunk ids (with the mirror flag) of the main path and every branch.
func _signature(rng: WorldRng) -> Array:
	var plan: LayerPlan = _generator.generate(LAYER, rng)
	var result: Array = []
	for placement: ChunkPlacement in plan.main:
		result.append("%s %s %s" % [placement.label(), placement.chunk_id, placement.mirrored])
	var branch_ids: Array = plan.branches.keys()
	branch_ids.sort()
	for branch: String in branch_ids:
		var branch_chunks: Array = plan.branches[branch]
		for placement: ChunkPlacement in branch_chunks:
			result.append("%s %s %s" % [placement.label(), placement.chunk_id, placement.mirrored])
		result.append(plan.rewards[branch])
	return result


func _slots_of(rng: WorldRng, placement: ChunkPlacement) -> Dictionary:
	return SlotFiller.plan(rng, LAYER, placement.key(), _library.get_info(placement.chunk_id).slots)


## Every combination of sides for `forks` forks.
func _all_choices(forks: int) -> Array[PackedStringArray]:
	var all: Array[PackedStringArray] = [PackedStringArray()]
	for _fork: int in forks:
		var next: Array[PackedStringArray] = []
		for choices: PackedStringArray in all:
			for side: String in LayerPlan.SIDES:
				var longer: PackedStringArray = choices.duplicate()
				longer.append(side)
				next.append(longer)
		all = next
	return all
