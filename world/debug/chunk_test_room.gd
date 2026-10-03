extends Node2D
## Chunk test room (docs/05-world.md#herramientas-de-autoría): plays one chunk
## on its own, built as the level would build it (mirror, optional parts, slots,
## fork exits or reward), over a floor so the player can start at its entry.
## Pick the chunk with `chunk_scene` (or `--chunk=res://…` after `--` on the
## command line); without one it starts with the first chunk of `layer`.
## Keys: R back to the start, M mirror, N another seed, PgUp/PgDn previous/next
## chunk of the layer, C photons and a positron (to try shops and containers).
## A development tool: the overlay shows code names.

## Thickness of the floor under the chunk.
const FLOOR_HEIGHT: float = 40.0
const CHUNK_ARG: String = "--chunk="
## Photons and positrons given by the C key.
const DEBUG_COINS: int = 50
const DEBUG_KEYS: int = 1

@export var layer: LayerData = preload("res://data/layers/layer_k.tres")
@export var chunk_scene: PackedScene = null
@export var mirrored: bool = false
@export var seed_text: String = "CHUNK-ROOM"

var run: RunState = null
var chunk: Chunk = null
var _seed_number: int = 0
var _start: Vector2 = Vector2.ZERO
var _last_choice: String = ""

@onready var _chunk_root: Node2D = %ChunkRoot
@onready var _floor: DebugBlock = %Floor
@onready var _player: Player = %Player
@onready var _camera: PlayerCamera = %Camera
@onready var _overlay: Label = %Overlay


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(CHUNK_ARG):
			chunk_scene = load(arg.trim_prefix(CHUNK_ARG))
	if chunk_scene == null:
		chunk_scene = layer.chunks[0]
	_camera.area_left = 0.0
	_camera.area_right = Chunk.WIDTH
	_camera.target = _player
	_build()


func _exit_tree() -> void:
	if RunManager.run == run:
		RunManager.run = null


func _process(_delta: float) -> void:
	_overlay.text = _describe()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_R:
			_restart_player()
		KEY_M:
			mirrored = not mirrored
			_build()
		KEY_N:
			_seed_number += 1
			_build()
		KEY_C:
			run.add_coins(DEBUG_COINS)
			run.add_keys(DEBUG_KEYS)
		KEY_PAGEUP, KEY_PAGEDOWN:
			var step: int = 1 if key.physical_keycode == KEY_PAGEDOWN else -1
			var index: int = maxi(layer.chunks.find(chunk_scene), 0)
			chunk_scene = layer.chunks[wrapi(index + step, 0, layer.chunks.size())]
			_build()


## (Re)builds the chunk with the current options and puts the player at its start.
func _build() -> void:
	if chunk != null:
		chunk.queue_free()
	run = RunState.new(
		"%s-%d" % [seed_text, _seed_number], RunManager.DEFAULT_CHARACTER, RunManager.CATALOG
	)
	run.hp_changed.connect(_on_hp_changed)
	run.build.spawner = _spawn_object
	# The pickups report to RunManager's run: make this room's run that one
	RunManager.run = run
	_player.bind_run(run)
	_last_choice = ""
	chunk = chunk_scene.instantiate()
	var placement := ChunkPlacement.create(layer.code, "test", 0, chunk.data.type)
	placement.mirrored = mirrored and chunk.data.mirrorable
	placement.fork = 1
	placement.reward = LayerGenerator.pick_fork_rewards(run.world_rng, layer, 1)[0]
	var roller := LootRoller.new(run.world_rng, run.build.catalog, run)
	Level.build_chunk(chunk, placement, layer, run.world_rng, 0, roller)
	chunk.branch_chosen.connect(_on_branch_chosen)
	_chunk_root.add_child(chunk)
	_floor.position = Vector2(0.0, chunk.get_height())
	_floor.size = Vector2(Chunk.WIDTH, FLOOR_HEIGHT)
	_camera.area_bottom = chunk.get_height() + FLOOR_HEIGHT
	var spawn: Marker2D = chunk.get_marker(Chunk.SPAWN_MARKER)
	var entries: Array[Marker2D] = chunk.get_entry_markers()
	var start_marker: Marker2D = (
		spawn if spawn != null else entries[0] if not entries.is_empty() else null
	)
	var start_x: float = start_marker.position.x if start_marker != null else Chunk.WIDTH / 2.0
	var start_y: float = start_marker.position.y if spawn != null else chunk.get_height()
	_start = Vector2(start_x, start_y - _player.get_feet_offset())
	_restart_player()


func _restart_player() -> void:
	_player.respawn_at(_start)
	_camera.snap_to_target()


func _describe() -> String:
	var data: ChunkData = chunk.data
	var lines: PackedStringArray = [
		(
			"%s   %s   difficulty %d   %s"
			% [
				data.id,
				ChunkData.Type.keys()[data.type],
				data.difficulty,
				"mirrored" if chunk.mirrored else "",
			]
		),
		(
			"entries %s   exits %s   seed %s   photons %d   positrons %d   items %d"
			% [
				_openings(ChunkInfo.read_openings(chunk.get_entry_markers())),
				_openings(ChunkInfo.read_openings(chunk.get_exit_markers())),
				run.seed_code,
				run.coins,
				run.keys,
				run.build.passive_items.size(),
			]
		),
	]
	if not _last_choice.is_empty():
		lines.append("branch chosen: %s" % _last_choice)
	lines.append(tr("DEBUG_CHUNK_ROOM_HELP"))
	return "\n".join(lines)


static func _openings(openings: int) -> String:
	var text: String = ""
	for opening: String in Chunk.Opening:
		if openings & Chunk.Opening[opening]:
			text += opening.left(1)
	return text


func _spawn_object(object_id: StringName, at: Vector2) -> void:
	chunk.spawn_object(object_id, chunk.to_local(at))


func _on_branch_chosen(side: int) -> void:
	_last_choice = LayerPlan.SIDES[side]


func _on_hp_changed(value: float, max_value: float) -> void:
	if value > 0.0 and value < max_value / 2.0:
		run.heal.call_deferred(max_value)
