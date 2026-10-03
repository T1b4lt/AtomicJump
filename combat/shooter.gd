class_name Shooter
extends Node2D
## Shoots projectiles in 4 directions (docs/04-player.md#disparo) with the
## shooter's stats: Frecuencia (attack_rate, shots per second), Alcance
## (attack_range) and Carga (attack_power, damage). Each shot builds a
## ProjectileSpec from the stats and launches a Projectile that inherits part
## of the shooter's velocity. Its owner ticks it and asks it to shoot (call
## down); the projectiles go to `projectile_parent`, out of the shooter's
## transform.

signal shot(projectile: Projectile, direction: Vector2)

const PROJECTILE_SCENE: PackedScene = preload("res://combat/projectile.tscn")

@export var team: ProjectileSpec.Team = ProjectileSpec.Team.PLAYER
## Speed of the projectiles in px/s.
@export var projectile_speed: float = 900.0
## Fraction of the shooter's velocity that the projectiles inherit.
@export_range(0.0, 1.0) var inherit_velocity_ratio: float = 0.25
## Px from the shooter where the projectiles appear.
@export var muzzle_distance: float = 18.0

## Stats that set damage, rate and range.
var stats: Stats = null
## Node that receives the projectiles (the level). Without one, the current scene.
var projectile_parent: Node = null
## Seconds until the next shot is allowed.
var cooldown_left: float = 0.0
## func(spec: ProjectileSpec, direction: Vector2, shooter_velocity: Vector2)
## that transforms every spec before its shot (the player's build).
var spec_modifier: Callable = Callable()


## Seconds between shots for a rate in shots per second.
static func cooldown_for(rate: float) -> float:
	return 1.0 / rate if rate > 0.0 else INF


## Unit vector of the 4-way direction closest to `direction` (vertical wins
## ties), or ZERO.
static func snap_direction(direction: Vector2) -> Vector2:
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	if absf(direction.y) >= absf(direction.x):
		return Vector2(0.0, signf(direction.y))
	return Vector2(signf(direction.x), 0.0)


func tick(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)


func can_shoot() -> bool:
	return stats != null and cooldown_left <= 0.0


## The spec of a shot with the current stats (spec_modifier transforms it).
func make_spec() -> ProjectileSpec:
	var spec := ProjectileSpec.new()
	spec.team = team
	spec.speed = projectile_speed
	spec.damage = stats.get_value(Stats.ATTACK_POWER)
	spec.attack_range = stats.get_value(Stats.ATTACK_RANGE)
	return spec


## Shoots towards `direction` (snapped to 4 directions) if the rate allows it.
## Returns the projectile, or null.
func try_shoot(direction: Vector2, shooter_velocity: Vector2 = Vector2.ZERO) -> Projectile:
	var aim: Vector2 = snap_direction(direction)
	if aim == Vector2.ZERO or not can_shoot():
		return null
	cooldown_left = cooldown_for(stats.get_value(Stats.ATTACK_RATE))
	return _launch(aim, shooter_velocity)


## Fires `count` projectiles evenly around the shooter at once, ignoring the
## rate (Efecto fotoeléctrico). Returns them.
func shoot_burst(count: int, shooter_velocity: Vector2 = Vector2.ZERO) -> Array[Projectile]:
	var projectiles: Array[Projectile] = []
	if stats == null or count <= 0:
		return projectiles
	for i: int in count:
		projectiles.append(_launch(Vector2.RIGHT.rotated(TAU * i / count), shooter_velocity))
	return projectiles


func _launch(direction: Vector2, shooter_velocity: Vector2) -> Projectile:
	var spec: ProjectileSpec = make_spec()
	if spec_modifier.is_valid():
		spec_modifier.call(spec, direction, shooter_velocity)
	var origin: Vector2 = global_position + direction * muzzle_distance
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	projectile.launch(spec, origin, direction, shooter_velocity * inherit_velocity_ratio)
	var parent: Node = projectile_parent
	if parent == null:
		parent = get_tree().current_scene
	parent.add_child(projectile)
	projectile.global_position = origin
	shot.emit(projectile, direction)
	return projectile
