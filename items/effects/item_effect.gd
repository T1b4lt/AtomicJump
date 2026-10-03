class_name ItemEffect
extends Resource
## Base of the effects of items and transformations (docs/12-architecture.md,
## "Objetos e interacciones"). Each effect is a reusable resource that answers
## some hooks of the player and of the combat; Build calls them. The resources
## in the .tres files are templates: Build duplicates one per item it applies,
## so an effect can keep its own state in plain variables.

## Id of the item (or transformation) that applies it, for stat modifiers.
var source: StringName = &""


## The item was gained.
func added(_build: Build) -> void:
	pass


## The item was lost (an operator swapped for another).
func removed(_build: Build) -> void:
	pass


## A shot of the player is about to be launched: transform its spec.
func modify_projectile(
	_build: Build, _spec: ProjectileSpec, _direction: Vector2, _shooter_velocity: Vector2
) -> void:
	pass


## A shot of the player hit something.
func projectile_hit(_build: Build, _info: DamageInfo, _at: Vector2) -> void:
	pass


## Photons were collected.
func coins_collected(_build: Build, _amount: int) -> void:
	pass


## The player entered a new chunk of the layer (its index in the column).
func chunk_entered(_build: Build, _index: int) -> void:
	pass


## Every physics frame of the player.
func physics_step(_build: Build, _delta: float) -> void:
	pass


## Operators: the effect of using it. Returns whether something happened.
func activate(_build: Build) -> bool:
	return false
