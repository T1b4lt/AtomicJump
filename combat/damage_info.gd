class_name DamageInfo
extends RefCounted
## One hit (docs/12-architecture.md#combate): how much damage, what dealt it and
## what it does besides hurting (knockback, status effects). A Hitbox creates it
## and the Hurtbox that receives it passes it to whatever takes the damage.

enum Kind { CONTACT, PROJECTILE, HAZARD, STATUS, THREAT }

## Damage before defense.
var amount: float = 0.0
var kind: Kind = Kind.CONTACT
## Id of what dealt it (an EnemyData id, &"spike", &"rising_threat"…): it is the
## cause of death shown at the end of the run.
var source_id: StringName = &""
## World position of the source, for the knockback direction (INF: unknown).
var source_position: Vector2 = Vector2.INF
## Knockback speed (px/s) given to the target, away from the source (0: none).
var knockback: float = 0.0
## Whether the target's defense reduces it.
var reducible: bool = true
## Whether it ignores the target's invulnerability and does not start it
## (status ticks, the Decoherence).
var ignores_invulnerability: bool = false
## Status effects applied to the target when the hit lands.
var statuses: Array[StatusEffectData] = []


static func create(
	p_amount: float,
	p_kind: Kind = Kind.CONTACT,
	p_source_id: StringName = &"",
	p_source_position: Vector2 = Vector2.INF
) -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = p_amount
	info.kind = p_kind
	info.source_id = p_source_id
	info.source_position = p_source_position
	return info


## Unit vector from the source towards `target_position` (ZERO if the source is
## unknown or in the same place).
func direction_from_source(target_position: Vector2) -> Vector2:
	if not source_position.is_finite():
		return Vector2.ZERO
	return source_position.direction_to(target_position)
