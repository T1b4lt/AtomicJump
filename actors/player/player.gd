class_name Player
extends CharacterBody2D
## Wilas. Reads its statistics from the RunState given in bind_run() and reports
## jumps and damage to it; the HP bar follows the run's signals.

## Seconds without taking damage after a hit.
@export var invulnerability_time: float = 1.0
## Blinks per second while invulnerable.
@export var blink_frequency: float = 15.0
## Opacity in the "off" half of each blink.
@export var blink_alpha: float = 0.3

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var run: RunState = null
## Jumps done in the air since last touching the floor.
var air_jumps_used: int = 0
## Seconds of invulnerability remaining.
var invulnerability_left: float = 0.0

@onready var _body_sprite: Sprite2D = %Body
@onready var _animation_player: AnimationPlayer = %AnimationPlayer
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel


## Number of jumps allowed in the air: max_jumps counts the ground jump too
## (2 = double jump). Walking off a ledge keeps all of them.
static func max_air_jumps(max_jumps: int) -> int:
	return maxi(max_jumps - 1, 0)


## Connects the player to the run it plays. Call it before the first physics frame.
func bind_run(new_run: RunState) -> void:
	if run != null:
		run.hp_changed.disconnect(_on_hp_changed)
		run.stats.stat_changed.disconnect(_on_stat_changed)
	run = new_run
	run.hp_changed.connect(_on_hp_changed)
	run.stats.stat_changed.connect(_on_stat_changed)
	_apply_size(run.stats.get_value(Stats.SIZE))
	_on_hp_changed(run.hp, run.get_max_hp())


func _physics_process(delta: float) -> void:
	if run == null:
		return
	_update_invulnerability(delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	# is_on_floor() still holds the state of the last move_and_slide(),
	# so the air jump count is reset before (never after) jumping in this frame.
	var on_floor: bool = is_on_floor()
	if on_floor:
		air_jumps_used = 0
	if Input.is_action_just_pressed("jump") and try_jump(on_floor):
		velocity.y = -run.stats.get_value(Stats.JUMP_FORCE)
		run.register_jump()

	var speed: float = run.stats.get_value(Stats.SPEED)
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		_body_sprite.scale.x = -1.0 if direction < 0 else 1.0
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	_update_animation(direction)


## Applies the jump rules for a jump press and returns whether Wilas jumps.
## A ground jump is always allowed and does not consume air jumps.
func try_jump(on_floor: bool) -> bool:
	if on_floor:
		return true
	if air_jumps_used < max_air_jumps(run.stats.get_int(Stats.MAX_JUMPS)):
		air_jumps_used += 1
		return true
	return false


func is_invulnerable() -> bool:
	return invulnerability_left > 0.0


## Damages the run (reduced by defense) and starts the invulnerability window.
## Damage taken while invulnerable is ignored. Returns whether it was applied.
func take_damage(amount: float) -> bool:
	if is_invulnerable() or run == null:
		return false
	run.take_damage(amount)
	invulnerability_left = invulnerability_time
	return true


func play_animation(animation_name: StringName) -> void:
	if _animation_player.current_animation != animation_name:
		_animation_player.play(animation_name)


func _update_invulnerability(delta: float) -> void:
	if not is_invulnerable():
		return
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	# Blink while invulnerable, back to fully opaque when it ends
	var blink_off: bool = fmod(invulnerability_left * blink_frequency, 1.0) < 0.5
	modulate.a = blink_alpha if is_invulnerable() and blink_off else 1.0


func _update_animation(direction: float) -> void:
	if not is_on_floor():
		play_animation(&"jump" if velocity.y < 0 else &"fall")
	elif direction != 0:
		play_animation(&"walk")
	else:
		play_animation(&"idle")


func _apply_size(value: float) -> void:
	scale = Vector2(value, value)


func _on_hp_changed(value: float, max_value: float) -> void:
	_hp_bar.max_value = max_value
	_hp_bar.value = value
	_hp_label.text = "%.2f/%s" % [value, max_value]


func _on_stat_changed(stat: StringName, value: float) -> void:
	if stat == Stats.SIZE:
		_apply_size(value)
