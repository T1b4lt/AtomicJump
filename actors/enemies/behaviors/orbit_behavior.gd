class_name OrbitBehavior
extends EnemyBehavior
## Circles around the point where the enemy spawned, ignoring the tiles
## (orbital electron). Its starting phase, its direction and whether the orbit
## is an ellipse come from the enemy's ai_rng, so they depend on the seed.
## Draws its trace: the dotted orbit and a fading arc behind the enemy.

## Radius of the orbit in px (the horizontal one for an ellipse).
@export var radius: float = 56.0
## Seconds per turn (docs/13-art-style.md: 1,5 s).
@export var period: float = 1.5
## Chance that the orbit is an ellipse, and its vertical/horizontal ratio.
@export_range(0.0, 1.0) var ellipse_chance: float = 0.35
@export_range(0.1, 1.0) var ellipse_ratio: float = 0.55
## Whether to draw the orbit trace.
@export var draw_trace: bool = true

## Center of the orbit, in the enemy's parent coordinates.
var center: Vector2 = Vector2.ZERO
## Radii of the orbit.
var radii: Vector2 = Vector2.ZERO
## Current angle in radians and turning direction (1 or -1).
var phase: float = 0.0
var turn: float = 1.0
## Offset left by knockback, which springs back to the orbit.
var _offset: Vector2 = Vector2.ZERO
var _trace: OrbitTrace = null


## Call it when the enemy is in the tree (from its _ready()).
func setup(enemy: Enemy) -> void:
	var global_center: Vector2 = enemy.global_position
	center = enemy.position
	phase = enemy.ai_rng.randf() * TAU
	turn = 1.0 if enemy.ai_rng.randf() < 0.5 else -1.0
	var ellipse: bool = enemy.ai_rng.randf() < ellipse_chance
	radii = Vector2(radius, radius * (ellipse_ratio if ellipse else 1.0))
	enemy.position = point_at(phase)
	if draw_trace:
		_trace = OrbitTrace.new()
		_trace.behavior = self
		_trace.top_level = true
		enemy.add_child(_trace)
		_trace.global_position = global_center


## Point of the orbit at an angle, in the parent's coordinates.
func point_at(angle: float) -> Vector2:
	return center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y)


func physics_step(enemy: Enemy, delta: float) -> void:
	var scaled: float = delta * enemy.get_time_scale()
	phase = wrapf(phase + turn * TAU / period * scaled, 0.0, TAU)
	_offset += enemy.knockback_velocity * delta
	_offset = _offset * exp(-Enemy.KNOCKBACK_DAMPING * delta)
	enemy.position = point_at(phase) + _offset
	if _trace != null:
		_trace.queue_redraw()


func stop(_enemy: Enemy) -> void:
	if _trace != null:
		_trace.visible = false


## The orbit trace: a dotted ellipse and a fading arc behind the enemy, drawn
## in place (it does not move with the enemy).
class OrbitTrace:
	extends Node2D

	const DOTS: int = 28
	const DOT_RADIUS: float = 1.2
	const ARC: float = PI / 2.0
	const ARC_POINTS: int = 12
	const GLOW: float = 1.4

	var behavior: OrbitBehavior = null

	func _draw() -> void:
		var radii: Vector2 = behavior.radii
		var color: Color = Palette.NEGATIVE
		for i: int in DOTS:
			var angle: float = TAU * i / DOTS
			draw_circle(
				Vector2(cos(angle) * radii.x, sin(angle) * radii.y), DOT_RADIUS, Color(color, 0.45)
			)
		var arc := PackedVector2Array()
		for i: int in ARC_POINTS + 1:
			var angle: float = behavior.phase - behavior.turn * ARC * i / ARC_POINTS
			arc.append(Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
		var colors := PackedColorArray()
		for i: int in arc.size():
			var alpha: float = 0.5 * (1.0 - float(i) / ARC_POINTS)
			colors.append(Color(color.r * GLOW, color.g * GLOW, color.b * GLOW, alpha))
		draw_polyline_colors(arc, colors, 3.0, true)
