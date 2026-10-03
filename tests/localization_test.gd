extends GdUnitTestSuite

## Tests de localización: cada texto visible de las escenas es una clave traducida.

const CSV_PATH: String = "res://localization/translations.csv"
const SCENE_DIRS: Array[String] = ["res://actors", "res://items", "res://ui", "res://world"]
## Properties of a .tscn line that hold visible text.
const TEXT_PROPERTIES: Array[String] = ["text", "placeholder_text", "tooltip_text"]


func after_test() -> void:
	TranslationServer.set_locale(Settings.language)


func test_every_key_is_translated_to_every_language() -> void:
	var rows: Array[PackedStringArray] = _read_csv()
	var header: PackedStringArray = rows[0]
	assert_array(Array(header)).contains(Array(Settings.LANGUAGES))
	for row: PackedStringArray in rows.slice(1):
		assert_int(row.size()).is_equal(header.size())
		for column: int in range(1, row.size()):
			(
				assert_str(row[column])
				. override_failure_message("%s sin traducir (%s)" % [row[0], header[column]])
				. is_not_empty()
			)


func test_spanish_is_the_initial_language() -> void:
	assert_str(Settings.DEFAULT_LANGUAGE).is_equal("es")
	assert_str(ProjectSettings.get_setting("internationalization/locale/fallback")).is_equal("es")
	TranslationServer.set_locale("es")
	assert_str(tr("MENU_PLAY")).is_equal("Jugar")
	TranslationServer.set_locale("en")
	assert_str(tr("MENU_PLAY")).is_equal("Play")


func test_scene_texts_are_translation_keys() -> void:
	var keys: Array[String] = []
	for row: PackedStringArray in _read_csv().slice(1):
		keys.append(row[0])
	var scenes: Array[String] = []
	for dir: String in SCENE_DIRS:
		_collect_scenes(dir, scenes)
	assert_array(scenes).is_not_empty()
	for path: String in scenes:
		for text: String in _translatable_texts(path):
			(
				assert_bool(text in keys)
				. override_failure_message('%s: "%s" no es una clave' % [path, text])
				. is_true()
			)


func test_stat_names_are_translated() -> void:
	TranslationServer.set_locale("es")
	for stat: StringName in Stats.ALL:
		var key: String = Hud.STAT_KEY_PREFIX + String(stat).to_upper()
		assert_str(tr(key)).override_failure_message(key).is_not_equal(key)


## Texts of the scene's nodes that are auto-translated (not marked as disabled).
func _translatable_texts(path: String) -> Array[String]:
	var texts: Array[String] = []
	var translate: bool = true
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		if line.begins_with("[node "):
			translate = true
		elif line == "auto_translate_mode = 2":
			translate = false
		for property: String in TEXT_PROPERTIES:
			var prefix: String = property + ' = "'
			if translate and line.begins_with(prefix):
				texts.append(line.trim_prefix(prefix).trim_suffix('"'))
	return texts


func _read_csv() -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() > 1:
			rows.append(row)
	return rows


func _collect_scenes(dir: String, out: Array[String]) -> void:
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "tscn":
			out.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		_collect_scenes(dir.path_join(sub), out)
