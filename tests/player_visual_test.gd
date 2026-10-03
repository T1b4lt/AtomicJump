extends GdUnitTestSuite

## Tests del aspecto de Wilas: órbita del electrón, expresiones según el estado
## y squash & stretch que vuelve a la escala normal.

const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")


func test_electron_passes_behind_the_core_in_the_upper_half() -> void:
	assert_bool(PlayerVisual.is_electron_behind(-PI / 2.0)).is_true()
	assert_bool(PlayerVisual.is_electron_behind(PI / 2.0)).is_false()
	# The tilted orbital (-25°) is higher on the right
	var right: Vector2 = PlayerVisual.electron_position(0.0)
	assert_float(right.x).is_greater(0.0)
	assert_float(right.y).is_less(0.0)
	assert_float(right.length()).is_equal_approx(PlayerVisual.ORBIT_RADII.x, 0.01)


func test_expression_follows_the_state() -> void:
	var visual: PlayerVisual = _visual()
	visual.set_state(Player.State.JUMP)
	assert_str(visual.get_expression()).is_equal("jump")
	visual.set_state(Player.State.DASH)
	assert_str(visual.get_expression()).is_equal("focus")
	visual.set_state(Player.State.HURT)
	assert_str(visual.get_expression()).is_equal("hurt")


func test_landing_shows_joy_then_back_to_neutral() -> void:
	var visual: PlayerVisual = _visual()
	visual.set_state(Player.State.IDLE)
	visual.play_land()
	assert_str(visual.get_expression()).is_equal("happy")
	visual._process(visual.happy_time + 0.01)
	assert_bool(visual.get_expression() in [&"neutral", &"blink"]).is_true()


func test_squash_returns_to_normal() -> void:
	var visual: PlayerVisual = _visual()
	visual.play_jump(false)
	assert_vector(visual.squash).is_equal(visual.jump_stretch)
	await get_tree().create_timer(visual.stretch_time + 0.1).timeout
	assert_vector(visual.squash).is_equal_approx(Vector2.ONE, Vector2(0.01, 0.01))


func test_parts_glow_in_hdr() -> void:
	var visual: PlayerVisual = _visual()
	var core: Sprite2D = visual.get_node("%Core")
	var electron: Sprite2D = visual.get_node("%Electron")
	assert_float(core.self_modulate.g).is_greater(1.0)
	assert_float(electron.self_modulate.r).is_greater(1.0)


func _visual() -> PlayerVisual:
	var player: Player = auto_free(PLAYER_SCENE.instantiate())
	add_child(player)
	player.set_physics_process(false)
	return player.get_node("%Visual")
