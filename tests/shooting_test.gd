extends "res://tests/support/player_suite.gd"

## Tests del disparo: Shooter (frecuencia, alcance, carga), proyectiles
## (herencia de velocidad, alcance, paredes, perforación) y el disparo del
## jugador (retroceso hacia abajo, nada de disparar durante el Túnel).

const PROJECTILE_SCENE: PackedScene = preload("res://combat/projectile.tscn")
const ORBITAL_ELECTRON: PackedScene = preload(
	"res://actors/enemies/orbital_electron/orbital_electron.tscn"
)


func test_snaps_to_four_directions() -> void:
	assert_vector(Shooter.snap_direction(Vector2(0.3, -0.9))).is_equal(Vector2.UP)
	assert_vector(Shooter.snap_direction(Vector2(-1.0, 0.2))).is_equal(Vector2.LEFT)
	assert_vector(Shooter.snap_direction(Vector2(0.7, 0.7))).is_equal(Vector2.DOWN)
	assert_vector(Shooter.snap_direction(Vector2.ZERO)).is_equal(Vector2.ZERO)


func test_spec_and_rate_come_from_the_stats() -> void:
	var stats := Stats.new(WILAS.base_stats)
	var shooter: Shooter = _shooter(stats)
	var spec: ProjectileSpec = shooter.make_spec()
	assert_float(spec.damage).is_equal(stats.get_value(Stats.ATTACK_POWER))
	assert_float(spec.attack_range).is_equal(stats.get_value(Stats.ATTACK_RANGE))
	assert_int(spec.team).is_equal(ProjectileSpec.Team.PLAYER)

	assert_object(shooter.try_shoot(Vector2.RIGHT)).is_not_null()
	assert_object(shooter.try_shoot(Vector2.RIGHT)).is_null()
	var cooldown: float = Shooter.cooldown_for(stats.get_value(Stats.ATTACK_RATE))
	assert_float(shooter.cooldown_left).is_equal_approx(cooldown, 0.0001)
	shooter.tick(cooldown)
	assert_object(shooter.try_shoot(Vector2.UP)).is_not_null()


func test_more_attack_rate_shoots_more_often() -> void:
	var stats := Stats.new(WILAS.base_stats)
	var before: float = Shooter.cooldown_for(stats.get_value(Stats.ATTACK_RATE))
	stats.add_modifier(StatModifier.create(Stats.ATTACK_RATE, StatModifier.Type.MULT, 1.0, &"t"))
	assert_float(Shooter.cooldown_for(stats.get_value(Stats.ATTACK_RATE))).is_less(before)


func test_projectile_inherits_part_of_the_shooter_velocity() -> void:
	var shooter: Shooter = _shooter(Stats.new(WILAS.base_stats))
	var projectile: Projectile = shooter.try_shoot(Vector2.UP, Vector2(200, 0))
	assert_float(projectile.velocity.x).is_equal(200.0 * shooter.inherit_velocity_ratio)
	assert_float(projectile.velocity.y).is_equal(-shooter.projectile_speed)


func test_projectile_layers_depend_on_its_team() -> void:
	var spec := ProjectileSpec.new()
	var projectile: Projectile = _projectile(spec, Vector2.ZERO, Vector2.RIGHT)
	assert_bool(projectile.get_collision_layer_value(PhysicsLayers.PLAYER_PROJECTILES)).is_true()
	assert_bool(projectile.get_collision_mask_value(PhysicsLayers.ENEMIES)).is_true()
	spec.team = ProjectileSpec.Team.ENEMY
	projectile = _projectile(spec, Vector2.ZERO, Vector2.RIGHT)
	assert_bool(projectile.get_collision_layer_value(PhysicsLayers.ENEMY_PROJECTILES)).is_true()
	assert_bool(projectile.get_collision_mask_value(PhysicsLayers.PLAYER)).is_true()


func test_projectile_fades_out_after_its_range() -> void:
	var spec := ProjectileSpec.new()
	spec.attack_range = 100.0
	var projectile: Projectile = _projectile(spec, Vector2(0, -2000), Vector2.RIGHT)
	for _frame: int in 6:
		projectile._physics_process(DT)
	assert_bool(projectile.is_done()).is_false()
	for _frame: int in 2:
		projectile._physics_process(DT)
	assert_bool(projectile.is_done()).is_true()
	assert_float(projectile.travelled).is_greater_equal(spec.attack_range)


func test_projectile_stops_on_walls_but_not_on_one_way_platforms() -> void:
	_add_platform(Vector2(0, -100), true, 300.0, 14.0)
	_add_platform(Vector2(0, -300), false, 300.0, 14.0)
	await get_tree().physics_frame
	var projectile: Projectile = _projectile(ProjectileSpec.new(), Vector2(0, 0), Vector2.UP)
	await get_tree().physics_frame
	for _frame: int in 30:
		projectile._physics_process(DT)
	assert_bool(projectile.is_done()).is_true()
	# It stopped on the solid platform, past the one-way one
	assert_float(projectile.global_position.y).is_equal_approx(-286.0, 1.0)


func test_projectile_stops_at_its_first_target_unless_it_pierces() -> void:
	var projectile: Projectile = _projectile(ProjectileSpec.new(), Vector2.ZERO, Vector2.RIGHT)
	var first: Enemy = _enemy(Vector2(-500, -500))
	var second: Enemy = _enemy(Vector2(-500, -500))
	projectile._on_area_entered(first.hurtbox)
	projectile._on_area_entered(second.hurtbox)
	assert_bool(projectile.is_done()).is_true()
	assert_float(first.health.hp).is_less(first.health.max_hp)
	assert_float(second.health.hp).is_equal(second.health.max_hp)

	var spec := ProjectileSpec.new()
	spec.pierce = 1
	projectile = _projectile(spec, Vector2.ZERO, Vector2.RIGHT)
	projectile._on_area_entered(first.hurtbox)
	assert_bool(projectile.is_done()).is_false()
	projectile._on_area_entered(second.hurtbox)
	assert_bool(projectile.is_done()).is_true()
	assert_float(second.health.hp).is_less(second.health.max_hp)


func test_player_shoots_with_the_shoot_direction() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	player.set_projectile_parent(_world)
	var shots: Array[Vector2] = []
	player.shot.connect(func(direction: Vector2) -> void: shots.append(direction))
	_step(player, _shoot(Vector2.LEFT))
	assert_array(shots).contains_exactly([Vector2.LEFT])
	assert_float(player.facing).is_equal(-1.0)
	var projectiles: Array[Node] = _world.get_children().filter(
		func(node: Node) -> bool: return node is Projectile
	)
	assert_int(projectiles.size()).is_equal(1)
	# Holding the direction keeps shooting at the attack rate
	_steps(player, roundi(player.get_shooter().cooldown_left / DT) + 1, _shoot(Vector2.LEFT))
	assert_int(shots.size()).is_equal(2)


func test_shooting_down_in_the_air_slows_the_fall_without_rising() -> void:
	_add_floor()
	var player: Player = await _add_player(Vector2(0, -800))
	player.set_projectile_parent(_world)
	_steps(player, 20)
	var falling: float = player.velocity.y
	assert_float(falling).is_greater(player.movement.shoot_down_recoil)
	_step(player, _shoot(Vector2.DOWN))
	var without_shot: float = falling + player.movement.gravity_for(falling) * DT
	assert_float(player.velocity.y).is_equal_approx(
		without_shot - player.movement.shoot_down_recoil, 0.01
	)
	# Never upwards, however many shots
	for _shot: int in 10:
		player.get_shooter().cooldown_left = 0.0
		_step(player, _shoot(Vector2.DOWN))
	assert_float(player.velocity.y).is_greater_equal(0.0)


func test_cannot_shoot_during_the_tunnel() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	player.set_projectile_parent(_world)
	_step(player, _controls(1.0, false, false, false, true))
	var input: PlayerInput = _shoot(Vector2.RIGHT)
	_step(player, input)
	assert_float(player.get_shooter().cooldown_left).is_equal(0.0)


func _shoot(direction: Vector2) -> PlayerInput:
	return PlayerInput.create(0.0, false, false, false, false, direction)


func _shooter(stats: Stats) -> Shooter:
	var shooter: Shooter = auto_free(Shooter.new())
	shooter.stats = stats
	shooter.projectile_parent = _world
	_world.add_child(shooter)
	return shooter


func _projectile(spec: ProjectileSpec, at: Vector2, direction: Vector2) -> Projectile:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(spec, at, direction)
	_world.add_child(projectile)
	projectile.set_physics_process(false)
	return projectile


func _enemy(at: Vector2) -> Enemy:
	var enemy: Enemy = ORBITAL_ELECTRON.instantiate()
	enemy.position = at
	_world.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy
