extends GdUnitTestSuite

## Tests de RunManager: una partida nueva por inicio y divisas por eventos globales.

var _saved_run: RunState


func before_test() -> void:
	_saved_run = RunManager.run


func after_test() -> void:
	RunManager.run = _saved_run


func test_start_run_creates_a_new_state() -> void:
	var first: RunState = RunManager.start_run("AAAA-1111")
	first.take_damage(50.0)
	var second: RunState = RunManager.start_run("BBBB-2222")
	assert_object(second).is_not_same(first)
	assert_str(second.seed_code).is_equal("BBBB-2222")
	assert_float(second.hp).is_equal(second.get_max_hp())
	assert_object(second.character).is_same(RunManager.DEFAULT_CHARACTER)


func test_start_run_without_seed_is_random() -> void:
	var run: RunState = RunManager.start_run("  - ")
	assert_bool(SeedCode.is_code(SeedCode.normalize(run.seed_code))).is_true()


func test_end_run_returns_the_run_and_clears_it() -> void:
	var run: RunState = RunManager.start_run("AAAA-1111")
	assert_object(RunManager.end_run()).is_same(run)
	assert_bool(RunManager.has_run()).is_false()
	assert_object(RunManager.end_run()).is_null()


func test_pickup_events_reach_the_current_run() -> void:
	var run: RunState = RunManager.start_run("AAAA-1111")
	Events.coin_collected.emit(5)
	Events.key_collected.emit(1)
	assert_int(run.coins).is_equal(5)
	assert_int(run.keys).is_equal(1)


func test_pickup_events_without_a_run_are_ignored() -> void:
	RunManager.run = null
	Events.coin_collected.emit(5)
	assert_bool(RunManager.has_run()).is_false()
