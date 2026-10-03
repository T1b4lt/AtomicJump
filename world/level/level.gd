class_name Level
extends Node2D
## Prototype level: a column of chunks chosen by the seed with PrototypeGenerator,
## a camera that follows the player and the Decoherence (RisingThreat) rising
## from below. Plays the run in RunManager and ends it when the player dies.

## Altitude units (pm) per chunk height (the prototype counted 11 per screen).
const ALTITUDE_UNITS_PER_CHUNK: float = 11.0
const PX_PER_UNIT: float = Chunk.HEIGHT / ALTITUDE_UNITS_PER_CHUNK

## Px below the bottom of the level where the Decoherence starts.
@export var threat_start_depth: float = 500.0
## Chunks kept ready above the top of the view.
@export var chunks_ahead: int = 1

var run: RunState = null
## Chunks in the world by index in the column (0 is the initial chunk).
var _chunks: Dictionary[int, Chunk] = {}
var _top_index: int = 0
var _start_y: float = 0.0
var _ending: bool = false

@onready var _camera: PlayerCamera = %Camera
@onready var _player: Player = %Player
@onready var _threat: RisingThreat = %RisingThreat
@onready var _hud: Hud = %Hud
@onready var _initial_chunk: Chunk = %InitialChunk


## Index in the column of the chunk that contains the world height `y`.
static func chunk_index_at(y: float) -> int:
	return floori((Chunk.HEIGHT - y) / Chunk.HEIGHT)


## World y of the top edge of the chunk at `index`.
static func chunk_top(index: int) -> float:
	return -Chunk.HEIGHT * index


func _ready() -> void:
	# Running the level scene on its own (F6) starts a random run
	run = RunManager.run if RunManager.has_run() else RunManager.start_run()
	_chunks[0] = _initial_chunk
	_place_objects(_initial_chunk, 0)

	_player.bind_run(run)
	_hud.bind_run(run)
	run.died.connect(_end_run)
	_start_y = _player.global_position.y

	_camera.area_left = 0.0
	_camera.area_right = Chunk.WIDTH
	_camera.area_bottom = Chunk.HEIGHT
	_camera.target = _player
	_camera.snap_to_target()

	_threat.position = Vector2(0.0, Chunk.HEIGHT + threat_start_depth)
	_threat.scan_left = Chunk.INNER_LEFT
	_threat.scan_right = Chunk.INNER_RIGHT
	_threat.setup(_player)
	_update_chunks()


func _physics_process(_delta: float) -> void:
	_threat.paused = is_safe_at(_player.global_position.y)
	_update_chunks()
	var height: float = (_start_y - _player.global_position.y) / PX_PER_UNIT
	if height > run.altitude:
		run.set_altitude(height)
	var feet_y: float = _player.global_position.y + _player.get_feet_offset()
	run.set_threat_distance(maxf(0.0, _threat.distance_to(feet_y)) / PX_PER_UNIT)


## Whether the chunk at the world height `y` is safe (the Decoherence stops).
func is_safe_at(y: float) -> bool:
	var chunk: Chunk = _chunks.get(chunk_index_at(y))
	return chunk != null and chunk.safe


## Creates the chunks up to `chunks_ahead` above the view and frees the ones
## left under both the Decoherence and the view (nobody can go back there).
func _update_chunks() -> void:
	var view_size: Vector2 = _camera.get_view_size()
	var view_top: float = _camera.global_position.y - view_size.y / 2.0
	while _top_index < chunk_index_at(view_top) + chunks_ahead:
		_top_index += 1
		_add_chunk(_top_index)
	var bottom_limit: float = maxf(
		_threat.global_position.y, _camera.global_position.y + view_size.y / 2.0
	)
	for index: int in _chunks.keys():
		if chunk_top(index) > bottom_limit:
			_chunks[index].queue_free()
			_chunks.erase(index)


func _add_chunk(index: int) -> void:
	var id: StringName = PrototypeGenerator.pick_chunk(run.world_rng, index)
	var chunk: Chunk = PrototypeGenerator.CHUNK_SCENES[id].instantiate() as Chunk
	chunk.position.y = chunk_top(index)
	add_child(chunk)
	_chunks[index] = chunk
	_place_objects(chunk, index)


func _place_objects(chunk: Chunk, index: int) -> void:
	chunk.place_objects(
		PrototypeGenerator.plan_objects(run.world_rng, index, chunk.get_slot_count())
	)


## Ends the run once and shows the end screen. The level stops while it fades.
func _end_run() -> void:
	if _ending:
		return
	_ending = true
	process_mode = Node.PROCESS_MODE_DISABLED
	var ended: RunState = RunManager.end_run()
	SceneRouter.go_to(SceneRouter.GAME_OVER, {"run": ended})


func _on_pause_menu_menu_button_pressed() -> void:
	RunManager.end_run()
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _on_pause_menu_exit_button_pressed() -> void:
	get_tree().quit()
