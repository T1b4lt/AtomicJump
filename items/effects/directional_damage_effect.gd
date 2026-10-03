class_name DirectionalDamageEffect
extends ItemEffect
## More damage when shooting in the direction the player moves (Efecto Doppler).

## Damage bonus (0.3 = +30 %).
@export var damage_bonus: float = 0.3
## Px/s the player must move along the shot's direction.
@export var min_speed: float = 60.0


func modify_projectile(
	_build: Build, spec: ProjectileSpec, direction: Vector2, shooter_velocity: Vector2
) -> void:
	if applies(direction, shooter_velocity):
		spec.damage *= 1.0 + damage_bonus


func applies(direction: Vector2, shooter_velocity: Vector2) -> bool:
	return shooter_velocity.dot(direction.normalized()) >= min_speed
