extends GdUnitTestSuite

## Tests del estado de partida (RunState).

const WILAS: CharacterData = preload("res://data/characters/wilas.tres")

var _hp_events: Array[Array] = []
var _died_count: int = 0


func before_test() -> void:
	_hp_events.clear()
	_died_count = 0


func test_runs_start_at_full_hp() -> void:
	var run := RunState.new("k7qx 2mpa", WILAS)
	assert_str(run.seed_code).is_equal("K7QX-2MPA")
	assert_str(run.get_seed_label()).is_equal("K7QX-2MPA · g%d" % WorldRng.GENERATION_VERSION)
	assert_int(run.world_rng.seed_value).is_equal(SeedCode.to_int("K7QX-2MPA"))
	assert_float(run.hp).is_equal(100.0)
	assert_float(run.get_max_hp()).is_equal(100.0)
	assert_int(run.coins).is_equal(0)
	assert_int(run.counters.jumps).is_equal(0)


func test_each_run_has_its_own_state() -> void:
	var first := RunState.new("A", WILAS)
	first.take_damage(30.0)
	first.add_coins(4)
	first.stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 50.0, &"a"))
	var second := RunState.new("B", WILAS)
	assert_float(second.hp).is_equal(100.0)
	assert_int(second.coins).is_equal(0)
	assert_float(second.stats.get_value(Stats.SPEED)).is_equal(300.0)


func test_damage_is_reduced_by_defense() -> void:
	var run := RunState.new("A", WILAS)
	run.stats.add_modifier(StatModifier.create(Stats.DEFENSE, StatModifier.Type.ADD, 0.25, &"a"))
	assert_float(run.take_damage(20.0)).is_equal(15.0)
	assert_float(run.hp).is_equal(85.0)


func test_unreducible_damage_ignores_defense() -> void:
	var run := RunState.new("A", WILAS)
	run.stats.add_modifier(StatModifier.create(Stats.DEFENSE, StatModifier.Type.ADD, 0.25, &"a"))
	assert_float(run.take_damage(25.0, false)).is_equal(25.0)
	assert_float(run.hp).is_equal(75.0)


func test_hp_never_goes_below_zero_and_dies_once() -> void:
	var run := RunState.new("A", WILAS)
	run.died.connect(func() -> void: _died_count += 1)
	run.take_damage(1000.0)
	run.take_damage(10.0)
	assert_float(run.hp).is_equal(0.0)
	assert_bool(run.is_dead()).is_true()
	assert_int(_died_count).is_equal(1)


func test_emits_hp_changed() -> void:
	var run := RunState.new("A", WILAS)
	run.hp_changed.connect(_record_hp)
	run.take_damage(10.0)
	run.heal(5.0)
	run.heal(500.0)
	assert_array(_hp_events).is_equal([[90.0, 100.0], [95.0, 100.0], [100.0, 100.0]])


func test_max_hp_changes_update_hp() -> void:
	var run := RunState.new("A", WILAS)
	run.hp_changed.connect(_record_hp)
	var modifier := StatModifier.create(Stats.MAX_HP, StatModifier.Type.ADD, -40.0, &"a")
	run.stats.add_modifier(modifier)
	assert_float(run.hp).is_equal(60.0)
	run.stats.remove_modifier(modifier)
	assert_float(run.hp).is_equal(60.0)
	assert_array(_hp_events).is_equal([[60.0, 60.0], [60.0, 100.0]])


func test_currencies_and_counters() -> void:
	var run := RunState.new("A", WILAS)
	var coins_signal: Array[int] = []
	run.coins_changed.connect(func(value: int) -> void: coins_signal.append(value))
	run.add_coins(1)
	run.add_coins(5)
	run.add_keys(1)
	run.register_jump()
	assert_int(run.coins).is_equal(6)
	assert_int(run.keys).is_equal(1)
	assert_int(run.counters.coins_collected).is_equal(6)
	assert_int(run.counters.keys_collected).is_equal(1)
	assert_int(run.counters.jumps).is_equal(1)
	assert_array(coins_signal).is_equal([1, 6])


func test_altitude_only_signals_changes() -> void:
	var run := RunState.new("A", WILAS)
	var altitudes: Array[float] = []
	run.altitude_changed.connect(func(value: float) -> void: altitudes.append(value))
	run.set_altitude(1.5)
	run.set_altitude(1.5)
	run.set_altitude(2.0)
	assert_array(altitudes).is_equal([1.5, 2.0])


func test_threat_distance_only_signals_changes() -> void:
	var run := RunState.new("A", WILAS)
	var distances: Array[float] = []
	run.threat_distance_changed.connect(func(value: float) -> void: distances.append(value))
	run.set_threat_distance(3.0)
	run.set_threat_distance(3.0)
	run.set_threat_distance(1.0)
	assert_array(distances).is_equal([3.0, 1.0])


func test_death_records_its_cause_and_kills_are_counted() -> void:
	var run := RunState.new("A", WILAS)
	run.take_damage(10.0, true, &"spike")
	assert_str(run.counters.death_cause).is_empty()
	run.take_damage(1000.0, false, &"rising_threat")
	assert_str(run.counters.death_cause).is_equal(&"rising_threat")
	assert_str(RunCounters.cause_key(&"rising_threat")).is_equal("CAUSE_RISING_THREAT")
	run.register_kill(&"free_neutron")
	run.register_kill(&"free_neutron")
	run.register_kill(&"orbital_electron")
	assert_int(run.counters.enemies_killed).is_equal(3)
	assert_int(run.counters.kills_by_enemy[&"free_neutron"]).is_equal(2)


func _record_hp(value: float, max_value: float) -> void:
	_hp_events.append([value, max_value])
