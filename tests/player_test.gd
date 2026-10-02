extends GdUnitTestSuite

## Tests del protagonista: lógica de saltos, daño e invulnerabilidad.

const PROTAGONIST_SCENE: PackedScene = preload("res://actors/player/player.tscn")

var _saved_max_jumps: int
var _saved_hp: float


func before_test() -> void:
	_saved_max_jumps = game.pr_max_jumps
	_saved_hp = game.pr_hp


func after_test() -> void:
	game.pr_max_jumps = _saved_max_jumps
	game.pr_hp = _saved_hp


func test_max_air_jumps() -> void:
	assert_int(Player.max_air_jumps(1)).is_equal(0)
	assert_int(Player.max_air_jumps(2)).is_equal(1)
	assert_int(Player.max_air_jumps(3)).is_equal(2)
	assert_int(Player.max_air_jumps(0)).is_equal(0)


func test_double_jump_from_floor() -> void:
	game.pr_max_jumps = 2
	var protagonist: Player = auto_free(PROTAGONIST_SCENE.instantiate())
	assert_bool(protagonist.try_jump(true)).is_true()
	assert_bool(protagonist.try_jump(false)).is_true()
	assert_bool(protagonist.try_jump(false)).is_false()


func test_ground_jump_is_allowed_with_stale_floor_state() -> void:
	# Pressing jump on several frames while still on the floor never consumes air jumps
	game.pr_max_jumps = 2
	var protagonist: Player = auto_free(PROTAGONIST_SCENE.instantiate())
	assert_bool(protagonist.try_jump(true)).is_true()
	assert_bool(protagonist.try_jump(true)).is_true()
	assert_int(protagonist.air_jumps_used).is_equal(0)


func test_walking_off_a_ledge_keeps_air_jumps() -> void:
	game.pr_max_jumps = 3
	var protagonist: Player = auto_free(PROTAGONIST_SCENE.instantiate())
	assert_bool(protagonist.try_jump(false)).is_true()
	assert_bool(protagonist.try_jump(false)).is_true()
	assert_bool(protagonist.try_jump(false)).is_false()


func test_damage_starts_invulnerability() -> void:
	game.pr_hp = 50.0
	var protagonist: Player = auto_free(PROTAGONIST_SCENE.instantiate())
	assert_bool(protagonist.take_damage(10.0)).is_true()
	assert_float(game.pr_hp).is_equal(50.0 - 10.0 * game.pr_defense)
	assert_bool(protagonist.is_invulnerable()).is_true()

	# A second hit during the invulnerability window is ignored
	assert_bool(protagonist.take_damage(10.0)).is_false()
	assert_float(game.pr_hp).is_equal(50.0 - 10.0 * game.pr_defense)


func test_invulnerability_ends_after_its_time() -> void:
	var protagonist: Player = auto_free(PROTAGONIST_SCENE.instantiate())
	protagonist.take_damage(1.0)
	protagonist._update_invulnerability(Player.INVULNERABILITY_TIME)
	assert_bool(protagonist.is_invulnerable()).is_false()
	assert_float(protagonist.modulate.a).is_equal(1.0)


func test_hp_never_goes_below_zero() -> void:
	game.pr_hp = 5.0
	var protagonist: Player = auto_free(PROTAGONIST_SCENE.instantiate())
	protagonist.take_damage(1000.0)
	assert_float(game.pr_hp).is_equal(0.0)
