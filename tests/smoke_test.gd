extends GdUnitTestSuite

## Tests de humo: comprueban que el proyecto carga y compila con los avisos como error.

const SCRIPT_DIRS: Array[String] = [
	"res://actors", "res://core", "res://items", "res://ui", "res://world"
]

const LEVEL_SCENE: PackedScene = preload("res://world/level/level.tscn")
const MOVEMENT_ROOM: PackedScene = preload("res://world/debug/movement_test_room.tscn")
const CHUNK_ROOM: PackedScene = preload("res://world/debug/chunk_test_room.tscn")


func test_truth() -> void:
	assert_bool(true).is_true()


func test_main_scene_loads() -> void:
	var main_scene_path: String = ProjectSettings.get_setting("application/run/main_scene")
	var main_scene: PackedScene = load(main_scene_path)
	assert_object(main_scene).is_not_null()


func test_level_starts_a_run_when_played_alone() -> void:
	var saved_run: RunState = RunManager.end_run()
	var level: Level = auto_free(LEVEL_SCENE.instantiate())
	add_child(level)
	assert_bool(RunManager.has_run()).is_true()
	assert_object(level.run).is_same(RunManager.run)
	RunManager.run = saved_run


func test_level_follows_the_player_and_raises_the_decoherence() -> void:
	var saved_run: RunState = RunManager.end_run()
	var level: Level = auto_free(LEVEL_SCENE.instantiate())
	add_child(level)
	var camera: PlayerCamera = level.get_node("%Camera")
	var player: Player = level.get_node("%Player")
	var threat: RisingThreat = level.get_node("%RisingThreat")
	assert_object(camera.target).is_same(player)
	assert_object(threat.player).is_same(player)
	assert_float(threat.global_position.y).is_greater(level.get_bottom())
	assert_float(threat.base_speed).is_equal(level.layer.threat_speed)
	# The player starts in the layer start chunk, which is safe: the Decoherence waits
	assert_int(level.get_column()[0].type).is_equal(ChunkData.Type.LAYER_START)
	assert_int(level.chunk_index_at(player.global_position.y)).is_equal(0)
	assert_bool(level.is_safe_at(player.global_position.y)).is_true()
	assert_bool(level.is_safe_at(level.get_chunk_top(1) + 10.0)).is_false()
	assert_object(level.get_chunk(1)).is_not_null()
	RunManager.run = saved_run


func test_level_column_grows_when_a_branch_is_chosen() -> void:
	var saved_run: RunState = RunManager.end_run()
	var level: Level = auto_free(LEVEL_SCENE.instantiate())
	add_child(level)
	var column: Array[ChunkPlacement] = level.get_column()
	var fork_index: int = column.size() - 1
	assert_int(column[fork_index].type).is_equal(ChunkData.Type.FORK)
	var player: Player = level.get_node("%Player")
	player.respawn_at(Vector2(640.0, level.get_chunk_top(fork_index) + 300.0))
	level._update_chunks()
	var fork: Chunk = level.get_chunk(fork_index)
	assert_object(fork).is_not_null()
	assert_array(fork.get_gates()).has_size(2)
	fork.get_gates()[0].entered.emit()
	assert_array(level.run.path).contains_exactly(["K/1/L"])
	assert_int(level.get_column().size()).is_greater(fork_index + 1)
	assert_str(level.get_column()[fork_index + 1].branch).is_equal("1/L")
	assert_object(level.get_chunk(fork_index + 1)).is_not_null()
	RunManager.run = saved_run


func test_chunk_tops_stack_upwards() -> void:
	var saved_run: RunState = RunManager.end_run()
	var level: Level = auto_free(LEVEL_SCENE.instantiate())
	add_child(level)
	var height: float = ChunkData.DEFAULT_HEIGHT_TILES * Chunk.TILE
	assert_float(level.get_chunk_top(0)).is_equal(0.0)
	assert_float(level.get_chunk_top(1)).is_equal(-height)
	assert_float(level.get_bottom()).is_equal(height)
	assert_int(level.chunk_index_at(height - 1.0)).is_equal(0)
	assert_int(level.chunk_index_at(height + 500.0)).is_equal(0)
	assert_int(level.chunk_index_at(-1.0)).is_equal(1)
	assert_int(level.chunk_index_at(-100000.0)).is_equal(level.get_column().size() - 1)
	RunManager.run = saved_run


func test_movement_room_runs_on_its_own() -> void:
	var room: Node2D = auto_free(MOVEMENT_ROOM.instantiate())
	add_child(room)
	var player: Player = room.get_node("%Player")
	assert_object(player.run).is_not_null()
	assert_object((room.get_node("%Camera") as PlayerCamera).target).is_same(player)
	# The Decoherence starts switched off
	assert_bool((room.get_node("%RisingThreat") as Node2D).visible).is_false()


func test_chunk_room_runs_on_its_own() -> void:
	var room: Node2D = auto_free(CHUNK_ROOM.instantiate())
	add_child(room)
	var player: Player = room.get_node("%Player")
	assert_object(player.run).is_not_null()
	var chunk: Chunk = room.get("chunk")
	assert_object(chunk).is_not_null()
	assert_float(player.global_position.y).is_less(chunk.get_height())


func test_all_project_scripts_compile() -> void:
	var scripts: Array[String] = []
	for dir: String in SCRIPT_DIRS:
		_collect_scripts(dir, scripts)
	assert_array(scripts).is_not_empty()
	for path: String in scripts:
		var script: GDScript = load(path)
		assert_object(script).override_failure_message("No carga: %s" % path).is_not_null()
		(
			assert_bool(script.can_instantiate())
			. override_failure_message("No compila: %s" % path)
			. is_true()
		)


func _collect_scripts(dir: String, out: Array[String]) -> void:
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "gd":
			out.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		_collect_scripts(dir.path_join(sub), out)
