class_name PatrolBehavior
extends EnemyBehavior
## Walks back and forth on its platform (free neutron): turns at walls and at
## the edges, so it never falls off. Its first direction comes from the
## enemy's ai_rng. The enemy's origin is at its feet.

## Px ahead of the feet where the floor is checked before stepping.
@export var edge_look_ahead: float = 18.0
## Seconds it stops after turning around.
@export var turn_pause: float = 0.25

## -1 left, 1 right.
var direction: float = 1.0
var _pause_left: float = 0.0


func setup(enemy: Enemy) -> void:
	direction = 1.0 if enemy.ai_rng.randf() < 0.5 else -1.0


func physics_step(enemy: Enemy, delta: float) -> void:
	enemy.apply_gravity(delta)
	patrol(enemy, delta)


## One frame of patrolling (gravity apart): pauses after turning, then walks.
func patrol(enemy: Enemy, delta: float) -> void:
	var time_scale: float = enemy.get_time_scale()
	_pause_left = maxf(0.0, _pause_left - delta * time_scale)
	var speed: float = 0.0 if _pause_left > 0.0 else enemy.data.speed * time_scale
	walk(enemy, speed)


## Moves at `speed` in the current direction (plus the knockback), turning
## around at walls and edges.
func walk(enemy: Enemy, speed: float) -> void:
	if enemy.is_on_floor() and not enemy.has_floor_ahead(direction, edge_look_ahead):
		turn_around()
		speed = 0.0
	enemy.velocity.x = direction * speed + enemy.knockback_velocity.x
	enemy.move_and_slide()
	if enemy.is_on_wall() and signf(enemy.get_wall_normal().x) == -direction:
		turn_around()
	enemy.visual.scale.x = direction


func turn_around() -> void:
	direction = -direction
	_pause_left = turn_pause
