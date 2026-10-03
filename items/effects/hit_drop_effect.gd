class_name HitDropEffect
extends ItemEffect
## Each hit of a shot has a chance of dropping a pickup where it lands
## (Efecto Compton). It is a combat roll: not guaranteed by the seed.

@export_range(0.0, 1.0) var chance: float = 0.1
## Chunk object id of what it drops.
@export var object_id: StringName = &"coin"


func projectile_hit(build: Build, info: DamageInfo, at: Vector2) -> void:
	if info.kind == DamageInfo.Kind.PROJECTILE and build.combat_rng.randf() < chance:
		build.spawn(object_id, at)
