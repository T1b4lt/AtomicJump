extends GdUnitTestSuite

## Tests del arte generado (art/build_game_assets.py): el manifiesto y los SVG
## coinciden, no llevan filtros ni texto y se importan al doble de escala.

const GENERATED_DIR: String = "res://assets/generated"
const MANIFEST_PATH: String = "res://assets/generated/manifest.json"


func test_manifest_lists_every_generated_svg() -> void:
	var listed: Array = _manifest_assets().keys()
	var found: Array[String] = []
	_collect_svgs(GENERATED_DIR, found)
	assert_array(found).is_not_empty()
	assert_array(listed).contains_exactly_in_any_order(found)


func test_svgs_have_no_filters_nor_text() -> void:
	var found: Array[String] = []
	_collect_svgs(GENERATED_DIR, found)
	for relative: String in found:
		var svg: String = FileAccess.get_file_as_string(GENERATED_DIR.path_join(relative))
		assert_bool(svg.contains("filter")).override_failure_message(relative).is_false()
		assert_bool(svg.contains("<text")).override_failure_message(relative).is_false()


func test_svgs_are_imported_at_double_scale() -> void:
	var assets: Dictionary = _manifest_assets()
	for relative: String in assets:
		var texture: Texture2D = load(GENERATED_DIR.path_join(relative))
		assert_object(texture).override_failure_message(relative).is_not_null()
		var entry: Dictionary = assets[relative]
		var size: Array = entry["size"]
		var width: float = size[0]
		var height: float = size[1]
		var expected: Vector2 = Vector2(width, height) * 2.0
		assert_vector(texture.get_size()).override_failure_message(relative).is_equal(expected)


func test_palette_matches_the_art_direction() -> void:
	assert_str(Palette.PLAYER.to_html(false)).is_equal("6bffb8")
	assert_str(Palette.DECOHERENCE.to_html(false)).is_equal("c9d2ff")


func _manifest_assets() -> Dictionary:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	assert_bool(manifest is Dictionary).is_true()
	var data: Dictionary = manifest
	return data["assets"]


func _collect_svgs(dir: String, out: Array[String], prefix: String = "") -> void:
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "svg":
			out.append(prefix + file)
	for sub: String in DirAccess.get_directories_at(dir):
		_collect_svgs(dir.path_join(sub), out, prefix + sub + "/")
