extends GdUnitTestSuite

## Base de los tests del jugador: un mundo de prueba con suelos y plataformas y
## helpers que simulan fotogramas de física con Player.physics_step().

const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")
const WILAS: CharacterData = preload("res://data/characters/wilas.tres")
const DT: float = 1.0 / 60.0
## Top of the test floor; the player stands on it with its origin FEET px above.
const FLOOR_Y: float = 20.0
const FEET: float = 20.0

var _world: Node2D = null


func before_test() -> void:
	_world = auto_free(Node2D.new())
	add_child(_world)


func _controls(
	move_axis: float = 0.0,
	jump_pressed: bool = false,
	jump_held: bool = false,
	down_held: bool = false,
	dash_pressed: bool = false
) -> PlayerInput:
	return PlayerInput.create(move_axis, jump_pressed, jump_held, down_held, dash_pressed)


func _step(player: Player, input: PlayerInput = null) -> void:
	player.physics_step(DT, input if input != null else PlayerInput.new())


func _steps(player: Player, frames: int, input: PlayerInput = null) -> void:
	for _frame: int in frames:
		_step(player, input)


## Wide solid floor whose top is at FLOOR_Y.
func _add_floor() -> StaticBody2D:
	return _add_platform(Vector2(0, FLOOR_Y), false, 4000.0, 40.0)


func _add_platform(
	top_center: Vector2, one_way: bool, width: float = 300.0, height: float = 14.0
) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 0
	body.set_collision_layer_value(
		PhysicsLayers.ONE_WAY_PLATFORMS if one_way else PhysicsLayers.WORLD, true
	)
	body.collision_mask = 0
	body.position = top_center + Vector2(0, height / 2.0)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, height)
	shape.shape = rectangle
	shape.one_way_collision = one_way
	body.add_child(shape)
	_world.add_child(body)
	return body


func _remove(body: StaticBody2D) -> void:
	body.queue_free()
	await get_tree().physics_frame


func _add_player(at: Vector2, max_jumps: int = 2) -> Player:
	var run := RunState.new("A", WILAS)
	var extra_jumps: float = max_jumps - run.stats.get_value(Stats.MAX_JUMPS)
	if extra_jumps != 0.0:
		run.stats.add_modifier(
			StatModifier.create(Stats.MAX_JUMPS, StatModifier.Type.ADD, extra_jumps, &"test")
		)
	var player: Player = PLAYER_SCENE.instantiate()
	player.position = at
	_world.add_child(player)
	player.set_physics_process(false)
	player.bind_run(run)
	# Let the physics server register the bodies before moving
	await get_tree().physics_frame
	return player


## A player already resting on the floor (one frame to detect it).
func _standing_player(at: Vector2 = Vector2(0, FLOOR_Y - FEET), max_jumps: int = 2) -> Player:
	var player: Player = await _add_player(at, max_jumps)
	_step(player)
	return player
