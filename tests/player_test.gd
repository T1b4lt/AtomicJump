extends GdUnitTestSuite

## Tests del jugador: lógica de saltos, daño, invulnerabilidad y estadísticas.

const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")
const WILAS: CharacterData = preload("res://data/characters/wilas.tres")


func test_max_air_jumps() -> void:
	assert_int(Player.max_air_jumps(1)).is_equal(0)
	assert_int(Player.max_air_jumps(2)).is_equal(1)
	assert_int(Player.max_air_jumps(3)).is_equal(2)
	assert_int(Player.max_air_jumps(0)).is_equal(0)


func test_double_jump_from_floor() -> void:
	var player: Player = _add_player(2)
	assert_bool(player.try_jump(true)).is_true()
	assert_bool(player.try_jump(false)).is_true()
	assert_bool(player.try_jump(false)).is_false()


func test_ground_jump_is_allowed_with_stale_floor_state() -> void:
	# Pressing jump on several frames while still on the floor never consumes air jumps
	var player: Player = _add_player(2)
	assert_bool(player.try_jump(true)).is_true()
	assert_bool(player.try_jump(true)).is_true()
	assert_int(player.air_jumps_used).is_equal(0)


func test_walking_off_a_ledge_keeps_air_jumps() -> void:
	var player: Player = _add_player(3)
	assert_bool(player.try_jump(false)).is_true()
	assert_bool(player.try_jump(false)).is_true()
	assert_bool(player.try_jump(false)).is_false()


func test_damage_starts_invulnerability() -> void:
	var player: Player = _add_player()
	assert_bool(player.take_damage(10.0)).is_true()
	assert_float(player.run.hp).is_equal(90.0)
	assert_bool(player.is_invulnerable()).is_true()

	# A second hit during the invulnerability window is ignored
	assert_bool(player.take_damage(10.0)).is_false()
	assert_float(player.run.hp).is_equal(90.0)


func test_invulnerability_ends_after_its_time() -> void:
	var player: Player = _add_player()
	player.take_damage(1.0)
	player._update_invulnerability(player.invulnerability_time)
	assert_bool(player.is_invulnerable()).is_false()
	assert_float(player.modulate.a).is_equal(1.0)


func test_hp_bar_follows_the_run() -> void:
	var player: Player = _add_player()
	var bar: ProgressBar = player.get_node("%HpBar")
	assert_float(bar.value).is_equal(100.0)
	player.take_damage(25.0)
	assert_float(bar.value).is_equal(75.0)
	assert_str((player.get_node("%HpLabel") as Label).text).is_equal("75.00/100.0")


func test_size_stat_scales_the_player() -> void:
	var player: Player = _add_player()
	player.run.stats.add_modifier(StatModifier.create(Stats.SIZE, StatModifier.Type.ADD, 0.2, &"a"))
	assert_vector(player.scale).is_equal_approx(Vector2(1.2, 1.2), Vector2(0.001, 0.001))


func _add_player(max_jumps: int = 2) -> Player:
	var run := RunState.new("A", WILAS)
	var extra_jumps: float = max_jumps - run.stats.get_value(Stats.MAX_JUMPS)
	if extra_jumps != 0.0:
		run.stats.add_modifier(
			StatModifier.create(Stats.MAX_JUMPS, StatModifier.Type.ADD, extra_jumps, &"test")
		)
	var player: Player = auto_free(PLAYER_SCENE.instantiate())
	add_child(player)
	player.set_physics_process(false)
	player.bind_run(run)
	return player
