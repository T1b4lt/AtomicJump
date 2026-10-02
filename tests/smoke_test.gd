extends GdUnitTestSuite

## Tests de humo: comprueban que el proyecto carga y compila con los avisos como error.

const SCRIPT_DIRS: Array[String] = [
	"res://actors", "res://core", "res://items", "res://ui", "res://world"
]

const LEVEL_SCENE: PackedScene = preload("res://world/level/level.tscn")


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
