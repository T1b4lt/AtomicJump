class_name RisingThreat
extends Node2D
## The Decoherence: a front that rises from below (its y is this node's y).
## Its speed has a base per layer, a rubber band that catches up with a player
## far above and slows down near them, and it stops while `paused` (safe chunks,
## bosses). Touching it takes 25 % of the max coherence, ignoring defense and
## invulnerability, and sends the player back to the last safe floor above it.
## See docs/03-run.md#la-decoherencia-amenaza-ascendente.

signal player_hit(player: Player)

## Floors looked at in one column when searching for a respawn spot.
## Cause of death when it kills the player.
const SOURCE_ID: StringName = &"rising_threat"
const MAX_FLOORS_PER_COLUMN: int = 16

@export_group("Speed")
## Speed in px/s with the player at a normal distance (Layer K is slow).
@export var base_speed: float = 45.0
## Beyond this distance (px) to the player the threat speeds up...
@export var rubber_band_distance: float = 900.0
## ...by this many px/s per px of extra distance.
@export var rubber_band_gain: float = 0.6
## Under this distance (px) it slows down, down to near_speed_ratio of the base.
@export var near_distance: float = 220.0
@export_range(0.0, 1.0) var near_speed_ratio: float = 0.5
@export var max_speed: float = 420.0

@export_group("Hit")
## Fraction of the max coherence taken on contact.
@export_range(0.0, 1.0) var damage_ratio: float = 0.25
## Minimum height (px) of a respawn spot above the front.
@export var respawn_clearance: float = 96.0
## Seconds before another hit can happen.
@export var hit_cooldown: float = 0.5
## Horizontal range searched for floor when no remembered spot is valid.
@export var scan_left: float = 0.0
@export var scan_right: float = 1280.0
## Height (px) above the front searched for floor, and the step between columns.
@export var scan_height: float = 1400.0
@export var scan_step: float = 32.0

## Followed player; set it with setup().
var player: Player = null
## While true the front does not move (it still hurts).
var paused: bool = false
## Current speed in px/s.
var speed: float = 0.0
var _hit_cooldown_left: float = 0.0

@onready var _hitbox: Area2D = %Hitbox


func setup(p_player: Player) -> void:
	player = p_player


func _physics_process(delta: float) -> void:
	_hit_cooldown_left = maxf(0.0, _hit_cooldown_left - delta)
	if player == null:
		return
	speed = 0.0 if paused else speed_for_distance(distance_to(player.global_position.y))
	position.y -= speed * delta
	if _hit_cooldown_left == 0.0 and _hitbox.overlaps_body(player):
		hit(player)


## Px from the front up to `y` (negative if `y` is under the front).
func distance_to(y: float) -> float:
	return global_position.y - y


## Speed (px/s) for a distance to the player: rubber band when far, slower when near.
func speed_for_distance(distance: float) -> float:
	var result: float = base_speed
	if distance > rubber_band_distance:
		result += (distance - rubber_band_distance) * rubber_band_gain
	elif distance < near_distance:
		result *= lerpf(near_speed_ratio, 1.0, clampf(distance / near_distance, 0.0, 1.0))
	return minf(result, max_speed)


## Hurts the player and, if it survives, moves it to a safe floor above the front.
func hit(target: Player) -> void:
	_hit_cooldown_left = hit_cooldown
	target.take_unavoidable_damage(target.run.get_max_hp() * damage_ratio, SOURCE_ID)
	if target.state != Player.State.DEAD:
		target.respawn_at(find_respawn_spot(target))
	player_hit.emit(target)


## The most recent floor spot of the player that is still above the front and
## still has floor under it; otherwise the floor found closest above the front.
func find_respawn_spot(target: Player) -> Vector2:
	var limit: float = global_position.y - respawn_clearance
	var feet: float = target.get_feet_offset()
	for i: int in range(target.safe_spots.size() - 1, -1, -1):
		var spot: Vector2 = target.safe_spots[i]
		if spot.y < limit and _floor_under(spot, feet + scan_step):
			return spot
	var scanned: Vector2 = _scan_floor(limit, feet)
	if scanned.is_finite():
		return scanned
	# No floor at all: drop the player from high enough to recover
	return Vector2(target.global_position.x, limit - scan_height / 2.0)


## Whether there is floor within `depth` px under `spot`.
func _floor_under(spot: Vector2, depth: float) -> bool:
	return not _ray(spot, spot + Vector2(0.0, depth)).is_empty()


## Floor closest to (but above) `limit`, looking down each column from
## `scan_height` above it; returns the spot to stand on it (INF if none).
func _scan_floor(limit: float, feet: float) -> Vector2:
	var best: Vector2 = Vector2.INF
	var x: float = scan_left + scan_step / 2.0
	while x < scan_right:
		var floor_y: float = _lowest_floor_in_column(x, limit - scan_height, limit)
		if is_finite(floor_y) and (not best.is_finite() or floor_y - feet > best.y):
			best = Vector2(x, floor_y - feet)
		x += scan_step
	return best


## Lowest floor top between `top` and `bottom` at column `x` (INF if none). A
## ray stops at the first floor, so it goes on from inside each one it hits.
func _lowest_floor_in_column(x: float, top: float, bottom: float) -> float:
	var lowest: float = INF
	var from: Vector2 = Vector2(x, top)
	for _floor: int in MAX_FLOORS_PER_COLUMN:
		var hit_result: Dictionary = _ray(from, Vector2(x, bottom))
		if hit_result.is_empty():
			break
		var floor_point: Vector2 = hit_result["position"]
		lowest = floor_point.y
		from = floor_point + Vector2(0.0, 1.0)
	return lowest


func _ray(from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = (
		1 << (PhysicsLayers.WORLD - 1) | 1 << (PhysicsLayers.ONE_WAY_PLATFORMS - 1)
	)
	return get_world_2d().direct_space_state.intersect_ray(query)
