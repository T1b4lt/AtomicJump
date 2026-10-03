class_name InputHints
extends RefCounted
## Names of the keys of the input actions, for the prompts of the UI.


## Name of the first keyboard key of an action ("W"), or the action's name.
static func key_name(action: StringName) -> String:
	if not InputMap.has_action(action):
		return String(action)
	for event: InputEvent in InputMap.action_get_events(action):
		var key: InputEventKey = event as InputEventKey
		if key != null:
			if key.keycode != KEY_NONE:
				return OS.get_keycode_string(key.keycode)
			return key.as_text_physical_keycode()
	return String(action)
