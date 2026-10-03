class_name ProjectileModifierEffect
extends ItemEffect
## Transforms every shot of the player: damage, pierce, status effects on hit
## and a wavy path (docs/12-architecture.md: the ProjectileSpec is what the
## modifiers change).

## Multiplier of the damage (1: unchanged).
@export var damage_multiplier: float = 1.0
## Extra enemies it goes through.
@export var extra_pierce: int = 0
## Status effects every hit applies (Vida media: Inestable).
@export var statuses: Array[StatusEffectData] = []
## Sideways wave of the path, in px (0: straight).
@export var wave_amplitude: float = 0.0


func modify_projectile(
	_build: Build, spec: ProjectileSpec, _direction: Vector2, _shooter_velocity: Vector2
) -> void:
	spec.damage *= damage_multiplier
	spec.pierce += extra_pierce
	spec.statuses.append_array(statuses)
	spec.wave_amplitude = maxf(spec.wave_amplitude, wave_amplitude)
