class_name StillStatEffect
extends StatEffect
## Its modifiers only apply while the player stands still on the floor
## (Onda estacionaria).

## Horizontal speed (px/s) under which the player counts as still.
@export var still_speed: float = 10.0

var _active: bool = false


func added(_build: Build) -> void:
	_active = false


func removed(build: Build) -> void:
	if _active:
		super(build)
	_active = false


func physics_step(build: Build, _delta: float) -> void:
	var player: Player = build.player
	var still: bool = (
		player != null and player.is_on_floor() and absf(player.velocity.x) < still_speed
	)
	if still == _active:
		return
	_active = still
	if still:
		super.added(build)
	else:
		super.removed(build)


func is_active() -> bool:
	return _active
