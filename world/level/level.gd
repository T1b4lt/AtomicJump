class_name Level
extends Node2D
## Prototype level: an auto-scrolling column of chunks chosen by the seed with
## PrototypeGenerator. Plays the run in RunManager and ends it when the player
## dies or falls below the camera.

## Altitude units per chunk height (the prototype counted 11 per screen).
const ALTITUDE_UNITS_PER_CHUNK: float = 11.0
## Chunks alive at once: the oldest is freed when another one leaves the screen.
const KEPT_CHUNKS: int = 3

## How far below the bottom edge of the screen the player can fall, in px.
@export var fall_margin: float = 50.0

var run: RunState = null
var _camera_start_y: float = 0.0
var _chunks: Array[Chunk] = []
var _ending: bool = false

@onready var _camera: ScrollingCamera = %Camera
@onready var _player: Player = %Player
@onready var _hud: Hud = %Hud
@onready var _initial_chunk: Chunk = %InitialChunk


func _ready() -> void:
	# Running the level scene on its own (F6) starts a random run
	run = RunManager.run if RunManager.has_run() else RunManager.start_run()

	# Bottom of the view on the bottom of the first chunk, play area centered
	var view_size: Vector2 = get_viewport_rect().size
	_camera.position = Vector2(Chunk.WIDTH / 2.0, Chunk.HEIGHT - view_size.y / 2.0)
	_camera_start_y = _camera.position.y

	_player.bind_run(run)
	_hud.bind_run(run)
	run.died.connect(_end_run)


func _process(_delta: float) -> void:
	var screen_bottom: float = _camera.position.y + get_viewport_rect().size.y / 2.0
	if _player.position.y > screen_bottom + fall_margin:
		_end_run()
		return
	run.set_altitude(
		(_camera_start_y - _camera.position.y) / (Chunk.HEIGHT / ALTITUDE_UNITS_PER_CHUNK)
	)


func _add_chunk() -> void:
	# Index 0 is the initial chunk, so the n-th added chunk has index n
	var index: int = _chunks.size() + 1
	var id: StringName = PrototypeGenerator.pick_chunk(run.world_rng, index)
	var chunk: Chunk = PrototypeGenerator.CHUNK_SCENES[id].instantiate() as Chunk
	_chunks.append(chunk)
	chunk.position.y = -Chunk.HEIGHT * index
	add_child(chunk)
	_place_objects(chunk, index)
	chunk.screen_entered.connect(_add_chunk)
	chunk.screen_exited.connect(_free_oldest_chunk)


func _place_objects(chunk: Chunk, index: int) -> void:
	chunk.place_objects(
		PrototypeGenerator.plan_objects(run.world_rng, index, chunk.get_slot_count())
	)


func _free_oldest_chunk() -> void:
	var index: int = _chunks.size() - KEPT_CHUNKS
	if index >= 0 and is_instance_valid(_chunks[index]):
		_chunks[index].queue_free()


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


func _on_initial_chunk_screen_entered() -> void:
	_add_chunk()
	_place_objects(_initial_chunk, 0)


func _on_initial_chunk_screen_exited() -> void:
	_initial_chunk.queue_free()
