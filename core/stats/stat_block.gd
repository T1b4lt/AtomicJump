class_name StatBlock
extends Resource
## Base statistics of a character. Property names match the ids in Stats.ALL.
## See docs/04-player.md#estadísticas.

@export var max_hp: float = 100.0
## 0 to 100 points.
@export var luck: float = 0.0
## Horizontal speed in px/s.
@export var speed: float = 300.0
## Upward jump speed in px/s.
@export var jump_force: float = 450.0
## Chained jumps, ground jump included (2 = double jump).
@export var max_jumps: float = 2.0
## Scale of the sprite and the collision.
@export var size: float = 1.0
## Damage per projectile.
@export var attack_power: float = 5.0
## Shots per second.
@export var attack_rate: float = 2.5
## Projectile distance in px.
@export var attack_range: float = 450.0
## Fraction of damage blocked (0.25 = 25 %).
@export var defense: float = 0.0


func get_base(stat: StringName) -> float:
	assert(stat in Stats.ALL, "Unknown stat: %s" % stat)
	return get(stat)
