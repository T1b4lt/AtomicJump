extends "res://tests/support/player_suite.gd"

## Tests del jugador: Túnel, daño, muerte, reaparición, puntos seguros,
## estadísticas y señales de la máquina de estados.


func test_dash_moves_fast_without_gravity_and_is_invulnerable() -> void:
	_add_floor()
	var player: Player = await _add_player(Vector2(0, -200))
	_step(player, _controls(-1.0, false, false, false, true))
	assert_int(player.state).is_equal(Player.State.DASH)
	assert_bool(player.is_invulnerable()).is_true()
	assert_float(player.velocity.x).is_equal(-player.movement.dash_speed)
	var start_y: float = player.global_position.y
	_steps(player, 5)
	assert_float(player.global_position.y).is_equal(start_y)
	assert_bool(player.take_damage(10.0)).is_false()
	_steps(player, 5)
	assert_int(player.state).is_not_equal(Player.State.DASH)
	assert_float(player.dash_cooldown_left).is_greater(0.0)


func test_dash_uses_facing_without_direction_and_has_a_cooldown() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	_step(player, _controls(0.0, false, false, false, true))
	assert_float(player.velocity.x).is_equal(player.movement.dash_speed)
	_steps(player, 12)
	assert_bool(player.can_dash()).is_false()
	_steps(player, roundi(player.movement.dash_cooldown / DT))
	assert_bool(player.can_dash()).is_true()


func test_air_dashes_are_limited_until_landing() -> void:
	_add_floor()
	var player: Player = await _add_player(Vector2(0, -600))
	_step(player, _controls(0.0, false, false, false, true))
	_steps(player, roundi((player.movement.dash_duration + player.movement.dash_cooldown) / DT) + 2)
	assert_bool(player.is_on_floor()).is_false()
	assert_bool(player.can_dash()).is_false()
	_steps(player, 90)
	assert_bool(player.is_on_floor()).is_true()
	assert_bool(player.can_dash()).is_true()


func test_damage_starts_invulnerability_and_knocks_back() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	assert_bool(player.take_damage(10.0, player.global_position + Vector2(-50, 0))).is_true()
	assert_float(player.run.hp).is_equal(90.0)
	assert_bool(player.is_invulnerable()).is_true()
	assert_int(player.state).is_equal(Player.State.HURT)
	assert_float(player.velocity.x).is_greater(0.0)
	assert_float(player.velocity.y).is_less(0.0)

	# A second hit during the invulnerability window is ignored
	assert_bool(player.take_damage(10.0)).is_false()
	assert_float(player.run.hp).is_equal(90.0)

	# Control comes back after the hurt time
	_steps(player, roundi(player.movement.hurt_time / DT) + 1)
	assert_int(player.state).is_not_equal(Player.State.HURT)


func test_invulnerability_ends_after_its_time() -> void:
	var player: Player = await _add_player(Vector2.ZERO)
	player.take_damage(1.0)
	player._update_invulnerability(player.invulnerability_time)
	assert_bool(player.is_invulnerable()).is_false()
	assert_float((player.get_node("%Visual") as PlayerVisual).blink_opacity).is_equal(1.0)


func test_unavoidable_damage_ignores_invulnerability_and_defense() -> void:
	var player: Player = await _add_player(Vector2.ZERO)
	player.run.stats.add_modifier(
		StatModifier.create(Stats.DEFENSE, StatModifier.Type.ADD, 0.5, &"a")
	)
	player.take_damage(20.0)
	assert_float(player.run.hp).is_equal(90.0)
	player.take_unavoidable_damage(25.0)
	assert_float(player.run.hp).is_equal(65.0)


func test_dies_and_stops() -> void:
	var player: Player = await _add_player(Vector2.ZERO)
	player.take_unavoidable_damage(1000.0)
	assert_int(player.state).is_equal(Player.State.DEAD)
	_steps(player, 10, _controls(1.0, true))
	assert_vector(player.global_position).is_equal(Vector2.ZERO)
	assert_bool(player.take_damage(10.0)).is_false()


func test_respawn_stops_and_protects_the_player() -> void:
	var player: Player = await _add_player(Vector2.ZERO)
	player.velocity = Vector2(100, 500)
	player.respawn_at(Vector2(30, -400))
	assert_vector(player.global_position).is_equal(Vector2(30, -400))
	assert_vector(player.velocity).is_equal(Vector2.ZERO)
	assert_bool(player.is_invulnerable()).is_true()


func test_remembers_safe_floor_spots() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	assert_int(player.safe_spots.size()).is_equal(1)
	_steps(player, 30, _controls(1.0))
	assert_int(player.safe_spots.size()).is_greater(1)
	assert_float(player.safe_spots[-1].y).is_equal_approx(FLOOR_Y - FEET, 1.0)


func test_feet_offset_follows_the_size() -> void:
	var player: Player = await _add_player(Vector2.ZERO)
	assert_float(player.get_feet_offset()).is_equal_approx(FEET, 0.01)
	player.run.stats.add_modifier(StatModifier.create(Stats.SIZE, StatModifier.Type.ADD, 0.2, &"a"))
	assert_vector(player.scale).is_equal_approx(Vector2(1.2, 1.2), Vector2(0.001, 0.001))
	assert_float(player.get_feet_offset()).is_equal_approx(FEET * 1.2, 0.01)


func test_hp_bar_follows_the_run() -> void:
	var player: Player = await _add_player(Vector2.ZERO)
	var bar: ProgressBar = player.get_node("%HpBar")
	assert_float(bar.value).is_equal(100.0)
	player.take_damage(25.0)
	assert_float(bar.value).is_equal(75.0)
	assert_str((player.get_node("%HpLabel") as Label).text).is_equal("75.00/100.0")


func test_state_changes_are_signalled() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var changes: Array[Player.State] = []
	player.state_changed.connect(
		func(_from: Player.State, to: Player.State) -> void: changes.append(to)
	)
	_step(player, _controls(0.0, true))
	_steps(player, 90)
	assert_array(changes).contains_exactly(
		[Player.State.JUMP, Player.State.FALL, Player.State.IDLE]
	)
