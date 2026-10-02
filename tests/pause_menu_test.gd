extends GdUnitTestSuite

## Tests del menú de pausa: Esc pausa y también reanuda.

const PAUSE_MENU_SCENE: PackedScene = preload("res://screens/pause_menu/pause_menu.tscn")


func after_test() -> void:
	get_tree().paused = false


func test_processes_while_paused() -> void:
	var menu: PauseMenu = auto_free(PAUSE_MENU_SCENE.instantiate())
	assert_int(menu.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_bool(menu.visible).is_false()


func test_pause_action_toggles_pause() -> void:
	var menu: PauseMenu = _add_menu()

	menu._unhandled_input(_pause_event())
	assert_bool(get_tree().paused).is_true()
	assert_bool(menu.visible).is_true()

	menu._unhandled_input(_pause_event())
	assert_bool(get_tree().paused).is_false()
	assert_bool(menu.visible).is_false()


func test_menu_button_resumes_before_leaving() -> void:
	var menu: PauseMenu = _add_menu()
	menu.pause()
	menu._on_menu_button_pressed()
	assert_bool(get_tree().paused).is_false()
	assert_bool(menu.visible).is_false()


func _add_menu() -> PauseMenu:
	var menu: PauseMenu = auto_free(PAUSE_MENU_SCENE.instantiate())
	add_child(menu)
	return menu


func _pause_event() -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	return event
