class_name Player
extends CharacterBody2D
## Wilas. A small state machine (State) moved by a MovementConfig: acceleration,
## variable jump, coyote time, jump buffer, quantum jumps, one-way platforms and
## the Tunnel (dash). Shoots in 4 directions with its Shooter and takes hits
## through its Hurtbox. Reads its stats from the RunState given in bind_run()
## and reports jumps and damage to it. See docs/04-player.md.

signal state_changed(from: State, to: State)
signal jumped(in_air: bool)
signal landed
signal dashed(direction: float)
signal hurt
signal respawned
signal shot(direction: Vector2)

enum State { IDLE, RUN, JUMP, FALL, DASH, HURT, DEAD }

## Group of the player: enemies find their target with it.
const GROUP: StringName = &"player"
## Cause of death of the damage that has no source (take_damage()).
const UNKNOWN_SOURCE: StringName = &"unknown"

## Floor spots remembered for respawning after touching the Decoherence.
const SAFE_SPOT_COUNT: int = 16
## Minimum distance between two remembered floor spots, in px.
const SAFE_SPOT_SPACING: float = 48.0
## Horizontal speed (px/s) under which the player counts as standing still.
const RUN_THRESHOLD: float = 10.0
## How far below the feet a floor is looked for, in px.
const FLOOR_PROBE: float = 2.0

@export var movement: MovementConfig = preload("res://data/movement/wilas_movement.tres")
## Seconds without taking damage after a hit.
@export var invulnerability_time: float = 1.0
## Blinks per second while invulnerable.
@export var blink_frequency: float = 15.0
## Opacity in the "off" half of each blink.
@export var blink_alpha: float = 0.3

var run: RunState = null
var state: State = State.IDLE
## 1 facing right, -1 facing left.
var facing: float = 1.0
## Jumps done in the air since last touching the floor.
var air_jumps_used: int = 0
## Tunnels done in the air since last touching the floor.
var air_dashes_used: int = 0
## Seconds of invulnerability remaining (the Tunnel adds its own).
var invulnerability_left: float = 0.0
## Seconds left to jump from the ground after leaving it.
var coyote_left: float = 0.0
## Seconds left for a jump press to be used.
var jump_buffer_left: float = 0.0
var dash_left: float = 0.0
var dash_cooldown_left: float = 0.0
## Seconds left ignoring the one-way platforms.
var drop_through_left: float = 0.0
var hurt_left: float = 0.0
## Recent floor spots, oldest first (see RisingThreat).
var safe_spots: PackedVector2Array = []

var _dash_direction: float = 1.0
## Whether releasing jump can still cut the current rise.
var _jump_cut_available: bool = false
var _was_on_floor: bool = false

@onready var _collision_shape: CollisionShape2D = %CollisionShape
@onready var _hurtbox: Hurtbox = %Hurtbox
@onready var _shooter: Shooter = %Shooter
@onready var _visual: PlayerVisual = %Visual
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel


## Number of jumps allowed in the air: max_jumps counts the ground jump too
## (2 = double jump). Walking off a ledge keeps all of them.
static func max_air_jumps(max_jumps: int) -> int:
	return maxi(max_jumps - 1, 0)


func _ready() -> void:
	add_to_group(GROUP)
	_hurtbox.handler = take_hit


## Connects the player to the run it plays. Call it before the first physics frame.
func bind_run(new_run: RunState) -> void:
	if run != null:
		run.hp_changed.disconnect(_on_hp_changed)
		run.died.disconnect(_on_died)
		run.stats.stat_changed.disconnect(_on_stat_changed)
	run = new_run
	run.hp_changed.connect(_on_hp_changed)
	run.died.connect(_on_died)
	run.stats.stat_changed.connect(_on_stat_changed)
	_shooter.stats = run.stats
	_apply_size(run.stats.get_value(Stats.SIZE))
	_on_hp_changed(run.hp, run.get_max_hp())


func _physics_process(delta: float) -> void:
	if run == null:
		return
	physics_step(delta, PlayerInput.from_actions())


## One physics frame with the given controls. _physics_process() calls it with
## the input actions; tests and the movement test room call it directly.
func physics_step(delta: float, input: PlayerInput) -> void:
	_tick_timers(delta)
	_shooter.tick(delta)
	match state:
		State.DEAD:
			velocity = Vector2.ZERO
			return
		State.DASH:
			velocity = Vector2(_dash_direction * movement.dash_speed, 0.0)
		State.HURT:
			_apply_gravity(delta)
			_apply_horizontal(delta, 0.0)
		_:
			_process_control(delta, input)
	move_and_slide()
	_after_move()
	_update_state()
	_visual.facing = facing


func is_invulnerable() -> bool:
	return invulnerability_left > 0.0 or state == State.DASH


func can_dash() -> bool:
	if dash_cooldown_left > 0.0 or state in [State.DASH, State.HURT, State.DEAD]:
		return false
	return is_on_floor() or air_dashes_used < movement.air_dashes


## Px from the player's origin down to its feet, at its current size.
func get_feet_offset() -> float:
	var shape: RectangleShape2D = _collision_shape.shape
	return (_collision_shape.position.y + shape.size.y / 2.0) * scale.y


## Air jumps still available before touching the floor again.
func get_air_jumps_left() -> int:
	return max_air_jumps(run.stats.get_int(Stats.MAX_JUMPS)) - air_jumps_used


## Node that receives the player's projectiles (the level).
func set_projectile_parent(parent: Node) -> void:
	_shooter.projectile_parent = parent


func get_shooter() -> Shooter:
	return _shooter


func get_hurtbox() -> Hurtbox:
	return _hurtbox


## Applies a hit (its Hurtbox calls it): damages the run (reduced by defense
## unless the hit says otherwise), knocks the player back from the source and
## starts the invulnerability window. Hits taken while invulnerable are
## ignored. Returns whether it was applied.
func take_hit(info: DamageInfo) -> bool:
	if run == null or state == State.DEAD:
		return false
	if info.ignores_invulnerability:
		take_unavoidable_damage(info.amount, info.source_id)
		return true
	if is_invulnerable():
		return false
	run.take_damage(info.amount, info.reducible, info.source_id)
	invulnerability_left = invulnerability_time
	if state != State.DEAD:
		_knock_back(info.source_position)
	return true


## take_hit() with only an amount and where it comes from.
func take_damage(amount: float, source_position: Vector2 = Vector2.INF) -> bool:
	return take_hit(
		DamageInfo.create(amount, DamageInfo.Kind.HAZARD, UNKNOWN_SOURCE, source_position)
	)


## Damage that ignores invulnerability and defense (the Decoherence).
func take_unavoidable_damage(amount: float, source_id: StringName = UNKNOWN_SOURCE) -> void:
	if run == null or state == State.DEAD:
		return
	run.take_damage(amount, false, source_id)
	if state != State.DEAD:
		_visual.play_hurt()
		hurt.emit()


## Moves the player to a floor spot, stopped and invulnerable for a while.
func respawn_at(spot: Vector2) -> void:
	global_position = spot
	velocity = Vector2.ZERO
	dash_left = 0.0
	hurt_left = 0.0
	invulnerability_left = invulnerability_time
	_jump_cut_available = false
	reset_physics_interpolation()
	_set_state(State.FALL)
	respawned.emit()


func _process_control(delta: float, input: PlayerInput) -> void:
	if input.move_axis != 0.0:
		facing = signf(input.move_axis)
	if input.jump_pressed:
		jump_buffer_left = movement.jump_buffer_time
	if input.dash_pressed and can_dash():
		_start_dash(input.move_axis)
		return
	_apply_gravity(delta)
	_try_jump(input)
	if not input.jump_held:
		_cut_jump()
	_apply_horizontal(delta, input.move_axis)
	_try_shoot(input.shoot_direction)


## Shoots if a direction is held and the rate allows it. Shooting down in the
## air slows the fall a little (docs/04-player.md#disparo): never a jump.
func _try_shoot(direction: Vector2) -> void:
	var projectile: Projectile = _shooter.try_shoot(direction, velocity)
	if projectile == null:
		return
	var aim: Vector2 = Shooter.snap_direction(direction)
	if aim.x != 0.0:
		facing = aim.x
	if aim.y > 0.0 and not is_on_floor() and velocity.y > 0.0:
		velocity.y = maxf(0.0, velocity.y - movement.shoot_down_recoil)
	shot.emit(aim)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return
	velocity.y = minf(
		velocity.y + movement.gravity_for(velocity.y) * delta, movement.terminal_velocity
	)


func _apply_horizontal(delta: float, axis: float) -> void:
	var max_speed: float = run.stats.get_value(Stats.SPEED)
	var target: float = axis * max_speed
	var rate: float = movement.horizontal_rate(max_speed, axis != 0.0, is_on_floor())
	velocity.x = move_toward(velocity.x, target, rate * delta)


## Uses a buffered jump press: ground jump (or coyote), Down + jump through a
## one-way platform, or an air jump if the press is from this frame.
func _try_jump(input: PlayerInput) -> void:
	if jump_buffer_left <= 0.0:
		return
	var on_floor: bool = is_on_floor()
	if on_floor or coyote_left > 0.0:
		jump_buffer_left = 0.0
		if on_floor and input.down_held and _overlaps_one_way(Vector2(0.0, FLOOR_PROBE)):
			_drop_through()
		else:
			_jump(false)
	elif input.jump_pressed and get_air_jumps_left() > 0:
		jump_buffer_left = 0.0
		air_jumps_used += 1
		_jump(true)


func _jump(in_air: bool) -> void:
	var force: float = run.stats.get_value(Stats.JUMP_FORCE)
	if in_air:
		force *= movement.air_jump_ratio
	velocity.y = -force
	coyote_left = 0.0
	_jump_cut_available = true
	run.register_jump()
	_visual.play_jump(in_air)
	jumped.emit(in_air)


## Variable jump: releasing the button while rising cuts the jump once.
func _cut_jump() -> void:
	if _jump_cut_available and velocity.y < 0.0:
		velocity.y *= movement.jump_cut_ratio
	_jump_cut_available = false


func _drop_through() -> void:
	drop_through_left = movement.drop_through_time
	set_collision_mask_value(PhysicsLayers.ONE_WAY_PLATFORMS, false)


func _start_dash(axis: float) -> void:
	_dash_direction = signf(axis) if axis != 0.0 else facing
	facing = _dash_direction
	dash_left = movement.dash_duration
	jump_buffer_left = 0.0
	_jump_cut_available = false
	if not is_on_floor():
		air_dashes_used += 1
	velocity = Vector2(_dash_direction * movement.dash_speed, 0.0)
	_set_state(State.DASH)
	dashed.emit(_dash_direction)


func _end_dash() -> void:
	dash_cooldown_left = movement.dash_cooldown
	# Leave the Tunnel at running speed instead of stopping dead
	velocity.x = _dash_direction * run.stats.get_value(Stats.SPEED)
	_set_state(State.FALL)


func _knock_back(source_position: Vector2) -> void:
	var away: float = -facing
	if source_position.is_finite() and not is_equal_approx(source_position.x, global_position.x):
		away = signf(global_position.x - source_position.x)
	velocity = Vector2(away * movement.knockback.x, movement.knockback.y)
	hurt_left = movement.hurt_time
	dash_left = 0.0
	jump_buffer_left = 0.0
	_jump_cut_available = false
	_set_state(State.HURT)
	_visual.play_hurt()
	hurt.emit()


func _tick_timers(delta: float) -> void:
	coyote_left = maxf(0.0, coyote_left - delta)
	jump_buffer_left = maxf(0.0, jump_buffer_left - delta)
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	hurt_left = maxf(0.0, hurt_left - delta)
	if state == State.DASH:
		dash_left -= delta
		if dash_left <= 0.0:
			_end_dash()
	if drop_through_left > 0.0:
		drop_through_left = maxf(0.0, drop_through_left - delta)
		if drop_through_left == 0.0:
			# Stay out of the platforms until fully through them
			if _overlaps_one_way(Vector2.ZERO):
				drop_through_left = delta
			else:
				set_collision_mask_value(PhysicsLayers.ONE_WAY_PLATFORMS, true)
	_update_invulnerability(delta)


func _after_move() -> void:
	var on_floor: bool = is_on_floor()
	if on_floor:
		coyote_left = movement.coyote_time
		air_jumps_used = 0
		air_dashes_used = 0
		if not _was_on_floor:
			_visual.play_land()
			landed.emit()
		_remember_safe_spot()
	_was_on_floor = on_floor


func _update_state() -> void:
	if state in [State.DASH, State.DEAD] or (state == State.HURT and hurt_left > 0.0):
		return
	if is_on_floor():
		_set_state(State.RUN if absf(velocity.x) > RUN_THRESHOLD else State.IDLE)
	else:
		_set_state(State.JUMP if velocity.y < 0.0 else State.FALL)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old_state: State = state
	state = new_state
	_visual.set_state(new_state)
	state_changed.emit(old_state, new_state)


func _remember_safe_spot() -> void:
	if invulnerability_left > 0.0 or state in [State.HURT, State.DEAD]:
		return
	if (
		not safe_spots.is_empty()
		and safe_spots[-1].distance_to(global_position) < SAFE_SPOT_SPACING
	):
		return
	safe_spots.append(global_position)
	if safe_spots.size() > SAFE_SPOT_COUNT:
		safe_spots.remove_at(0)


## Whether the player's shape, moved by `offset`, touches a one-way platform.
func _overlaps_one_way(offset: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _collision_shape.shape
	query.transform = _collision_shape.global_transform.translated(offset)
	query.collision_mask = 1 << (PhysicsLayers.ONE_WAY_PLATFORMS - 1)
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _update_invulnerability(delta: float) -> void:
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	# Blink while invulnerable, back to fully opaque when it ends
	var blink_off: bool = fmod(invulnerability_left * blink_frequency, 1.0) < 0.5
	_visual.blink_opacity = blink_alpha if invulnerability_left > 0.0 and blink_off else 1.0


func _apply_size(value: float) -> void:
	scale = Vector2(value, value)


func _on_died() -> void:
	velocity = Vector2.ZERO
	_set_state(State.DEAD)


func _on_hp_changed(value: float, max_value: float) -> void:
	_hp_bar.max_value = max_value
	_hp_bar.value = value
	_hp_label.text = "%.2f/%s" % [value, max_value]


func _on_stat_changed(stat: StringName, value: float) -> void:
	if stat == Stats.SIZE:
		_apply_size(value)
