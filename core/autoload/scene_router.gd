extends CanvasLayer
## Changes the current scene with a fade transition and passes parameters to the
## next one (autoload `SceneRouter`).
##
## Screens are reached by path instead of preload(): the menus, the level and the
## end screen point at each other, and preloading them would create cycles.

signal scene_changed(path: String)

const MAIN_MENU: String = "res://ui/main_menu/main_menu.tscn"
const SETTINGS_MENU: String = "res://ui/settings_menu/settings_menu.tscn"
const LEVEL: String = "res://world/level/level.tscn"
const GAME_OVER: String = "res://ui/game_over/game_over.tscn"

## Seconds of each half of the transition (fade out, then fade in).
@export var fade_time: float = 0.15

## Parameters given to the last go_to(), for the new scene to read.
var params: Dictionary = {}
var _changing: bool = false

@onready var _fade: ColorRect = %Fade


func _ready() -> void:
	_fade.color.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_changing() -> bool:
	return _changing


## Fades out, switches to the scene at `path` and fades back in. Ignored while
## another change is in progress.
func go_to(path: String, new_params: Dictionary = {}) -> void:
	if _changing:
		return
	_changing = true
	params = new_params
	# Block clicks on the old scene during the transition
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0)
	var error: Error = get_tree().change_scene_to_file(path)
	assert(error == OK, "Cannot change to scene %s" % path)
	# The new scene is added on the next frame
	await get_tree().process_frame
	scene_changed.emit(path)
	await _fade_to(0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_changing = false


func get_param(key: String, default: Variant = null) -> Variant:
	return params.get(key, default)


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", alpha, fade_time)
	await tween.finished
