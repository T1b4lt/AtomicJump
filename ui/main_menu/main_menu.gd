class_name MainMenu
extends CanvasLayer
## Main menu: start a random run or one with a typed seed, options and quit.

@onready var _seed_input: LineEdit = %SeedInput


func _ready() -> void:
	_seed_input.max_length = SeedCode.DIGITS


func _on_play_button_pressed() -> void:
	_start_run(SeedCode.generate())


func _on_play_seed_button_pressed() -> void:
	if not SeedCode.is_valid_text(_seed_input.text):
		_seed_input.clear()
		return
	_start_run(SeedCode.from_text(_seed_input.text))


func _on_settings_button_pressed() -> void:
	SceneRouter.go_to(SceneRouter.SETTINGS_MENU)


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _start_run(seed_value: int) -> void:
	RunManager.start_run(seed_value)
	SceneRouter.go_to(SceneRouter.LEVEL)
