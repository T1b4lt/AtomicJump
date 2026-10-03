extends GdUnitTestSuite

## Tests de los recogibles: avisan por Events y la partida en curso los suma.

const COIN_SCENE: PackedScene = preload("res://items/pickups/coin/coin.tscn")
const KEY_SCENE: PackedScene = preload("res://items/pickups/key/key.tscn")
const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")

var _saved_run: RunState


func before_test() -> void:
	_saved_run = RunManager.run


func after_test() -> void:
	RunManager.run = _saved_run


func test_coin_and_key_add_to_the_run() -> void:
	var run: RunState = RunManager.start_run(123456789)
	var player: Player = auto_free(PLAYER_SCENE.instantiate())
	var coin: Coin = auto_free(COIN_SCENE.instantiate())
	var key: KeyPickup = auto_free(KEY_SCENE.instantiate())
	coin._on_body_entered(player)
	key._on_body_entered(player)
	assert_int(run.coins).is_equal(1)
	assert_int(run.keys).is_equal(1)
	assert_bool(coin.is_queued_for_deletion()).is_true()


func test_other_bodies_are_ignored() -> void:
	var run: RunState = RunManager.start_run(123456789)
	var coin: Coin = auto_free(COIN_SCENE.instantiate())
	var body: Node2D = auto_free(Node2D.new())
	coin._on_body_entered(body)
	assert_int(run.coins).is_equal(0)
