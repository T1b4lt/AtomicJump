class_name SettingsMenu
extends CanvasLayer
## Options screen. Changes apply at once and are saved when going back.

## Translation key of each language name, by locale code.
const LANGUAGE_KEYS: Dictionary[String, String] = {"es": "LANGUAGE_ES", "en": "LANGUAGE_EN"}

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _effects_slider: HSlider = %EffectsSlider
@onready var _language_option: OptionButton = %LanguageOption


func _ready() -> void:
	_master_slider.value = Settings.master_volume
	_music_slider.value = Settings.music_volume
	_effects_slider.value = Settings.effects_volume
	for language: String in Settings.LANGUAGES:
		_language_option.add_item(LANGUAGE_KEYS[language])
	_language_option.select(Settings.LANGUAGES.find(Settings.language))

	_master_slider.value_changed.connect(_on_volume_changed.unbind(1))
	_music_slider.value_changed.connect(_on_volume_changed.unbind(1))
	_effects_slider.value_changed.connect(_on_volume_changed.unbind(1))
	_language_option.item_selected.connect(_on_language_selected)


func _on_volume_changed() -> void:
	Settings.master_volume = _master_slider.value
	Settings.music_volume = _music_slider.value
	Settings.effects_volume = _effects_slider.value
	Settings.apply()


func _on_language_selected(index: int) -> void:
	Settings.language = Settings.LANGUAGES[index]
	Settings.apply()


func _on_back_button_pressed() -> void:
	Settings.save_settings()
	SceneRouter.go_to(SceneRouter.MAIN_MENU)
