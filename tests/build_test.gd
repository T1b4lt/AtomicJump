extends "res://tests/support/player_suite.gd"

## Tests de los objetos de la partida (docs/07-items.md): efectos de estadística,
## efectos con hooks, transformación por etiqueta y operadores con su recarga.

const CATALOG: ItemCatalog = preload("res://data/items/item_catalog.tres")
const FREE_NEUTRON: PackedScene = preload("res://actors/enemies/free_neutron/free_neutron.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://combat/projectile.tscn")


func test_stat_items_add_modifiers_with_their_source() -> void:
	var run := RunState.new("A", WILAS, CATALOG)
	run.add_item(_item(&"effective_mass"))
	run.add_item(_item(&"linear_momentum"))
	assert_float(run.get_max_hp()).is_equal(125.0)
	assert_float(run.stats.get_value(Stats.SPEED)).is_equal(340.0)
	assert_str(run.stats.get_modifiers(Stats.SPEED)[0].source).is_equal(&"linear_momentum")
	run.add_item(_item(&"planck_constant"))
	assert_float(run.stats.get_value(Stats.SPEED)).is_equal_approx(357.0, 0.001)
	assert_int(run.counters.items_collected).is_equal(3)
	assert_bool(run.build.has_item(&"planck_constant")).is_true()


func test_bose_einstein_triples_the_pickup_radius() -> void:
	var run := RunState.new("A", WILAS, CATALOG)
	var base: float = run.stats.get_value(Stats.PICKUP_RADIUS)
	run.add_item(_item(&"bose_einstein"))
	assert_float(run.stats.get_value(Stats.PICKUP_RADIUS)).is_equal_approx(base * 3.0, 0.001)


func test_three_wave_items_give_the_wave_packet() -> void:
	var run := RunState.new("A", WILAS, CATALOG)
	var gained: Array[StringName] = []
	run.build.transformation_gained.connect(
		func(t: TransformationData) -> void: gained.append(t.id)
	)
	run.add_item(_item(&"compton_length"))
	run.add_item(_item(&"mean_free_path"))
	assert_array(gained).is_empty()
	run.add_item(_item(&"doppler_effect"))
	assert_array(gained).contains_exactly([&"wave_packet"])
	run.add_item(_item(&"standing_wave"))
	assert_array(gained).contains_exactly([&"wave_packet"])
	var spec := ProjectileSpec.new()
	run.build.modify_projectile(spec, Vector2.RIGHT, Vector2.ZERO)
	assert_int(spec.pierce).is_equal(1)
	assert_float(spec.wave_amplitude).is_greater(0.0)


func test_wavy_projectiles_move_sideways() -> void:
	var spec := ProjectileSpec.new()
	spec.wave_amplitude = 6.0
	var projectile: Projectile = auto_free(PROJECTILE_SCENE.instantiate())
	projectile.launch(spec, Vector2.ZERO, Vector2.RIGHT)
	var offset: Vector2 = projectile.wave_offset_at(spec.speed / (4.0 * spec.wave_frequency))
	assert_float(offset.x).is_equal_approx(0.0, 0.001)
	assert_float(absf(offset.y)).is_equal_approx(6.0, 0.001)
	spec.wave_amplitude = 0.0
	assert_vector(projectile.wave_offset_at(100.0)).is_equal(Vector2.ZERO)


func test_doppler_only_boosts_shots_in_the_movement_direction() -> void:
	var run := RunState.new("A", WILAS, CATALOG)
	run.add_item(_item(&"doppler_effect"))
	var forwards := ProjectileSpec.new()
	run.build.modify_projectile(forwards, Vector2.RIGHT, Vector2(300.0, 0.0))
	assert_float(forwards.damage).is_equal_approx(5.0 * 1.3, 0.001)
	var backwards := ProjectileSpec.new()
	run.build.modify_projectile(backwards, Vector2.LEFT, Vector2(300.0, 0.0))
	assert_float(backwards.damage).is_equal(5.0)


func test_half_life_makes_shots_apply_unstable() -> void:
	var run := RunState.new("A", WILAS, CATALOG)
	run.add_item(_item(&"half_life"))
	var spec := ProjectileSpec.new()
	run.build.modify_projectile(spec, Vector2.UP, Vector2.ZERO)
	assert_int(spec.statuses.size()).is_equal(1)
	assert_str(spec.statuses[0].id).is_equal(StatusEffectData.DECAY)


func test_standing_wave_only_while_still() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var run: RunState = player.run
	run.add_item(_item(&"standing_wave"))
	var base: float = run.stats.get_base(Stats.ATTACK_RATE)
	_step(player)
	assert_float(run.stats.get_value(Stats.ATTACK_RATE)).is_equal_approx(base * 1.5, 0.001)
	_steps(player, 10, _controls(1.0))
	assert_float(run.stats.get_value(Stats.ATTACK_RATE)).is_equal(base)


func test_photoelectric_fires_a_burst_every_ten_photons() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	player.set_projectile_parent(_world)
	player.run.add_item(_item(&"photoelectric_effect"))
	player.run.add_coins(9)
	assert_int(_projectiles().size()).is_equal(0)
	player.run.add_coins(1)
	assert_int(_projectiles().size()).is_equal(8)
	player.run.add_coins(25)
	assert_int(_projectiles().size()).is_equal(24)


func test_compton_effect_drops_photons_on_some_hits() -> void:
	var run := RunState.new("A", WILAS, CATALOG)
	var drops: Array[Vector2] = []
	run.build.spawner = func(object_id: StringName, at: Vector2) -> void:
		assert_str(object_id).is_equal(&"coin")
		drops.append(at)
	run.add_item(_item(&"compton_effect"))
	for i: int in 400:
		run.build.on_projectile_hit(
			DamageInfo.create(5.0, DamageInfo.Kind.PROJECTILE), Vector2(i, 0)
		)
	assert_int(drops.size()).is_between(15, 70)


func test_vacuum_energy_spawns_a_quantum_per_new_chunk() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var run: RunState = player.run
	var spawned: Array[StringName] = []
	run.build.spawner = func(object_id: StringName, _at: Vector2) -> void: spawned.append(object_id)
	run.add_item(_item(&"vacuum_energy"))
	run.enter_chunk(2)
	assert_array(spawned).contains_exactly([&"heal_pickup", &"heal_pickup"])
	run.enter_chunk(2)
	run.enter_chunk(1)
	assert_int(spawned.size()).is_equal(2)


func test_operators_swap_and_recharge_by_chunks() -> void:
	var run := RunState.new("A", WILAS, CATALOG)
	var zeno: ItemData = _item(&"zeno_effect")
	var collapse: ItemData = _item(&"collapse")
	assert_object(run.add_item(zeno)).is_null()
	assert_bool(run.build.is_active_ready()).is_true()
	assert_object(run.add_item(collapse)).is_same(zeno)
	assert_object(run.build.active_item).is_same(collapse)
	assert_bool(run.build.has_item(&"zeno_effect")).is_false()
	run.build.active_charge = 0
	assert_bool(run.build.use_active()).is_false()
	for index: int in range(1, collapse.charge_chunks + 1):
		run.enter_chunk(index)
	assert_int(run.build.active_charge).is_equal(collapse.charge_chunks)
	run.enter_chunk(10)
	assert_int(run.build.active_charge).is_equal(collapse.charge_chunks)


func test_zeno_freezes_the_enemies_on_screen() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var run: RunState = player.run
	run.add_item(_item(&"zeno_effect"))
	var view: Rect2 = run.build.get_view_rect()
	var seen: Enemy = _enemy(view.get_center())
	var unseen: Enemy = _enemy(view.end + Vector2(500.0, 500.0))
	assert_bool(player.run.build.use_active()).is_true()
	assert_bool(seen.statuses.has(StatusEffectData.OBSERVED)).is_true()
	assert_float(seen.get_time_scale()).is_equal(0.0)
	assert_bool(unseen.statuses.has(StatusEffectData.OBSERVED)).is_false()
	assert_int(run.build.active_charge).is_equal(0)


func test_collapse_destroys_enemy_projectiles_on_screen() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	player.run.add_item(_item(&"collapse"))
	var spec := ProjectileSpec.new()
	spec.team = ProjectileSpec.Team.ENEMY
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(spec, player.run.build.get_view_rect().get_center(), Vector2.LEFT)
	_world.add_child(projectile)
	assert_bool(projectile.is_in_group(Projectile.ENEMY_GROUP)).is_true()
	assert_bool(player.run.build.use_active()).is_true()
	assert_bool(projectile.is_done()).is_true()


func test_player_uses_the_operator_with_its_action() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	player.run.add_item(_item(&"zeno_effect"))
	var input := PlayerInput.new()
	input.use_active_pressed = true
	_step(player, input)
	assert_int(player.run.build.active_charge).is_equal(0)


func _item(id: StringName) -> ItemData:
	var item: ItemData = CATALOG.get_item(id)
	assert_object(item).override_failure_message("Falta %s" % id).is_not_null()
	return item


func _enemy(at: Vector2) -> Enemy:
	var enemy: Enemy = FREE_NEUTRON.instantiate()
	enemy.position = at
	_world.add_child(enemy)
	return enemy


func _projectiles() -> Array[Node]:
	return _world.get_children().filter(func(node: Node) -> bool: return node is Projectile)
