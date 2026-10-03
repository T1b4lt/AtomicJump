extends GdUnitTestSuite

## Tests de la cámara: sigue al jugador con look-ahead vertical y respeta los
## límites laterales e inferior.

const VIEW: Vector2 = Vector2(1280, 720)


func test_goal_sits_above_the_target() -> void:
	var camera: PlayerCamera = _camera()
	camera.area_left = -5000.0
	camera.area_right = 5000.0
	var goal: Vector2 = camera.compute_goal(Vector2(100, -300), 0.0, VIEW)
	assert_vector(goal).is_equal(Vector2(100, -300 + camera.vertical_bias))


func test_narrow_area_is_centered() -> void:
	var camera: PlayerCamera = _camera()
	camera.area_left = 0.0
	camera.area_right = 1160.0
	assert_float(camera.clamp_to_area(Vector2(50, 0), VIEW).x).is_equal(580.0)
	assert_float(camera.clamp_to_area(Vector2(1100, 0), VIEW).x).is_equal(580.0)


func test_wide_area_clamps_the_sides() -> void:
	var camera: PlayerCamera = _camera()
	camera.area_left = 0.0
	camera.area_right = 3000.0
	assert_float(camera.clamp_to_area(Vector2(100, 0), VIEW).x).is_equal(640.0)
	assert_float(camera.clamp_to_area(Vector2(1500, 0), VIEW).x).is_equal(1500.0)
	assert_float(camera.clamp_to_area(Vector2(2900, 0), VIEW).x).is_equal(2360.0)


func test_never_shows_below_the_bottom() -> void:
	var camera: PlayerCamera = _camera()
	camera.area_bottom = 670.0
	assert_float(camera.clamp_to_area(Vector2(0, 600), VIEW).y).is_equal(310.0)
	assert_float(camera.clamp_to_area(Vector2(0, -900), VIEW).y).is_equal(-900.0)


func test_looks_ahead_where_the_target_moves() -> void:
	var falling: Vector2 = await _settle(820.0)
	var rising: Vector2 = await _settle(-450.0)
	var still: Vector2 = await _settle(0.0)
	assert_float(falling.y).is_greater(still.y)
	assert_float(rising.y).is_less(still.y)


func test_snaps_to_the_target() -> void:
	var camera: PlayerCamera = _camera()
	var target: Node2D = auto_free(Node2D.new())
	add_child(target)
	target.global_position = Vector2(300, -2000)
	camera.area_right = 5000.0
	camera.target = target
	camera.snap_to_target()
	assert_float(camera.global_position.y).is_equal(-2000.0 + camera.vertical_bias)


## Camera y after following for a while a body moving at a fixed vertical speed
## that stays in place (only its velocity matters for the look-ahead).
func _settle(vertical_speed: float) -> Vector2:
	var camera: PlayerCamera = _camera()
	var body: CharacterBody2D = auto_free(CharacterBody2D.new())
	add_child(body)
	body.velocity = Vector2(0, vertical_speed)
	camera.target = body
	camera.set_physics_process(false)
	for _frame: int in 300:
		camera._physics_process(1.0 / 60.0)
	return camera.global_position


func _camera() -> PlayerCamera:
	var camera: PlayerCamera = auto_free(PlayerCamera.new())
	add_child(camera)
	return camera
