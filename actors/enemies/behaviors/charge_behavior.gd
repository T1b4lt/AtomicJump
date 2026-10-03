class_name ChargeBehavior
extends PatrolBehavior
## Heavy patrol that charges (alpha particle): when it sees the player in its
## row it warns (`warning_time`, docs/13-art-style.md: 300–500 ms), charges
## horizontally and stops when it hits a wall (stunned for a while) or reaches
## an edge. Then it recovers and patrols again.

enum Phase { PATROL, WARNING, CHARGE, STUNNED, RECOVER }

## How far it sees, in px, and how far above or below its row the player can be.
@export var sight_range: float = 560.0
@export var row_tolerance: float = 40.0
## Height of its eyes above its feet, for the line of sight.
@export var eye_height: float = 20.0
@export var warning_time: float = 0.45
@export var charge_speed: float = 520.0
## Seconds stunned after hitting a wall, and resting after an edge.
@export var stun_time: float = 0.9
@export var recover_time: float = 0.6
## Node shown while charging (its speed lines), if any.
@export var speed_lines: Node2D = null

var phase: Phase = Phase.PATROL
var _phase_left: float = 0.0


func setup(enemy: Enemy) -> void:
	super(enemy)
	_set_speed_lines(false)


func physics_step(enemy: Enemy, delta: float) -> void:
	var time_scale: float = enemy.get_time_scale()
	enemy.apply_gravity(delta)
	_phase_left = maxf(0.0, _phase_left - delta * time_scale)
	match phase:
		Phase.PATROL:
			if sees_target(enemy):
				_start_warning(enemy)
				_stand(enemy)
			else:
				patrol(enemy, delta)
		Phase.WARNING:
			_stand(enemy)
			if _phase_left == 0.0:
				phase = Phase.CHARGE
				_set_speed_lines(true)
		Phase.CHARGE:
			_charge(enemy, time_scale)
		Phase.STUNNED, Phase.RECOVER:
			_stand(enemy)
			if _phase_left == 0.0:
				phase = Phase.PATROL


## Whether the player is in its row, in range and in sight.
func sees_target(enemy: Enemy) -> bool:
	var offset: Vector2 = enemy.to_target()
	if not offset.is_finite() or enemy.is_dying():
		return false
	# The target's origin is its center: compare it with the enemy's center
	var dy: float = offset.y + eye_height
	if absf(dy) > row_tolerance or absf(offset.x) > sight_range:
		return false
	return enemy.can_see(enemy.target.global_position, eye_height)


func _start_warning(enemy: Enemy) -> void:
	phase = Phase.WARNING
	_phase_left = warning_time
	direction = signf(enemy.to_target().x) if enemy.to_target().x != 0.0 else direction
	enemy.visual.scale.x = direction
	enemy.play_warning(warning_time)


func _charge(enemy: Enemy, time_scale: float) -> void:
	if enemy.is_on_floor() and not enemy.has_floor_ahead(direction, edge_look_ahead):
		_end_charge(Phase.RECOVER, recover_time)
		_stand(enemy)
		return
	enemy.velocity.x = direction * charge_speed * time_scale + enemy.knockback_velocity.x
	enemy.move_and_slide()
	if enemy.is_on_wall() and signf(enemy.get_wall_normal().x) == -direction:
		_end_charge(Phase.STUNNED, stun_time)


func _end_charge(next: Phase, time: float) -> void:
	phase = next
	_phase_left = time
	_set_speed_lines(false)


func _stand(enemy: Enemy) -> void:
	enemy.velocity.x = enemy.knockback_velocity.x
	enemy.move_and_slide()


func _set_speed_lines(shown: bool) -> void:
	if speed_lines != null:
		speed_lines.visible = shown
