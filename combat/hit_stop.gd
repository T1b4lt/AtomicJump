class_name HitStop
extends Node
## Hitstop (docs/13-art-style.md#animación: 40–60 ms): freezes the game for a
## few milliseconds so that hits are felt. It slows Engine.time_scale and
## restores it with a timer that ignores the time scale; overlapping stops
## extend the current one instead of adding up. Leaving the tree always
## restores the normal speed.

## Time scale during a stop (almost frozen).
@export var stopped_time_scale: float = 0.05
## Durations in seconds: hitting an enemy, killing one and being hurt.
@export var enemy_hit_time: float = 0.03
@export var enemy_kill_time: float = 0.05
@export var player_hurt_time: float = 0.06
## Whether stops happen (accessibility or debug tools can turn them off).
@export var enabled: bool = true

## Engine ticks (ms) when the current stop ends.
var _ends_at: int = 0
## Number of the latest stop: only its timer restores the speed.
var _stop_id: int = 0


func _exit_tree() -> void:
	Engine.time_scale = 1.0


## Stops the game for `duration` real seconds (or longer if a stop is running).
func stop(duration: float) -> void:
	if not enabled or duration <= 0.0 or not is_inside_tree():
		return
	var ends_at: int = Time.get_ticks_msec() + roundi(duration * 1000.0)
	if ends_at <= _ends_at:
		return
	_ends_at = ends_at
	_stop_id += 1
	Engine.time_scale = stopped_time_scale
	var timer: SceneTreeTimer = get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(_on_timeout.bind(_stop_id))


func is_stopped() -> bool:
	return Engine.time_scale < 1.0


func _on_timeout(stop_id: int) -> void:
	if stop_id == _stop_id:
		Engine.time_scale = 1.0
