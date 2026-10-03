class_name ProjectileSpec
extends Resource
## What a projectile is (docs/12-architecture.md, "Objetos e interacciones"):
## damage, speed, range, size and what it does on impact. A Shooter builds one
## from the stats for every shot, and projectile modifiers (Phase 7 onwards)
## transform it before the projectile is launched.

enum Team { PLAYER, ENEMY }

@export var team: Team = Team.PLAYER
@export var damage: float = 5.0
## Speed in px/s.
@export var speed: float = 900.0
## Distance in px before it fades out.
@export var attack_range: float = 450.0
## Scale of the sprite and of the collision.
@export var size: float = 1.0
## Extra targets it goes through (0: it stops at the first one).
@export var pierce: int = 0
## Knockback speed (px/s) given to what it hits.
@export var knockback: float = 120.0
## Cause of death if it kills the player (enemy projectiles).
@export var source_id: StringName = &""
## Status effects every hit applies.
@export var statuses: Array[StatusEffectData] = []
