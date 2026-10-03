class_name EnemyBehavior
extends Node
## A reusable way of moving (docs/09-enemies.md): patrol, orbit, charge… The
## Enemy calls it down every physics frame. Speeds and timers are scaled by
## Enemy.get_time_scale() (slowed or rooted by status effects).


## Called once when the enemy is ready.
func setup(_enemy: Enemy) -> void:
	pass


## One physics frame of movement.
func physics_step(_enemy: Enemy, _delta: float) -> void:
	pass


## Called once when the enemy dies or vanishes: hide what it draws.
func stop(_enemy: Enemy) -> void:
	pass
