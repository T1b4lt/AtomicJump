extends GdUnitTestSuite

## Tests del sistema de estadísticas: fórmula, límites, caché y señal stat_changed.

const WILAS: CharacterData = preload("res://data/characters/wilas.tres")

var _changes: Array[Array] = []


func before_test() -> void:
	_changes.clear()


func test_base_values_come_from_the_stat_block() -> void:
	var stats := Stats.new(WILAS.base_stats)
	for stat: StringName in Stats.ALL:
		assert_float(stats.get_value(stat)).is_equal(WILAS.base_stats.get_base(stat))


func test_wilas_base_stats() -> void:
	var stats := Stats.new(WILAS.base_stats)
	assert_float(stats.get_value(Stats.MAX_HP)).is_equal(100.0)
	assert_float(stats.get_value(Stats.SPEED)).is_equal(300.0)
	assert_float(stats.get_value(Stats.JUMP_FORCE)).is_equal(450.0)
	assert_int(stats.get_int(Stats.MAX_JUMPS)).is_equal(2)
	assert_float(stats.get_value(Stats.DEFENSE)).is_equal(0.0)


func test_adds_then_multiplies() -> void:
	var stats := Stats.new(_block())
	stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 20.0, &"a"))
	stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.MULT, 0.5, &"b"))
	stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 30.0, &"c"))
	# (300 + 20 + 30) × 1.5
	assert_float(stats.get_value(Stats.SPEED)).is_equal_approx(525.0, 0.001)


func test_multipliers_stack_multiplicatively() -> void:
	var stats := Stats.new(_block())
	stats.add_modifier(StatModifier.create(Stats.ATTACK_POWER, StatModifier.Type.MULT, 0.5, &"a"))
	stats.add_modifier(StatModifier.create(Stats.ATTACK_POWER, StatModifier.Type.MULT, 1.0, &"b"))
	# 5 × 1.5 × 2
	assert_float(stats.get_value(Stats.ATTACK_POWER)).is_equal_approx(15.0, 0.001)


func test_values_are_clamped_to_their_limits() -> void:
	var stats := Stats.new(_block())
	stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 1000.0, &"a"))
	stats.add_modifier(StatModifier.create(Stats.DEFENSE, StatModifier.Type.ADD, 2.0, &"a"))
	stats.add_modifier(StatModifier.create(Stats.SIZE, StatModifier.Type.MULT, -0.9, &"a"))
	stats.add_modifier(StatModifier.create(Stats.MAX_HP, StatModifier.Type.ADD, -500.0, &"a"))
	assert_float(stats.get_value(Stats.SPEED)).is_equal(Stats.MAX_VALUES[Stats.SPEED])
	assert_float(stats.get_value(Stats.DEFENSE)).is_equal(0.6)
	assert_float(stats.get_value(Stats.SIZE)).is_equal(0.6)
	assert_float(stats.get_value(Stats.MAX_HP)).is_equal(1.0)


func test_every_stat_has_limits_and_a_base_value() -> void:
	var block := StatBlock.new()
	for stat: StringName in Stats.ALL:
		assert_bool(Stats.MIN_VALUES.has(stat)).override_failure_message(String(stat)).is_true()
		assert_bool(Stats.MAX_VALUES.has(stat)).override_failure_message(String(stat)).is_true()
		assert_bool(stat in block).override_failure_message(String(stat)).is_true()


func test_modifiers_only_affect_their_stat() -> void:
	var stats := Stats.new(_block())
	stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 50.0, &"a"))
	assert_float(stats.get_value(Stats.JUMP_FORCE)).is_equal(450.0)


func test_remove_modifier_restores_the_value() -> void:
	var stats := Stats.new(_block())
	var modifier := StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 50.0, &"a")
	stats.add_modifier(modifier)
	stats.remove_modifier(modifier)
	assert_float(stats.get_value(Stats.SPEED)).is_equal(300.0)


func test_remove_modifiers_from_a_source() -> void:
	var stats := Stats.new(_block())
	stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 50.0, &"item"))
	stats.add_modifier(StatModifier.create(Stats.MAX_HP, StatModifier.Type.ADD, 10.0, &"item"))
	stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 5.0, &"other"))
	assert_int(stats.remove_modifiers_from(&"item")).is_equal(2)
	assert_float(stats.get_value(Stats.SPEED)).is_equal(305.0)
	assert_float(stats.get_value(Stats.MAX_HP)).is_equal(100.0)
	assert_int(stats.get_modifiers(Stats.SPEED).size()).is_equal(1)


func test_emits_stat_changed_with_the_new_value() -> void:
	var stats := Stats.new(_block())
	stats.stat_changed.connect(_record_change)
	var modifier := StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 50.0, &"a")
	stats.add_modifier(modifier)
	stats.remove_modifier(modifier)
	assert_array(_changes).is_equal([[Stats.SPEED, 350.0], [Stats.SPEED, 300.0]])


func test_no_signal_when_the_value_does_not_change() -> void:
	var stats := Stats.new(_block())
	stats.add_modifier(StatModifier.create(Stats.DEFENSE, StatModifier.Type.ADD, 0.6, &"a"))
	stats.stat_changed.connect(_record_change)
	# Already at the 60 % limit: the final value stays the same
	stats.add_modifier(StatModifier.create(Stats.DEFENSE, StatModifier.Type.ADD, 0.2, &"b"))
	stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 0.0, &"c"))
	assert_array(_changes).is_empty()


func test_cache_is_invalidated_by_modifiers() -> void:
	var stats := Stats.new(_block())
	assert_float(stats.get_value(Stats.SPEED)).is_equal(300.0)
	stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 50.0, &"a"))
	assert_float(stats.get_value(Stats.SPEED)).is_equal(350.0)


func test_base_block_is_not_modified() -> void:
	var block := _block()
	var stats := Stats.new(block)
	stats.add_modifier(StatModifier.create(Stats.SPEED, StatModifier.Type.ADD, 50.0, &"a"))
	assert_float(block.speed).is_equal(300.0)
	assert_float(stats.get_base(Stats.SPEED)).is_equal(300.0)


func _block() -> StatBlock:
	return StatBlock.new()


func _record_change(stat: StringName, value: float) -> void:
	_changes.append([stat, value])
