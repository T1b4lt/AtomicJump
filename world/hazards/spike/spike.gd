class_name Spike
extends Hitbox
## Potential spikes (picos de potencial): a continuous Hitbox on the hazards
## layer that hurts the player's Hurtbox while in contact. The player's
## invulnerability window sets the rate, so standing on them keeps hurting.
## The origin is the middle of their base: place it on the surface of a
## platform (slot_hazard markers are placed there).

## Cause of death when they kill the player.
const SOURCE_ID: StringName = &"spike"


func _init() -> void:
	kind = DamageInfo.Kind.HAZARD
	source_id = SOURCE_ID
	continuous = true
