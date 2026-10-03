class_name ImpactEffect
extends Node2D
## Bubble chamber impact (docs/13-art-style.md#efectos-visuales): a white flash,
## a ring that expands and two spirals of opposite charge that close in on
## themselves (r = r0 · e^(−k·t)), with a trail of tiny bubbles. Drawn in the
## engine and played once; its owner waits for `finished` before freeing it.
## The angles are cosmetic and use their own RandomNumberGenerator.

signal finished

## Turns of each spiral and how fast it closes.
const SPIRAL_TURNS: float = 1.6
const SPIRAL_DECAY: float = 0.22
const SPIRAL_POINTS: int = 48
const BUBBLES: int = 7
## Brightness multiplier (HDR) of the lines, so they glow.
const GLOW: float = 1.8

## Seconds the effect lasts.
@export var duration: float = 0.35
## Radius of the ring and size of the spirals, in px.
@export var radius: float = 18.0
## Colors of the two spirals (opposite charges).
@export var color_a: Color = Palette.NEGATIVE
@export var color_b: Color = Palette.POSITIVE
## Main direction of the impact: the spirals open around it.
@export var direction: Vector2 = Vector2.UP

var _time: float = 0.0
var _spin: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_spin = _rng.randf_range(-0.6, 0.6)


func _process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		set_process(false)
		visible = false
		finished.emit()
		return
	queue_redraw()


func get_progress() -> float:
	return clampf(_time / duration, 0.0, 1.0) if duration > 0.0 else 1.0


func _draw() -> void:
	var t: float = get_progress()
	var fade: float = 1.0 - t
	# Flash: a white disc that shrinks fast
	var flash: float = maxf(0.0, 1.0 - t * 3.0)
	if flash > 0.0:
		draw_circle(Vector2.ZERO, radius * 0.6 * flash, Color(GLOW, GLOW, GLOW, flash))
	# Ring that expands
	draw_arc(Vector2.ZERO, radius * (0.4 + t), 0.0, TAU, 32, _bright(Palette.INK, fade * 0.8), 1.5)
	# Two spirals of opposite charge, drawn as they grow
	var base: float = direction.angle() + _spin
	for side: int in [1, -1]:
		var color: Color = color_a if side == 1 else color_b
		_draw_spiral(base + side * 0.6, side, t, _bright(color, fade))
	# Bubbles along the incoming track
	for i: int in BUBBLES:
		var along: float = (i + 1) * radius * 0.35
		var bubble: Vector2 = -direction.normalized() * along * (0.5 + t)
		draw_circle(bubble, 1.0, _bright(Palette.INK_DIM, fade * 0.7))


func _draw_spiral(angle: float, turn: int, t: float, color: Color) -> void:
	var points := PackedVector2Array()
	var count: int = maxi(2, roundi(SPIRAL_POINTS * minf(1.0, t * 2.0)))
	var r0: float = radius * 0.9
	# The spiral starts at the impact and curls around a center beside it
	var center: Vector2 = Vector2.from_angle(angle + turn * PI / 2.0) * r0
	for i: int in count:
		var a: float = float(i) / SPIRAL_POINTS * SPIRAL_TURNS * TAU
		var r: float = r0 * exp(-SPIRAL_DECAY * a)
		var phase: float = angle - turn * PI / 2.0 + turn * a
		points.append(center + Vector2.from_angle(phase) * r)
	draw_polyline(points, color, 1.3, true)


static func _bright(color: Color, alpha: float) -> Color:
	return Color(color.r * GLOW, color.g * GLOW, color.b * GLOW, alpha)
