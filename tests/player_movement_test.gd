extends "res://tests/support/player_suite.gd"

## Tests del movimiento del jugador: aceleración, gravedad, salto variable,
## coyote time, jump buffer, saltos cuánticos y plataformas atravesables.


func test_max_air_jumps() -> void:
	assert_int(Player.max_air_jumps(1)).is_equal(0)
	assert_int(Player.max_air_jumps(2)).is_equal(1)
	assert_int(Player.max_air_jumps(3)).is_equal(2)
	assert_int(Player.max_air_jumps(0)).is_equal(0)


func test_falls_lands_and_idles() -> void:
	_add_floor()
	var player: Player = await _add_player(Vector2(0, -100))
	_steps(player, 60)
	assert_bool(player.is_on_floor()).is_true()
	assert_int(player.state).is_equal(Player.State.IDLE)
	assert_float(player.global_position.y).is_equal_approx(FLOOR_Y - FEET, 1.0)


func test_accelerates_and_decelerates_quickly() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var speed: float = player.run.stats.get_value(Stats.SPEED)
	_steps(player, 2, _controls(1.0))
	assert_float(player.velocity.x).is_greater(0.0).is_less(speed)
	_steps(player, 4, _controls(1.0))
	assert_float(player.velocity.x).is_equal_approx(speed, 0.01)
	assert_int(player.state).is_equal(Player.State.RUN)
	_steps(player, 5)
	assert_float(player.velocity.x).is_equal(0.0)
	assert_int(player.state).is_equal(Player.State.IDLE)


func test_ground_jump() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	_step(player, _controls(0.0, true))
	assert_float(player.velocity.y).is_less(0.0)
	assert_int(player.state).is_equal(Player.State.JUMP)
	assert_int(player.run.counters.jumps).is_equal(1)
	assert_int(player.air_jumps_used).is_equal(0)


func test_releasing_jump_cuts_the_jump() -> void:
	_add_floor()
	var held: Player = await _standing_player()
	var full_height: float = _jump_height(held, 60)
	var tapped: Player = await _standing_player(Vector2(200, FLOOR_Y - FEET))
	var short_height: float = _jump_height(tapped, 4)
	assert_float(short_height).is_less(full_height * 0.6)


func test_falls_faster_than_it_rises_and_has_terminal_velocity() -> void:
	var config := MovementConfig.new()
	assert_float(config.gravity_for(10.0)).is_greater(config.gravity_for(-10.0))
	var player: Player = await _add_player(Vector2.ZERO)
	_steps(player, 180)
	assert_float(player.velocity.y).is_equal(player.movement.terminal_velocity)
	assert_int(player.state).is_equal(Player.State.FALL)


func test_coyote_time_allows_a_ground_jump_after_leaving_the_floor() -> void:
	var floor_body: StaticBody2D = _add_floor()
	var player: Player = await _standing_player()
	await _remove(floor_body)
	_steps(player, 3)
	assert_bool(player.is_on_floor()).is_false()
	_step(player, _controls(0.0, true))
	assert_float(player.velocity.y).is_less(0.0)
	assert_int(player.air_jumps_used).is_equal(0)


func test_after_coyote_time_jumps_are_air_jumps_and_none_is_lost() -> void:
	var floor_body: StaticBody2D = _add_floor()
	var player: Player = await _standing_player(Vector2(0, FLOOR_Y - FEET), 3)
	await _remove(floor_body)
	_steps(player, 10)
	# Walking off a ledge keeps every air jump: 3 jumps = 2 in the air
	_step(player, _controls(0.0, true))
	_step(player, _controls(0.0, true))
	_step(player, _controls(0.0, true))
	assert_int(player.air_jumps_used).is_equal(2)
	assert_int(player.run.counters.jumps).is_equal(2)


func test_jump_buffer_jumps_on_landing() -> void:
	_add_floor()
	var player: Player = await _add_player(Vector2(0, FLOOR_Y - FEET - 12), 1)
	player.velocity.y = 300.0
	_step(player, _controls(0.0, true))
	assert_int(player.run.counters.jumps).is_equal(0)
	_steps(player, 5, _controls(0.0, false, true))
	assert_int(player.run.counters.jumps).is_equal(1)
	assert_float(player.velocity.y).is_less(0.0)


func test_old_jump_presses_are_forgotten() -> void:
	_add_floor()
	var player: Player = await _add_player(Vector2(0, FLOOR_Y - FEET - 150), 1)
	_step(player, _controls(0.0, true))
	_steps(player, 40)
	assert_bool(player.is_on_floor()).is_true()
	assert_int(player.run.counters.jumps).is_equal(0)


func test_double_jump_uses_the_air_jump_ratio() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	_step(player, _controls(0.0, true))
	_steps(player, 10, _controls(0.0, false, true))
	_step(player, _controls(0.0, true))
	var air_force: float = player.run.stats.get_value(Stats.JUMP_FORCE)
	air_force *= player.movement.air_jump_ratio
	# The jump starts at -air_force and gravity acts once in that frame
	assert_float(player.velocity.y).is_equal_approx(-air_force, 30.0)
	assert_int(player.air_jumps_used).is_equal(1)
	assert_int(player.get_air_jumps_left()).is_equal(0)
	_step(player, _controls(0.0, true))
	assert_int(player.run.counters.jumps).is_equal(2)


func test_landing_restores_air_jumps() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	_step(player, _controls(0.0, true))
	_step(player, _controls(0.0, true))
	assert_int(player.air_jumps_used).is_equal(1)
	_steps(player, 90)
	assert_bool(player.is_on_floor()).is_true()
	assert_int(player.air_jumps_used).is_equal(0)


func test_jumps_up_through_a_one_way_platform() -> void:
	_add_floor()
	_add_platform(Vector2(0, FLOOR_Y - 70), true)
	var player: Player = await _standing_player()
	_step(player, _controls(0.0, true))
	_steps(player, 90, _controls(0.0, false, true))
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_equal_approx(FLOOR_Y - 70 - FEET, 1.0)


func test_down_and_jump_drops_through_a_one_way_platform() -> void:
	_add_floor()
	_add_platform(Vector2(0, FLOOR_Y - 70), true)
	var player: Player = await _standing_player(Vector2(0, FLOOR_Y - 70 - FEET))
	_step(player, _controls(0.0, true, false, true))
	assert_int(player.run.counters.jumps).is_equal(0)
	_steps(player, 60, _controls(0.0, false, false, true))
	assert_float(player.global_position.y).is_equal_approx(FLOOR_Y - FEET, 1.0)
	assert_bool(player.get_collision_mask_value(PhysicsLayers.ONE_WAY_PLATFORMS)).is_true()


func test_down_and_jump_on_solid_floor_is_a_normal_jump() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	_step(player, _controls(0.0, true, false, true))
	assert_int(player.run.counters.jumps).is_equal(1)
	assert_bool(player.get_collision_mask_value(PhysicsLayers.ONE_WAY_PLATFORMS)).is_true()


func _jump_height(player: Player, held_frames: int) -> float:
	var start_y: float = player.global_position.y
	var top_y: float = start_y
	_step(player, _controls(0.0, true))
	for frame: int in 90:
		_step(player, _controls(0.0, false, frame < held_frames))
		top_y = minf(top_y, player.global_position.y)
	return start_y - top_y
