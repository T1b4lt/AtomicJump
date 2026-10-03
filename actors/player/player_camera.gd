class_name PlayerCamera
extends Camera2D
## Follows the player smoothly, sits a bit above it (in a climber the view
## upwards matters more) and looks ahead in the direction it moves vertically.
## Never shows past the sides of the play area nor below the bottom of the level.
## The Decoherence sets the pace, not the camera (docs/03-run.md).

## How fast the camera catches up with its goal, per second (exponential).
@export var follow_speed: float = 6.0
## Pixels between the target and the center of the view (negative: view above).
@export var vertical_bias: float = -90.0
@export_group("Look-ahead")
## Pixels of look-ahead per px/s of vertical speed.
@export var look_ahead_factor: float = 0.25
@export var max_look_ahead_up: float = 80.0
@export var max_look_ahead_down: float = 200.0
## How fast the look-ahead changes, per second (exponential).
@export var look_ahead_speed: float = 3.0
@export_group("Limits")
## Sides of the play area in world px. If it is narrower than the view, the
## view is centered on it.
@export var area_left: float = 0.0
@export var area_right: float = 1280.0
## Lowest world y the view may show.
@export var area_bottom: float = INF

## Followed node. A CharacterBody2D also gives its velocity for the look-ahead.
var target: Node2D = null
var _look_ahead: float = 0.0


func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var vertical_speed: float = 0.0
	if target is CharacterBody2D:
		vertical_speed = (target as CharacterBody2D).velocity.y
	var wanted_look_ahead: float = clampf(
		vertical_speed * look_ahead_factor, -max_look_ahead_up, max_look_ahead_down
	)
	_look_ahead = lerpf(_look_ahead, wanted_look_ahead, _smoothing(look_ahead_speed, delta))
	var goal: Vector2 = compute_goal(target.global_position, _look_ahead, get_view_size())
	global_position = clamp_to_area(
		global_position.lerp(goal, _smoothing(follow_speed, delta)), get_view_size()
	)


## Jumps to the target at once (start of a level, respawn...).
func snap_to_target() -> void:
	if target == null:
		return
	_look_ahead = 0.0
	global_position = compute_goal(target.global_position, 0.0, get_view_size())
	reset_physics_interpolation()


## Where the camera wants to be for a target position and a look-ahead.
func compute_goal(target_position: Vector2, look_ahead: float, view_size: Vector2) -> Vector2:
	return clamp_to_area(
		Vector2(target_position.x, target_position.y + vertical_bias + look_ahead), view_size
	)


## Keeps the view inside the play area: centered on it if it is narrower than
## the view, and never below area_bottom.
func clamp_to_area(center: Vector2, view_size: Vector2) -> Vector2:
	var half: Vector2 = view_size / 2.0
	var x: float = (area_left + area_right) / 2.0
	if area_right - area_left > view_size.x:
		x = clampf(center.x, area_left + half.x, area_right - half.x)
	return Vector2(x, minf(center.y, area_bottom - half.y))


## Size of the world area the camera shows.
func get_view_size() -> Vector2:
	return get_viewport_rect().size / zoom


## Lerp weight for an exponential approach at `speed` per second.
func _smoothing(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)
