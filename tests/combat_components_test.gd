extends GdUnitTestSuite

## Tests de los componentes de combate: DamageInfo, HealthComponent, Hurtbox,
## Hitbox, estados alterados y hitstop.

const DECAY: StatusEffectData = preload("res://data/statuses/status_decay.tres")
const SLOW: StatusEffectData = preload("res://data/statuses/status_slow.tres")
const ROOT: StatusEffectData = preload("res://data/statuses/status_root.tres")


func test_damage_info_points_away_from_its_source() -> void:
	var info := DamageInfo.create(5.0, DamageInfo.Kind.CONTACT, &"x", Vector2(10, 0))
	assert_vector(info.direction_from_source(Vector2(20, 0))).is_equal(Vector2.RIGHT)
	assert_vector(DamageInfo.create(5.0).direction_from_source(Vector2.ONE)).is_equal(Vector2.ZERO)


func test_health_takes_hits_and_dies_once() -> void:
	var health: HealthComponent = _health(10.0)
	var died: Array[DamageInfo] = []
	health.died.connect(func(info: DamageInfo) -> void: died.append(info))
	assert_bool(health.take_hit(DamageInfo.create(4.0))).is_true()
	assert_float(health.hp).is_equal(6.0)
	assert_bool(health.take_hit(DamageInfo.create(100.0, DamageInfo.Kind.CONTACT, &"a"))).is_true()
	assert_float(health.hp).is_equal(0.0)
	assert_bool(health.take_hit(DamageInfo.create(1.0))).is_false()
	assert_int(died.size()).is_equal(1)
	assert_str(died[0].source_id).is_equal(&"a")


func test_health_invulnerability_ignores_hits_but_not_status_ticks() -> void:
	var health: HealthComponent = _health(10.0)
	health.invulnerability_time = 0.5
	health.take_hit(DamageInfo.create(1.0))
	assert_bool(health.is_invulnerable()).is_true()
	assert_bool(health.take_hit(DamageInfo.create(1.0))).is_false()
	var tick := DamageInfo.create(1.0, DamageInfo.Kind.STATUS)
	tick.ignores_invulnerability = true
	assert_bool(health.take_hit(tick)).is_true()
	assert_float(health.hp).is_equal(8.0)
	health._physics_process(0.5)
	assert_bool(health.is_invulnerable()).is_false()


func test_hurtbox_passes_hits_to_its_health_or_its_handler() -> void:
	var hurtbox: Hurtbox = auto_free(Hurtbox.new())
	hurtbox.health = _health(10.0)
	var received: Array[DamageInfo] = []
	hurtbox.hit_received.connect(func(info: DamageInfo) -> void: received.append(info))
	assert_bool(hurtbox.receive(DamageInfo.create(3.0))).is_true()
	assert_float(hurtbox.health.hp).is_equal(7.0)
	hurtbox.handler = func(_info: DamageInfo) -> bool: return false
	assert_bool(hurtbox.receive(DamageInfo.create(3.0))).is_false()
	assert_float(hurtbox.health.hp).is_equal(7.0)
	assert_int(received.size()).is_equal(1)


func test_hitbox_builds_its_damage_info() -> void:
	var hitbox: Hitbox = _hitbox()
	hitbox.damage = 7.0
	hitbox.kind = DamageInfo.Kind.HAZARD
	hitbox.source_id = &"spike"
	hitbox.knockback = 50.0
	hitbox.statuses = [DECAY]
	hitbox.position = Vector2(3, 4)
	var info: DamageInfo = hitbox.make_damage()
	assert_float(info.amount).is_equal(7.0)
	assert_int(info.kind).is_equal(DamageInfo.Kind.HAZARD)
	assert_str(info.source_id).is_equal(&"spike")
	assert_float(info.knockback).is_equal(50.0)
	assert_vector(info.source_position).is_equal(Vector2(3, 4))
	assert_int(info.statuses.size()).is_equal(1)


func test_continuous_hitbox_keeps_hitting_while_in_contact() -> void:
	var hitbox: Hitbox = _hitbox()
	var hurtbox: Hurtbox = _hurtbox(100.0)
	hitbox._on_area_entered(hurtbox)
	hitbox._physics_process(0.0)
	assert_float(hurtbox.health.hp).is_equal(100.0 - 2.0 * hitbox.damage)
	hitbox._on_area_exited(hurtbox)
	hitbox._physics_process(0.0)
	assert_float(hurtbox.health.hp).is_equal(100.0 - 2.0 * hitbox.damage)


func test_single_hit_hitbox_hits_each_target_once_up_to_its_limit() -> void:
	var hitbox: Hitbox = _hitbox()
	hitbox.continuous = false
	hitbox.max_hits = 2
	var first: Hurtbox = _hurtbox(100.0)
	var second: Hurtbox = _hurtbox(100.0)
	var third: Hurtbox = _hurtbox(100.0)
	assert_bool(hitbox.hit(first)).is_true()
	assert_bool(hitbox.hit(first)).is_false()
	assert_bool(hitbox.hit(second)).is_true()
	assert_bool(hitbox.is_spent()).is_true()
	assert_bool(hitbox.hit(third)).is_false()
	assert_float(third.health.hp).is_equal(100.0)


func test_decay_stacks_and_deals_damage_over_time() -> void:
	var statuses: StatusEffects = _statuses(100.0)
	statuses.apply(DECAY)
	statuses.apply(DECAY)
	assert_int(statuses.get_stacks(StatusEffectData.DECAY)).is_equal(2)
	statuses.tick(DECAY.tick_interval)
	assert_float(statuses.health.hp).is_equal(100.0 - 2.0 * DECAY.damage_per_tick)
	for _i: int in DECAY.max_stacks + 3:
		statuses.apply(DECAY)
	assert_int(statuses.get_stacks(StatusEffectData.DECAY)).is_equal(DECAY.max_stacks)


func test_statuses_expire_after_their_duration() -> void:
	var statuses: StatusEffects = _statuses(100.0)
	var removed: Array[StringName] = []
	statuses.status_removed.connect(func(id: StringName) -> void: removed.append(id))
	statuses.apply(SLOW)
	statuses.tick(SLOW.duration - 0.1)
	assert_bool(statuses.has(StatusEffectData.SLOW)).is_true()
	statuses.tick(0.2)
	assert_bool(statuses.has(StatusEffectData.SLOW)).is_false()
	assert_array(removed).contains_exactly([StatusEffectData.SLOW])


func test_slow_and_root_change_the_speed_multiplier() -> void:
	var statuses: StatusEffects = _statuses(100.0)
	assert_float(statuses.get_speed_multiplier()).is_equal(1.0)
	assert_object(statuses.get_tint()).is_equal(Color.WHITE)
	statuses.apply(SLOW)
	assert_float(statuses.get_speed_multiplier()).is_equal(SLOW.speed_multiplier)
	assert_object(statuses.get_tint()).is_equal(Palette.FAMILY_GRAVITY)
	statuses.apply(ROOT)
	assert_float(statuses.get_speed_multiplier()).is_equal(0.0)


func test_status_data_ids_match_their_files() -> void:
	assert_str(DECAY.id).is_equal(StatusEffectData.DECAY)
	assert_str(SLOW.id).is_equal(StatusEffectData.SLOW)
	assert_str(ROOT.id).is_equal(StatusEffectData.ROOT)


func test_hit_stop_slows_time_and_restores_it() -> void:
	var hit_stop: HitStop = auto_free(HitStop.new())
	add_child(hit_stop)
	hit_stop.stop(0.05)
	assert_bool(hit_stop.is_stopped()).is_true()
	assert_float(Engine.time_scale).is_equal(hit_stop.stopped_time_scale)
	await await_millis(120)
	assert_float(Engine.time_scale).is_equal(1.0)
	# Leaving the tree in the middle of a stop restores the speed
	hit_stop.stop(1.0)
	remove_child(hit_stop)
	assert_float(Engine.time_scale).is_equal(1.0)


func _health(max_hp: float) -> HealthComponent:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	health.setup(max_hp)
	return health


func _hurtbox(max_hp: float) -> Hurtbox:
	var hurtbox: Hurtbox = auto_free(Hurtbox.new())
	hurtbox.health = _health(max_hp)
	return hurtbox


func _hitbox() -> Hitbox:
	var hitbox: Hitbox = auto_free(Hitbox.new())
	add_child(hitbox)
	return hitbox


func _statuses(max_hp: float) -> StatusEffects:
	var statuses: StatusEffects = auto_free(StatusEffects.new())
	statuses.health = _health(max_hp)
	add_child(statuses)
	return statuses
