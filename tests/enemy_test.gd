extends "res://tests/support/player_suite.gd"

## Tests de los enemigos de la Capa K: datos y escalado, decisiones y caídas
## direccionadas por su hueco, daño en ambos sentidos, muerte (eventos,
## caídas, decaimiento del neutrón), patrulla, órbita y embestida, y su
## aparición en los huecos de los tramos.

const LAYER: LayerData = preload("res://data/layers/layer_k.tres")
const LADDER: PackedScene = preload("res://world/chunks/k/k_ladder.tscn")
const ORBITAL_ELECTRON: PackedScene = preload(
	"res://actors/enemies/orbital_electron/orbital_electron.tscn"
)
const FREE_NEUTRON: PackedScene = preload("res://actors/enemies/free_neutron/free_neutron.tscn")
const ALPHA_PARTICLE: PackedScene = preload(
	"res://actors/enemies/alpha_particle/alpha_particle.tscn"
)
const DECAY: StatusEffectData = preload("res://data/statuses/status_decay.tres")
const ROOT: StatusEffectData = preload("res://data/statuses/status_root.tres")
## Enemies of Layer K and their stats (docs/09-enemies.md): hp, damage.
const BESTIARY: Dictionary[StringName, Vector2] = {
	&"orbital_electron": Vector2(10, 10),
	&"free_neutron": Vector2(15, 10),
	&"alpha_particle": Vector2(30, 15),
}

var _saved_run: RunState


func before_test() -> void:
	super()
	_saved_run = RunManager.run


func after_test() -> void:
	RunManager.run = _saved_run


func test_bestiary_matches_the_design() -> void:
	for id: StringName in BESTIARY:
		var enemy: Enemy = auto_free(Chunk.OBJECT_SCENES[id].instantiate())
		assert_str(enemy.data.id).is_equal(id)
		assert_float(enemy.data.max_hp).is_equal(BESTIARY[id].x)
		assert_float(enemy.data.contact_damage).is_equal(BESTIARY[id].y)
		assert_str(tr(enemy.data.name_key)).is_not_equal(enemy.data.name_key)
		assert_str(tr(RunCounters.cause_key(id))).is_not_equal(RunCounters.cause_key(id))


func test_layer_k_fills_enemy_slots_with_its_enemies() -> void:
	var ground: Dictionary[StringName, float] = LAYER.get_slot_objects(Chunk.SLOT_ENEMY_GROUND)
	var air: Dictionary[StringName, float] = LAYER.get_slot_objects(Chunk.SLOT_ENEMY_AIR)
	assert_array(ground.keys()).contains_exactly_in_any_order(
		[Chunk.FREE_NEUTRON, Chunk.ALPHA_PARTICLE]
	)
	assert_array(air.keys()).contains_exactly([Chunk.ORBITAL_ELECTRON])
	assert_str(EnemyData.COIN_DROP).is_equal(Chunk.COIN)


func test_stats_scale_with_the_layer() -> void:
	var neutron: Enemy = auto_free(FREE_NEUTRON.instantiate())
	var data: EnemyData = neutron.data
	assert_float(data.get_max_hp(0)).is_equal(data.max_hp)
	assert_float(data.get_max_hp(2)).is_equal(data.max_hp * 1.5)
	assert_float(data.get_contact_damage(1)).is_equal(data.contact_damage * 1.25)


func test_drops_are_addressed_by_the_slot() -> void:
	var alpha: Enemy = auto_free(ALPHA_PARTICLE.instantiate())
	var data: EnemyData = alpha.data
	var rng := WorldRng.new(42)
	var dropped: int = 0
	for slot: int in 200:
		var address: Array = ["K", "main", 3, "slot_enemy_ground_%d" % slot]
		var drops: Array[StringName] = data.roll_drops(rng, address)
		assert_array(data.roll_drops(WorldRng.new(42), address)).is_equal(drops)
		if not drops.is_empty():
			dropped += 1
			assert_int(drops.size()).is_between(data.coin_drop_count.x, data.coin_drop_count.y)
	# About coin_drop_chance of them drop something
	assert_int(dropped).is_between(30, 90)
	# Raising the chance only adds drops (monotonic)
	for slot: int in 50:
		var address: Array = ["K", "main", 3, "slot_enemy_ground_%d" % slot]
		if not data.roll_drops(rng, address).is_empty():
			assert_array(data.roll_drops(rng, address, 2.0)).is_not_empty()


func test_ai_decisions_depend_on_the_slot_address() -> void:
	var rng := WorldRng.new(7)
	var phases: Array[float] = []
	for _i: int in 2:
		var enemy: Enemy = _spawn(ORBITAL_ELECTRON, Vector2(0, -500), rng, ["K", "main", 1, "a"])
		phases.append((enemy.behavior as OrbitBehavior).phase)
	var other: Enemy = _spawn(ORBITAL_ELECTRON, Vector2(0, -500), rng, ["K", "main", 1, "b"])
	assert_float(phases[0]).is_equal(phases[1])
	assert_float((other.behavior as OrbitBehavior).phase).is_not_equal(phases[0])


func test_orbital_electron_circles_its_spawn_point() -> void:
	var enemy: Enemy = _spawn(ORBITAL_ELECTRON, Vector2(100, -500))
	var orbit: OrbitBehavior = enemy.behavior
	assert_vector(orbit.center).is_equal(Vector2(100, -500))
	for _frame: int in 45:
		enemy._physics_process(DT)
		var offset: Vector2 = enemy.position - orbit.center
		var on_ellipse: float = (
			pow(offset.x / orbit.radii.x, 2.0) + pow(offset.y / orbit.radii.y, 2.0)
		)
		assert_float(on_ellipse).is_equal_approx(1.0, 0.01)
	# A full turn takes `period` seconds
	var start: float = orbit.phase
	for _frame: int in roundi(orbit.period / DT):
		enemy._physics_process(DT)
	assert_float(absf(angle_difference(orbit.phase, start))).is_less(0.01)


func test_player_shots_hurt_enemies_and_knock_them_back() -> void:
	var enemy: Enemy = _spawn(FREE_NEUTRON, Vector2(0, -500))
	var info := DamageInfo.create(5.0, DamageInfo.Kind.PROJECTILE, &"", Vector2(-100, -500))
	info.knockback = 100.0
	info.statuses = [DECAY]
	assert_bool(enemy.hurtbox.receive(info)).is_true()
	assert_float(enemy.health.hp).is_equal(enemy.data.max_hp - 5.0)
	assert_float(enemy.knockback_velocity.x).is_greater(0.0)
	assert_bool(enemy.statuses.has(StatusEffectData.DECAY)).is_true()


func test_root_stops_an_enemy() -> void:
	var enemy: Enemy = _spawn(ORBITAL_ELECTRON, Vector2(0, -500))
	enemy.statuses.apply(ROOT)
	var before: Vector2 = enemy.position
	for _frame: int in 10:
		enemy._physics_process(DT)
	assert_vector(enemy.position).is_equal(before)


func test_contact_hurts_the_player_and_is_the_cause_of_death() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var enemy: Enemy = _spawn(ALPHA_PARTICLE, player.global_position + Vector2(30, 0))
	enemy.contact_hitbox._on_area_entered(player.get_hurtbox())
	assert_float(player.run.hp).is_equal(player.run.get_max_hp() - enemy.data.contact_damage)
	assert_int(player.state).is_equal(Player.State.HURT)
	# Knocked back away from the enemy
	assert_float(player.velocity.x).is_less(0.0)
	player.run.take_damage(player.run.hp - 1.0)
	player._update_invulnerability(player.invulnerability_time)
	enemy.contact_hitbox._physics_process(0.0)
	assert_bool(player.run.is_dead()).is_true()
	assert_str(player.run.counters.death_cause).is_equal(&"alpha_particle")


func test_death_counts_the_kill_drops_loot_and_frees_the_enemy() -> void:
	var run: RunState = RunManager.start_run("KILLS")
	var chunk := Chunk.new()
	_world.add_child(chunk)
	# An address whose drop roll succeeds
	var address: Array = []
	var probe: Enemy = auto_free(ALPHA_PARTICLE.instantiate())
	var data: EnemyData = probe.data
	for slot: int in 100:
		address = ["K", "main", 1, "slot_%d" % slot]
		if not data.roll_drops(run.world_rng, address).is_empty():
			break
	chunk.set_rolls(run.world_rng)
	var enemy: Enemy = ALPHA_PARTICLE.instantiate()
	chunk.add_enemy(enemy, Vector2(0, -500), address)
	var killed: Array[StringName] = []
	enemy.died.connect(func(dead: Enemy) -> void: killed.append(dead.data.id))
	enemy.health.take_hit(DamageInfo.create(1000.0))
	assert_array(killed).contains_exactly([&"alpha_particle"])
	assert_int(run.counters.enemies_killed).is_equal(1)
	assert_int(run.counters.kills_by_enemy[&"alpha_particle"]).is_equal(1)
	assert_array(chunk.get_enemies()).is_empty()
	await get_tree().process_frame
	var coins: Array[Node] = chunk.get_children().filter(
		func(node: Node) -> bool: return node is Coin
	)
	assert_int(coins.size()).is_equal(data.roll_drops(run.world_rng, address).size())
	await await_millis(700)
	assert_bool(is_instance_valid(enemy)).is_false()


func test_free_neutron_decays_into_a_short_lived_electron() -> void:
	var chunk := Chunk.new()
	_world.add_child(chunk)
	chunk.set_rolls(WorldRng.new(1))
	var neutron: Enemy = FREE_NEUTRON.instantiate()
	chunk.add_enemy(neutron, Vector2(0, -500), ["K", "main", 1, "slot_enemy_ground_1"])
	neutron.health.take_hit(DamageInfo.create(1000.0))
	await get_tree().process_frame
	var products: Array[Enemy] = chunk.get_enemies()
	assert_int(products.size()).is_equal(1)
	var electron: Enemy = products[0]
	assert_str(electron.data.id).is_equal(&"decay_electron")
	# (a physics frame may have ticked since it appeared)
	assert_float(electron.lifetime).is_equal_approx(neutron.data.decay_lifetime, 0.1)
	assert_array(electron.address).is_equal(["K", "main", 1, "slot_enemy_ground_1", &"decay"])
	# It vanishes when its lifetime ends, without counting as a kill
	electron._physics_process(electron.lifetime)
	assert_bool(electron.is_dying()).is_true()


func test_free_neutron_patrols_without_falling_off() -> void:
	_add_platform(Vector2(0, 0), false, 200.0, 14.0)
	await get_tree().physics_frame
	var enemy: Enemy = _spawn(FREE_NEUTRON, Vector2(0, -2))
	enemy.set_physics_process(true)
	var patrol: PatrolBehavior = enemy.behavior
	var directions: Array[float] = [patrol.direction]
	for _frame: int in 600:
		await get_tree().physics_frame
		if patrol.direction != directions.back():
			directions.append(patrol.direction)
	assert_int(directions.size()).is_greater_equal(3)
	assert_float(absf(enemy.position.x)).is_less(100.0)
	assert_float(enemy.position.y).is_equal_approx(0.0, 2.0)


func test_alpha_particle_warns_then_charges_at_the_player_in_its_row() -> void:
	_add_floor()
	var player: Player = await _standing_player(Vector2(-300, FLOOR_Y - FEET))
	var enemy: Enemy = _spawn(ALPHA_PARTICLE, Vector2(100, FLOOR_Y))
	enemy.set_physics_process(true)
	var charge: ChargeBehavior = enemy.behavior
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_int(charge.phase).is_equal(ChargeBehavior.Phase.WARNING)
	assert_float(charge.direction).is_equal(-1.0)
	for _frame: int in roundi(charge.warning_time / DT) + 3:
		await get_tree().physics_frame
	assert_int(charge.phase).is_equal(ChargeBehavior.Phase.CHARGE)
	assert_bool(charge.speed_lines.visible).is_true()
	assert_float(enemy.velocity.x).is_less(-charge.charge_speed * 0.9)
	# A player out of its row is not seen
	player.global_position.y -= 200.0
	assert_bool(charge.sees_target(enemy)).is_false()


func test_chunk_spawns_enemies_in_their_slots() -> void:
	var chunk: Chunk = auto_free(LADDER.instantiate())
	_world.add_child(chunk)
	var plan: Dictionary[StringName, StringName] = {
		&"slot_enemy_ground_1": Chunk.FREE_NEUTRON, &"slot_enemy_air_1": Chunk.ORBITAL_ELECTRON
	}
	chunk.fill_slots(plan, ["K", "main", 2], WorldRng.new(3), 1)
	var enemies: Array[Enemy] = chunk.get_enemies()
	assert_int(enemies.size()).is_equal(2)
	for enemy: Enemy in enemies:
		assert_int(enemy.layer_index).is_equal(1)
		assert_float(enemy.health.max_hp).is_equal(enemy.data.get_max_hp(1))
		assert_array(enemy.address.slice(0, 3)).is_equal(["K", "main", 2])
	var neutrons: Array[Enemy] = enemies.filter(
		func(enemy: Enemy) -> bool: return enemy.data.id == Chunk.FREE_NEUTRON
	)
	var neutron: Enemy = neutrons[0]
	assert_vector(neutron.position).is_equal(
		(chunk.get_node(^"Slots/slot_enemy_ground_1") as Node2D).position
	)


func test_enemy_slots_use_the_enemy_domain() -> void:
	var slots: Dictionary[StringName, StringName] = {
		&"slot_enemy_ground_1": Chunk.SLOT_ENEMY_GROUND, &"slot_pickup_1": Chunk.SLOT_PICKUP
	}
	var rng := WorldRng.new(5)
	var key: Array = ["K", "main", 4]
	var plan: Dictionary[StringName, StringName] = SlotFiller.plan(rng, LAYER, key, slots, 100.0)
	assert_str(plan[&"slot_enemy_ground_1"]).is_equal(
		rng.pick_weighted(LAYER.enemy_ground_weights, &"enemy", key + [&"slot_enemy_ground_1"])
	)
	assert_str(SlotFiller.kind_domain(Chunk.SLOT_ENEMY_AIR)).is_equal(&"enemy")
	assert_str(SlotFiller.kind_domain(Chunk.SLOT_PICKUP)).is_equal(&"slot_kind")


func test_validator_requires_ground_enemy_slots_on_a_platform() -> void:
	var chunk: Chunk = auto_free(LADDER.instantiate())
	assert_array(ChunkValidator.validate(chunk)).is_empty()
	var slot: Node2D = chunk.get_node(^"Slots/slot_enemy_ground_1")
	slot.position.y -= 64.0
	assert_str("\n".join(ChunkValidator.validate(chunk))).contains("must stand on a platform")


func _spawn(
	scene: PackedScene, at: Vector2, rng: WorldRng = null, address: Array = ["test"]
) -> Enemy:
	var enemy: Enemy = scene.instantiate()
	enemy.setup(address, rng)
	enemy.position = at
	_world.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy
