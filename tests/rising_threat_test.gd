extends GdUnitTestSuite

## Tests de la Decoherencia: velocidad (base, goma elástica, cerca), pausa, daño
## del 25 % y reaparición en una plataforma segura por encima.

const THREAT_SCENE: PackedScene = preload("res://world/rising_threat/rising_threat.tscn")
const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")
const WILAS: CharacterData = preload("res://data/characters/wilas.tres")
const DT: float = 1.0 / 60.0

var _world: Node2D = null


func before_test() -> void:
	_world = auto_free(Node2D.new())
	add_child(_world)


func test_speed_is_the_base_at_a_normal_distance() -> void:
	var threat: RisingThreat = _threat()
	assert_float(threat.speed_for_distance(500.0)).is_equal(threat.base_speed)


func test_rubber_band_speeds_up_when_far_and_has_a_cap() -> void:
	var threat: RisingThreat = _threat()
	var far: float = threat.rubber_band_distance + 100.0
	assert_float(threat.speed_for_distance(far)).is_equal(
		threat.base_speed + 100.0 * threat.rubber_band_gain
	)
	assert_float(threat.speed_for_distance(100000.0)).is_equal(threat.max_speed)
	# Speed never drops as the distance grows
	var last: float = 0.0
	for distance: float in [0.0, 50.0, 200.0, 600.0, 1000.0, 2000.0, 5000.0]:
		var speed: float = threat.speed_for_distance(distance)
		assert_float(speed).is_greater_equal(last)
		last = speed


func test_slows_down_near_the_player() -> void:
	var threat: RisingThreat = _threat()
	assert_float(threat.speed_for_distance(0.0)).is_equal(
		threat.base_speed * threat.near_speed_ratio
	)
	assert_float(threat.speed_for_distance(threat.near_distance / 2.0)).is_less(threat.base_speed)


func test_rises_towards_the_player_and_stops_when_paused() -> void:
	var player: Player = await _player(Vector2(0, -500))
	var threat: RisingThreat = _threat(Vector2(0, 0))
	threat.setup(player)
	threat._physics_process(1.0)
	assert_float(threat.global_position.y).is_less(0.0)
	var y: float = threat.global_position.y
	threat.paused = true
	threat._physics_process(1.0)
	assert_float(threat.global_position.y).is_equal(y)
	assert_float(threat.speed).is_equal(0.0)


func test_distance_is_positive_above_the_front() -> void:
	var threat: RisingThreat = _threat(Vector2(0, 100))
	assert_float(threat.distance_to(-50.0)).is_equal(150.0)
	assert_float(threat.distance_to(200.0)).is_equal(-100.0)


func test_hit_takes_a_quarter_of_max_coherence_ignoring_defense_and_invulnerability() -> void:
	_add_floor(Vector2(0, -300))
	var player: Player = await _player(Vector2(0, 0))
	player.run.stats.add_modifier(
		StatModifier.create(Stats.DEFENSE, StatModifier.Type.ADD, 0.5, &"a")
	)
	player.invulnerability_left = 1.0
	var threat: RisingThreat = _threat(Vector2(0, 10))
	threat.hit(player)
	assert_float(player.run.hp).is_equal(75.0)


func test_hit_respawns_at_the_last_safe_spot_above_the_front() -> void:
	_add_floor(Vector2(0, -300))
	_add_floor(Vector2(0, -600))
	await get_tree().physics_frame
	var player: Player = await _player(Vector2(0, 0))
	player.safe_spots = PackedVector2Array([Vector2(0, -620), Vector2(0, -320), Vector2(0, 50)])
	var threat: RisingThreat = _threat(Vector2(0, 0))
	threat.hit(player)
	# The newest spot is under the front: the next one above it wins
	assert_vector(player.global_position).is_equal(Vector2(0, -320))
	assert_bool(player.is_invulnerable()).is_true()


func test_spots_without_floor_are_skipped() -> void:
	_add_floor(Vector2(0, -600))
	await get_tree().physics_frame
	var player: Player = await _player(Vector2(0, 0))
	player.safe_spots = PackedVector2Array([Vector2(0, -620), Vector2(0, -320)])
	var threat: RisingThreat = _threat(Vector2(0, 0))
	assert_vector(threat.find_respawn_spot(player)).is_equal(Vector2(0, -620))


func test_one_way_platforms_count_as_floor() -> void:
	_add_floor(Vector2(0, -300), true)
	await get_tree().physics_frame
	var player: Player = await _player(Vector2(0, 0))
	player.safe_spots = PackedVector2Array([Vector2(0, -320)])
	var threat: RisingThreat = _threat(Vector2(0, 0))
	assert_vector(threat.find_respawn_spot(player)).is_equal(Vector2(0, -320))


func test_without_valid_spots_scans_for_the_closest_floor_above() -> void:
	_add_floor(Vector2(200, -400))
	_add_floor(Vector2(200, -900))
	await get_tree().physics_frame
	var player: Player = await _player(Vector2(0, 0))
	player.safe_spots = PackedVector2Array()
	var threat: RisingThreat = _threat(Vector2(0, 0))
	threat.scan_left = 0.0
	threat.scan_right = 400.0
	var spot: Vector2 = threat.find_respawn_spot(player)
	assert_float(spot.y).is_equal_approx(-400.0 - player.get_feet_offset(), 0.5)
	assert_float(spot.x).is_between(100.0, 300.0)


func test_a_lethal_hit_does_not_respawn() -> void:
	var player: Player = await _player(Vector2(0, 0))
	player.run.take_damage(90.0)
	var threat: RisingThreat = _threat(Vector2(0, 10))
	threat.hit(player)
	assert_bool(player.run.is_dead()).is_true()
	assert_int(player.state).is_equal(Player.State.DEAD)
	assert_vector(player.global_position).is_equal(Vector2.ZERO)


func test_is_on_the_rising_threat_layer_and_detects_the_player() -> void:
	var threat: RisingThreat = _threat()
	var hitbox: Area2D = threat.get_node("%Hitbox")
	assert_int(hitbox.collision_layer).is_equal(1 << (PhysicsLayers.RISING_THREAT - 1))
	assert_int(hitbox.collision_mask).is_equal(1 << (PhysicsLayers.PLAYER - 1))


func _threat(at: Vector2 = Vector2.ZERO) -> RisingThreat:
	var threat: RisingThreat = THREAT_SCENE.instantiate()
	threat.position = at
	_world.add_child(threat)
	threat.set_physics_process(false)
	return threat


func _player(at: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = at
	_world.add_child(player)
	player.set_physics_process(false)
	player.bind_run(RunState.new("A", WILAS))
	await get_tree().physics_frame
	return player


## Platform 200 px wide whose top center is at `top_center`.
func _add_floor(top_center: Vector2, one_way: bool = false) -> void:
	var body := StaticBody2D.new()
	var layer: int = PhysicsLayers.ONE_WAY_PLATFORMS if one_way else PhysicsLayers.WORLD
	body.collision_layer = 1 << (layer - 1)
	body.collision_mask = 0
	body.position = top_center + Vector2(0, 10)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(200, 20)
	shape.shape = rectangle
	shape.one_way_collision = one_way
	body.add_child(shape)
	_world.add_child(body)
