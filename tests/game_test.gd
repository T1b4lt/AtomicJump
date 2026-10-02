extends GdUnitTestSuite

## Tests del estado de partida del prototipo (autoload `game`).

const GameScript: GDScript = preload("res://scripts/game.gd")


func test_generated_seeds_are_valid_seed_text() -> void:
	for i: int in 200:
		var generated: int = Game.generate_seed()
		assert_int(generated).is_between(Game.SEED_MIN, Game.SEED_MAX)
		assert_bool(Game.is_valid_seed_text(str(generated))).is_true()


func test_seed_text_validation() -> void:
	assert_bool(Game.is_valid_seed_text("123456789")).is_true()
	assert_bool(Game.is_valid_seed_text(" 987654321 ")).is_true()
	assert_bool(Game.is_valid_seed_text("")).is_false()
	assert_bool(Game.is_valid_seed_text("12345678")).is_false()
	assert_bool(Game.is_valid_seed_text("1234567890")).is_false()
	assert_bool(Game.is_valid_seed_text("012345678")).is_false()
	assert_bool(Game.is_valid_seed_text("-12345678")).is_false()
	assert_bool(Game.is_valid_seed_text("+12345678")).is_false()
	assert_bool(Game.is_valid_seed_text("12345a789")).is_false()


func test_start_run_resets_previous_run_state() -> void:
	var state: Game = auto_free(GameScript.new())
	state.pr_hp = 3.0
	state.altitude = 42.0
	state.jump_counter = 7
	state.actual_coins = 5
	state.total_keys = 2

	state.start_run(123456789)

	assert_int(state.game_seed).is_equal(123456789)
	assert_float(state.pr_hp).is_equal(state.pr_max_hp)
	assert_float(state.altitude).is_equal(0.0)
	assert_int(state.jump_counter).is_equal(0)
	assert_int(state.actual_coins).is_equal(0)
	assert_int(state.total_keys).is_equal(0)


func test_runs_start_at_full_hp() -> void:
	var state: Game = auto_free(GameScript.new())
	assert_float(state.pr_hp).is_equal(state.pr_max_hp)
	assert_float(state.pr_max_hp).is_equal(100.0)
