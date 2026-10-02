extends GdUnitTestSuite

## Tests de la configuración del proyecto: viewport, acciones de input y autoloads.

const ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_down",
	&"jump",
	&"shoot_up",
	&"shoot_down",
	&"shoot_left",
	&"shoot_right",
	&"dash",
	&"use_active",
	&"interact",
	&"show_build",
	&"pause",
]
const AUTOLOADS: Array[String] = ["Events", "Settings", "RunManager", "SceneRouter"]


func test_viewport_is_1280x720_with_keep_width() -> void:
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_width")).is_equal(1280)
	assert_int(ProjectSettings.get_setting("display/window/size/viewport_height")).is_equal(720)
	assert_str(ProjectSettings.get_setting("display/window/stretch/mode")).is_equal("canvas_items")
	assert_str(ProjectSettings.get_setting("display/window/stretch/aspect")).is_equal("keep_width")


func test_every_action_has_keyboard_and_gamepad_events() -> void:
	for action: StringName in ACTIONS:
		assert_bool(InputMap.has_action(action)).override_failure_message(action).is_true()
		var has_key: bool = false
		var has_joypad: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			has_key = has_key or event is InputEventKey
			has_joypad = (
				has_joypad or event is InputEventJoypadButton or event is InputEventJoypadMotion
			)
		assert_bool(has_key).override_failure_message("%s sin teclado" % action).is_true()
		assert_bool(has_joypad).override_failure_message("%s sin mando" % action).is_true()


func test_old_actions_are_gone() -> void:
	assert_bool(InputMap.has_action(&"left")).is_false()
	assert_bool(InputMap.has_action(&"right")).is_false()


func test_autoloads() -> void:
	for autoload: String in AUTOLOADS:
		assert_bool(ProjectSettings.has_setting("autoload/" + autoload)).is_true()
		assert_object(get_tree().root.get_node_or_null(autoload)).is_not_null()
	assert_bool(ProjectSettings.has_setting("autoload/game")).is_false()
