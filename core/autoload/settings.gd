extends Node
## Player options (autoload `Settings`): loads them from settings.cfg at startup,
## applies them to the audio buses and the language, and saves them on request.

signal changed

const DEFAULT_PATH: String = "user://settings.cfg"
const AUDIO_SECTION: String = "audio"
const GAME_SECTION: String = "game"
const MASTER_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Music"
const EFFECTS_BUS: StringName = &"Effects"
const DEFAULT_VOLUME: float = 1.0
const DEFAULT_LANGUAGE: String = "es"
## Languages offered in the options menu, as locale codes.
const LANGUAGES: PackedStringArray = ["es", "en"]

## Linear volumes, 0 to 1.
var master_volume: float = DEFAULT_VOLUME
var music_volume: float = DEFAULT_VOLUME
var effects_volume: float = DEFAULT_VOLUME
## Locale code, one of LANGUAGES.
var language: String = DEFAULT_LANGUAGE
## Where the options are stored. Tests point it elsewhere.
var config_path: String = DEFAULT_PATH


func _ready() -> void:
	load_settings()
	apply()


## Reads the options file. Missing or invalid values keep their defaults.
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		return
	master_volume = _read_volume(config, "master", master_volume)
	music_volume = _read_volume(config, "music", music_volume)
	effects_volume = _read_volume(config, "effects", effects_volume)
	var saved_language: Variant = config.get_value(GAME_SECTION, "language", language)
	if saved_language is String and saved_language in LANGUAGES:
		language = saved_language


func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value(AUDIO_SECTION, "master", master_volume)
	config.set_value(AUDIO_SECTION, "music", music_volume)
	config.set_value(AUDIO_SECTION, "effects", effects_volume)
	config.set_value(GAME_SECTION, "language", language)
	return config.save(config_path)


## Applies every option to the engine and notifies listeners.
func apply() -> void:
	_set_bus_volume(MASTER_BUS, master_volume)
	_set_bus_volume(MUSIC_BUS, music_volume)
	_set_bus_volume(EFFECTS_BUS, effects_volume)
	TranslationServer.set_locale(language)
	changed.emit()


func _read_volume(config: ConfigFile, key: String, fallback: float) -> float:
	var value: Variant = config.get_value(AUDIO_SECTION, key, fallback)
	if value is float or value is int:
		var volume: float = value
		return clampf(volume, 0.0, 1.0)
	return fallback


func _set_bus_volume(bus: StringName, volume: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(volume))
