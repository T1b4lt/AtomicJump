extends GdUnitTestSuite

## Tests de Settings: guardado, carga, valores por defecto y aplicación al motor.

const TEST_PATH: String = "user://settings_test.cfg"

var _saved: Dictionary = {}


func before_test() -> void:
	_saved = {
		"master": Settings.master_volume,
		"music": Settings.music_volume,
		"effects": Settings.effects_volume,
		"language": Settings.language,
		"path": Settings.config_path,
	}
	Settings.config_path = TEST_PATH


func after_test() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	Settings.master_volume = _saved["master"]
	Settings.music_volume = _saved["music"]
	Settings.effects_volume = _saved["effects"]
	Settings.language = _saved["language"]
	Settings.config_path = _saved["path"]
	Settings.apply()


func test_save_and_load_round_trip() -> void:
	Settings.master_volume = 0.5
	Settings.music_volume = 0.25
	Settings.effects_volume = 0.0
	Settings.language = "en"
	assert_int(Settings.save_settings()).is_equal(OK)

	Settings.master_volume = 1.0
	Settings.music_volume = 1.0
	Settings.effects_volume = 1.0
	Settings.language = "es"
	Settings.load_settings()

	assert_float(Settings.master_volume).is_equal(0.5)
	assert_float(Settings.music_volume).is_equal(0.25)
	assert_float(Settings.effects_volume).is_equal(0.0)
	assert_str(Settings.language).is_equal("en")


func test_missing_file_keeps_current_values() -> void:
	Settings.master_volume = 0.7
	Settings.load_settings()
	assert_float(Settings.master_volume).is_equal(0.7)


func test_invalid_values_are_ignored_or_clamped() -> void:
	var config := ConfigFile.new()
	config.set_value(Settings.AUDIO_SECTION, "master", 5.0)
	config.set_value(Settings.AUDIO_SECTION, "music", "loud")
	config.set_value(Settings.GAME_SECTION, "language", "xx")
	config.save(TEST_PATH)
	Settings.music_volume = 0.3
	Settings.language = "es"
	Settings.load_settings()
	assert_float(Settings.master_volume).is_equal(1.0)
	assert_float(Settings.music_volume).is_equal(0.3)
	assert_str(Settings.language).is_equal("es")


func test_apply_sets_buses_and_locale() -> void:
	Settings.music_volume = 0.5
	Settings.language = "en"
	Settings.apply()
	var music_bus: int = AudioServer.get_bus_index(Settings.MUSIC_BUS)
	assert_int(music_bus).is_greater(0)
	assert_float(AudioServer.get_bus_volume_db(music_bus)).is_equal_approx(linear_to_db(0.5), 0.001)
	assert_str(TranslationServer.get_locale()).is_equal("en")
	assert_int(AudioServer.get_bus_index(Settings.EFFECTS_BUS)).is_greater(0)
