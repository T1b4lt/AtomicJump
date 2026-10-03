class_name MainMenu
extends CanvasLayer
## Main menu: start a random run or one with a typed seed, options and quit. The
## seed field takes any text (docs/08-seeds.md); Random fills it with a new
## code and Paste with the clipboard.

@onready var _seed_input: LineEdit = %SeedInput


func _ready() -> void:
	_seed_input.max_length = SeedCode.MAX_TEXT_LENGTH


## Puts a seed in the field, as the player would see it in the HUD.
func set_seed_text(text: String) -> void:
	_seed_input.text = SeedCode.from_text(text)
	_seed_input.caret_column = _seed_input.text.length()


func get_seed_text() -> String:
	return _seed_input.text


func _on_play_button_pressed() -> void:
	_start_run(SeedCode.generate())


func _on_play_seed_button_pressed() -> void:
	if not SeedCode.is_valid_text(_seed_input.text):
		_seed_input.clear()
		_seed_input.grab_focus()
		return
	_start_run(_seed_input.text)


func _on_seed_input_text_submitted(_text: String) -> void:
	_on_play_seed_button_pressed()


func _on_random_seed_button_pressed() -> void:
	set_seed_text(SeedCode.generate())


func _on_paste_seed_button_pressed() -> void:
	set_seed_text(DisplayServer.clipboard_get())


func _on_settings_button_pressed() -> void:
	SceneRouter.go_to(SceneRouter.SETTINGS_MENU)


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _start_run(seed_text: String) -> void:
	RunManager.start_run(seed_text)
	SceneRouter.go_to(SceneRouter.LEVEL)
