extends "res://tests/support/player_suite.gd"

## Tests de los recogibles: fotones (1/5/10) y positrones avisan por Events y la
## partida en curso los suma; los fotones vuelan hacia el jugador; los cuantos de
## energía curan y esperan si la coherencia está llena.

const COIN_SCENE: PackedScene = preload("res://items/pickups/coin/coin.tscn")
const KEY_SCENE: PackedScene = preload("res://items/pickups/key/key.tscn")

var _saved_run: RunState


func before_test() -> void:
	super()
	_saved_run = RunManager.run


func after_test() -> void:
	RunManager.run = _saved_run


func test_coin_and_key_add_to_the_run() -> void:
	var run: RunState = RunManager.start_run("K7QX-2MPA")
	var player: Player = auto_free(PLAYER_SCENE.instantiate())
	var coin: Coin = auto_free(COIN_SCENE.instantiate())
	var key: KeyPickup = auto_free(KEY_SCENE.instantiate())
	coin._on_body_entered(player)
	key._on_body_entered(player)
	assert_int(run.coins).is_equal(1)
	assert_int(run.keys).is_equal(1)
	assert_bool(coin.is_queued_for_deletion()).is_true()


func test_photon_values() -> void:
	var run: RunState = RunManager.start_run("VALUES")
	var player: Player = auto_free(PLAYER_SCENE.instantiate())
	for object_id: StringName in [PickupScenes.COIN, PickupScenes.COIN_5, PickupScenes.COIN_10]:
		var coin: Coin = auto_free(PickupScenes.instantiate(object_id))
		assert_bool(coin.magnetic).is_true()
		coin.try_collect(player)
	assert_int(run.coins).is_equal(16)


func test_other_bodies_are_ignored() -> void:
	var run: RunState = RunManager.start_run("K7QX-2MPA")
	var coin: Coin = auto_free(COIN_SCENE.instantiate())
	var body: Node2D = auto_free(Node2D.new())
	coin._on_body_entered(body)
	assert_int(run.coins).is_equal(0)


func test_heal_waits_while_coherence_is_full() -> void:
	_add_floor()
	var player: Player = await _standing_player()
	var heal: HealPickup = auto_free(PickupScenes.instantiate(PickupScenes.HEAL))
	assert_bool(heal.try_collect(player)).is_false()
	player.run.take_damage(30.0)
	assert_bool(heal.try_collect(player)).is_true()
	assert_float(player.run.hp).is_equal(90.0)
	var big: HealPickup = auto_free(PickupScenes.instantiate(PickupScenes.HEAL_BIG))
	player.run.take_damage(80.0)
	big.try_collect(player)
	assert_float(player.run.hp).is_equal(60.0)


func test_photons_fly_to_the_player_inside_its_radius() -> void:
	RunManager.start_run("MAGNET")
	_add_floor()
	var player: Player = await _standing_player()
	var radius: float = player.get_pickup_radius()
	var near: Coin = PickupScenes.instantiate(PickupScenes.COIN)
	near.position = player.global_position + Vector2(radius - 10.0, 0.0)
	_world.add_child(near)
	var far: Coin = PickupScenes.instantiate(PickupScenes.COIN)
	far.position = player.global_position + Vector2(radius + 60.0, 0.0)
	_world.add_child(far)
	var far_start: Vector2 = far.global_position
	var start_distance: float = near.global_position.distance_to(player.global_position)
	near._physics_process(DT)
	near._physics_process(DT)
	far._physics_process(DT)
	assert_bool(near.attracted).is_true()
	assert_float(near.global_position.distance_to(player.global_position)).is_less(start_distance)
	assert_bool(far.attracted).is_false()
	assert_vector(far.global_position).is_equal(far_start)
