extends GdUnitTestSuite

## Tests del protagonista: lógica de saltos.

const PROTAGONIST_SCENE: PackedScene = preload("res://characters/protagonist/protagonist.tscn")

var _saved_max_jumps: int


func before_test() -> void:
	_saved_max_jumps = game.pr_max_jumps


func after_test() -> void:
	game.pr_max_jumps = _saved_max_jumps


func test_max_air_jumps() -> void:
	assert_int(Protagonist.max_air_jumps(1)).is_equal(0)
	assert_int(Protagonist.max_air_jumps(2)).is_equal(1)
	assert_int(Protagonist.max_air_jumps(3)).is_equal(2)
	assert_int(Protagonist.max_air_jumps(0)).is_equal(0)


func test_double_jump_from_floor() -> void:
	game.pr_max_jumps = 2
	var protagonist: Protagonist = auto_free(PROTAGONIST_SCENE.instantiate())
	assert_bool(protagonist.try_jump(true)).is_true()
	assert_bool(protagonist.try_jump(false)).is_true()
	assert_bool(protagonist.try_jump(false)).is_false()


func test_ground_jump_is_allowed_with_stale_floor_state() -> void:
	# Pressing jump on several frames while still on the floor never consumes air jumps
	game.pr_max_jumps = 2
	var protagonist: Protagonist = auto_free(PROTAGONIST_SCENE.instantiate())
	assert_bool(protagonist.try_jump(true)).is_true()
	assert_bool(protagonist.try_jump(true)).is_true()
	assert_int(protagonist.air_jumps_used).is_equal(0)


func test_walking_off_a_ledge_keeps_air_jumps() -> void:
	game.pr_max_jumps = 3
	var protagonist: Protagonist = auto_free(PROTAGONIST_SCENE.instantiate())
	assert_bool(protagonist.try_jump(false)).is_true()
	assert_bool(protagonist.try_jump(false)).is_true()
	assert_bool(protagonist.try_jump(false)).is_false()
