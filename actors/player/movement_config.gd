class_name MovementConfig
extends Resource
## How the player moves: acceleration, gravity, jump assists and the Tunnel (dash).
## Speed, jump force and the number of jumps are stats (Stats.SPEED,
## Stats.JUMP_FORCE, Stats.MAX_JUMPS); this resource shapes how they feel.
## Values and reasons in docs/04-player.md#movimiento.

@export_group("Run")
## Seconds from standing still to full speed on the floor.
@export var acceleration_time: float = 0.08
## Seconds from full speed to standing still on the floor.
@export var deceleration_time: float = 0.06
## Seconds from standing still to full speed in the air (a bit less grip).
@export var air_acceleration_time: float = 0.12
## Seconds from full speed to standing still in the air.
@export var air_deceleration_time: float = 0.16

@export_group("Gravity")
## Gravity while rising, in px/s². With jump_force 450 a ground jump rises ~100 px.
@export var rise_gravity: float = 980.0
## Gravity while falling, as a multiple of rise_gravity: falling is faster (weight).
@export var fall_gravity_multiplier: float = 1.6
## Maximum falling speed in px/s. Keeps falls controllable and avoids tunnelling.
@export var terminal_velocity: float = 820.0

@export_group("Jump")
## Upward speed kept when the jump button is released while rising (variable jump).
@export_range(0.0, 1.0) var jump_cut_ratio: float = 0.45
## Air jumps (quantum jumps) use this fraction of jump_force.
@export_range(0.0, 2.0) var air_jump_ratio: float = 0.92
## Seconds after leaving a ledge during which a ground jump is still allowed.
@export var coyote_time: float = 0.1
## Seconds a jump press is remembered before landing.
@export var jump_buffer_time: float = 0.12
## Seconds the one-way platforms are ignored after Down + jump.
@export var drop_through_time: float = 0.2

@export_group("Tunnel (dash)")
## Horizontal speed of the Tunnel in px/s (distance = speed × duration).
@export var dash_speed: float = 900.0
## Seconds the Tunnel lasts; the player is invulnerable meanwhile.
@export var dash_duration: float = 0.15
## Seconds after a Tunnel ends before another one can start.
@export var dash_cooldown: float = 0.6
## Tunnels allowed in the air before touching the floor again.
@export var air_dashes: int = 1

@export_group("Shooting")
## Falling speed (px/s) each shot downwards takes away in the air. It never
## pushes upwards: it slows the fall, it is not a jump.
@export var shoot_down_recoil: float = 140.0

@export_group("Hurt")
## Seconds of knockback (no control) after taking damage.
@export var hurt_time: float = 0.2
## Knockback speed: horizontal away from the hit, and upwards.
@export var knockback: Vector2 = Vector2(260.0, -220.0)


## Gravity for the current vertical speed: stronger when falling.
func gravity_for(vertical_velocity: float) -> float:
	if vertical_velocity > 0.0:
		return rise_gravity * fall_gravity_multiplier
	return rise_gravity


## Horizontal speed change per second towards `target` (px/s²), from the time it
## takes to go from 0 to `max_speed` (or back).
func horizontal_rate(max_speed: float, accelerating: bool, on_floor: bool) -> float:
	var time: float
	if on_floor:
		time = acceleration_time if accelerating else deceleration_time
	else:
		time = air_acceleration_time if accelerating else air_deceleration_time
	if time <= 0.0:
		return INF
	return max_speed / time
