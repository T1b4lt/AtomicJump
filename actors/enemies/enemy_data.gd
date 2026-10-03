class_name EnemyData
extends Resource
## Stats of an enemy type (docs/09-enemies.md): health, contact damage, speed,
## what it drops and what it decays into. Health and damage scale with the
## layer. The resources live in data/enemies/; the behaviour is in the scene.

## Health and damage grow by this fraction per layer index (K is 0).
const LAYER_SCALING: float = 0.25
## Object id of the photons it drops: Chunk.COIN, not referenced because the
## Chunk script loads the enemy scenes (it would be a cyclic load).
const COIN_DROP: StringName = &"coin"

## Code name (orbital_electron…): the object id of the slots and the cause of death.
@export var id: StringName = &""
@export var name_key: String = ""
@export var max_hp: float = 10.0
## Damage of touching it, before the player's defense.
@export var contact_damage: float = 10.0
## Movement speed in px/s (its behaviour decides how it is used).
@export var speed: float = 60.0
## Fraction of the knockback of the hits that it ignores.
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0

@export_group("Drops")
## Chance of dropping photons when it dies, and how many (rolled in [x, y]).
@export_range(0.0, 1.0) var coin_drop_chance: float = 0.3
@export var coin_drop_count: Vector2i = Vector2i(1, 2)

@export_group("Decay")
## Enemy that appears where it dies (a free neutron decays into an electron).
@export var decay_scene: PackedScene = null
## Seconds the decay product lives before vanishing.
@export var decay_lifetime: float = 5.0


## A value scaled for the layer: × (1 + LAYER_SCALING × layer_index).
static func scale_for_layer(value: float, layer_index: int) -> float:
	return value * (1.0 + LAYER_SCALING * layer_index)


func get_max_hp(layer_index: int) -> float:
	return scale_for_layer(max_hp, layer_index)


func get_contact_damage(layer_index: int) -> float:
	return scale_for_layer(contact_damage, layer_index)


## Objects (COIN_DROP…) dropped by the enemy that spawned at `address`. The
## roll is addressed with its slot (domain "drop"), so it is the same in every
## run with the seed; `chance_multiplier` is where upgrades will raise it.
func roll_drops(rng: WorldRng, address: Array, chance_multiplier: float = 1.0) -> Array[StringName]:
	var drops: Array[StringName] = []
	if rng == null or not rng.chance(coin_drop_chance * chance_multiplier, &"drop", address):
		return drops
	var count: int = rng.roll_range(
		coin_drop_count.x, coin_drop_count.y, &"drop", address + [&"count"]
	)
	for _i: int in count:
		drops.append(COIN_DROP)
	return drops
