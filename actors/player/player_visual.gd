class_name PlayerVisual
extends Node2D
## Wilas drawn from its generated parts (assets/generated/player/) and animated in
## the engine: the electron orbits, the core breathes, squashes and stretches,
## the eyes change with the state and blink. The Player calls it down; it never
## changes gameplay. Timings from docs/13-art-style.md#tiempos-de-referencia.

const EYES: Dictionary[StringName, Texture2D] = {
	&"neutral": preload("res://assets/generated/player/player_eyes_neutral.svg"),
	&"blink": preload("res://assets/generated/player/player_eyes_blink.svg"),
	&"happy": preload("res://assets/generated/player/player_eyes_happy.svg"),
	&"jump": preload("res://assets/generated/player/player_eyes_jump.svg"),
	&"focus": preload("res://assets/generated/player/player_eyes_focus.svg"),
	&"hurt": preload("res://assets/generated/player/player_eyes_hurt.svg"),
}
## Orbital ellipse of the electron (same as art/atomic_art/characters.py).
const ORBIT_RADII: Vector2 = Vector2(31.0, 11.0)
const ORBIT_ANGLE: float = deg_to_rad(-25.0)
## Expression for each Player.State while nothing else overrides it.
const STATE_EXPRESSIONS: Dictionary[int, StringName] = {
	Player.State.IDLE: &"neutral",
	Player.State.RUN: &"neutral",
	Player.State.JUMP: &"jump",
	Player.State.FALL: &"neutral",
	Player.State.DASH: &"focus",
	Player.State.HURT: &"hurt",
	Player.State.DEAD: &"hurt",
}
## Z order of the electron when it passes behind or in front of the core.
const ELECTRON_Z_BEHIND: int = -1
const ELECTRON_Z_FRONT: int = 2

@export_group("Idle")
## Electron turns per second.
@export var orbit_speed: float = 1.0
## Breathing: scale amplitude and seconds per cycle.
@export var breathe_amplitude: float = 0.025
@export var breathe_period: float = 2.0
## Seconds between blinks (random in the range) and blink length.
@export var blink_interval: Vector2 = Vector2(2.0, 4.0)
@export var blink_time: float = 0.1
## Pixels the eyes move towards the facing direction.
@export var eye_shift: float = 2.0

@export_group("Squash and stretch")
@export var jump_stretch: Vector2 = Vector2(0.84, 1.22)
@export var air_jump_stretch: Vector2 = Vector2(0.88, 1.15)
@export var stretch_time: float = 0.3
@export var land_squash: Vector2 = Vector2(1.28, 0.75)
@export var land_time: float = 0.08
@export var dash_stretch: Vector2 = Vector2(1.3, 0.8)
## Seconds the happy face lasts after landing.
@export var happy_time: float = 0.15

@export_group("Effects")
## Brightness multiplier (HDR) of the parts that glow.
@export var core_glow: float = 1.25
@export var line_glow: float = 1.8
## Hurt flash: brightness and seconds.
@export var flash_brightness: float = 4.0
@export var flash_time: float = 0.1
## Quantum jump pulse: seconds and final radii of the ring.
@export var pulse_time: float = 0.15
@export var pulse_radii: Vector2 = Vector2(52.0, 14.0)
## Opacity of Wilas while in the Tunnel ("wave state").
@export var dash_alpha: float = 0.6
## Afterimages kept during the Tunnel.
@export var trail_length: int = 6

## Scale of the body from squash and stretch (breathing is applied on top).
var squash: Vector2 = Vector2.ONE
## 1 facing right, -1 facing left (moves the eyes).
var facing: float = 1.0
## Opacity set by the Player's invulnerability blink.
var blink_opacity: float = 1.0

var _state: int = Player.State.IDLE
var _orbit_phase: float = 0.0
var _time: float = 0.0
var _blink_left: float = 0.0
var _next_blink: float = 0.0
var _happy_left: float = 0.0
var _pulse_left: float = 0.0
var _trail: PackedVector2Array = []
var _squash_tween: Tween = null
var _flash_tween: Tween = null
## Cosmetic only (blinks): world randomness never comes from here.
var _rng := RandomNumberGenerator.new()

@onready var _body: Node2D = %Body
@onready var _core: Sprite2D = %Core
@onready var _eyes: Sprite2D = %Eyes
@onready var _orbital: Sprite2D = %Orbital
@onready var _orbital_front: Sprite2D = %OrbitalFront
@onready var _electron: Sprite2D = %Electron


## Electron position on its tilted orbital for a phase in radians.
static func electron_position(phase: float) -> Vector2:
	return Vector2(ORBIT_RADII.x * cos(phase), ORBIT_RADII.y * sin(phase)).rotated(ORBIT_ANGLE)


## The electron is behind the core in the upper half of the orbital.
static func is_electron_behind(phase: float) -> bool:
	return sin(phase) < 0.0


func _ready() -> void:
	_rng.randomize()
	_next_blink = _rng.randf_range(blink_interval.x, blink_interval.y)
	_core.self_modulate = _bright(Color.WHITE, core_glow)
	for line: Sprite2D in [_orbital, _orbital_front, _electron]:
		line.self_modulate = _bright(Color.WHITE, line_glow)


func _process(delta: float) -> void:
	_time += delta
	_orbit_phase = fmod(_orbit_phase + TAU * orbit_speed * delta, TAU)
	_electron.position = electron_position(_orbit_phase)
	_electron.z_index = ELECTRON_Z_BEHIND if is_electron_behind(_orbit_phase) else ELECTRON_Z_FRONT

	var breathe: float = 0.0
	if _state == Player.State.IDLE:
		breathe = breathe_amplitude * sin(TAU * _time / breathe_period)
	_body.scale = squash * Vector2(1.0 + breathe, 1.0 - breathe)

	_happy_left = maxf(0.0, _happy_left - delta)
	_update_blink(delta)
	_eyes.texture = EYES[get_expression()]
	_eyes.position.x = facing * eye_shift

	modulate.a = blink_opacity * (dash_alpha if _state == Player.State.DASH else 1.0)
	_update_trail()
	if _pulse_left > 0.0:
		_pulse_left = maxf(0.0, _pulse_left - delta)
	queue_redraw()


func _draw() -> void:
	# Tunnel afterimages, oldest first
	for i: int in _trail.size():
		var weight: float = float(i + 1) / (_trail.size() + 1)
		draw_circle(to_local(_trail[i]), 16.0, Color(Palette.PLAYER, 0.18 * weight))
	# Quantum jump pulse: a flat ring growing under Wilas
	if _pulse_left > 0.0:
		var progress: float = 1.0 - _pulse_left / pulse_time
		var eased: float = 1.0 - pow(1.0 - progress, 3.0)
		var radii: Vector2 = Vector2(12.0, 4.0).lerp(pulse_radii, eased)
		draw_set_transform(Vector2(0.0, 22.0), 0.0, Vector2(1.0, radii.y / radii.x))
		draw_arc(
			Vector2.ZERO,
			radii.x,
			0.0,
			TAU,
			48,
			_bright(Palette.PLAYER, line_glow) * Color(1, 1, 1, 1.0 - progress),
			2.5 * (1.0 - progress) + 0.5
		)
		draw_set_transform(Vector2.ZERO)


## Expression shown now: hurt and dash win, then landing joy, blinks and the state.
func get_expression() -> StringName:
	var expression: StringName = STATE_EXPRESSIONS[_state]
	if _state in [Player.State.HURT, Player.State.DEAD, Player.State.DASH]:
		return expression
	if _happy_left > 0.0:
		return &"happy"
	if _blink_left > 0.0:
		return &"blink"
	return expression


func set_state(state: int) -> void:
	var was_dashing: bool = _state == Player.State.DASH
	_state = state
	if state == Player.State.DASH:
		_trail.clear()
		_tween_squash(dash_stretch, 0.0)
	elif was_dashing:
		_trail.clear()
		_tween_squash(Vector2.ONE, stretch_time * 0.5)


func play_jump(in_air: bool) -> void:
	_happy_left = 0.0
	_tween_squash(air_jump_stretch if in_air else jump_stretch, 0.0)
	_tween_squash(Vector2.ONE, stretch_time, true)
	if in_air:
		_pulse_left = pulse_time


func play_land() -> void:
	_happy_left = happy_time
	_tween_squash(land_squash, land_time * 0.5)
	_tween_squash(Vector2.ONE, land_time * 0.5, true)


func play_hurt() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	_core.modulate = Color(flash_brightness, flash_brightness, flash_brightness)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_core, ^"modulate", Color.WHITE, flash_time)


## Animates `squash` to `target` in `time` seconds (0 = at once). With `chain`
## it goes after the current squash animation instead of replacing it.
func _tween_squash(target: Vector2, time: float, chain: bool = false) -> void:
	if not chain and _squash_tween != null:
		_squash_tween.kill()
		_squash_tween = null
	if time <= 0.0:
		squash = target
		return
	if _squash_tween == null or not _squash_tween.is_valid():
		_squash_tween = create_tween()
	(
		_squash_tween
		. tween_property(self, ^"squash", target, time)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_OUT)
	)


func _update_blink(delta: float) -> void:
	_blink_left = maxf(0.0, _blink_left - delta)
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink_left = blink_time
		_next_blink = _rng.randf_range(blink_interval.x, blink_interval.y)


func _update_trail() -> void:
	if _state != Player.State.DASH:
		return
	# Afterimages stay where they were in the world while Wilas moves on
	_trail.append(global_position)
	if _trail.size() > trail_length:
		_trail.remove_at(0)


func _bright(color: Color, factor: float) -> Color:
	return Color(color.r * factor, color.g * factor, color.b * factor, color.a)
