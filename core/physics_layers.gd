class_name PhysicsLayers
extends RefCounted
## 2D physics layer numbers (1-based, as in the editor and in
## set_collision_layer_value()). Names in project.godot, table in
## docs/12-architecture.md#combate.

const WORLD: int = 1
const PLAYER: int = 2
const ENEMIES: int = 3
const PICKUPS: int = 4
const PLAYER_PROJECTILES: int = 5
const ENEMY_PROJECTILES: int = 6
const HAZARDS: int = 7
const ONE_WAY_PLATFORMS: int = 8
const RISING_THREAT: int = 9

## Layer names as written in project.godot, by layer number.
const NAMES: Dictionary[int, String] = {
	WORLD: "world",
	PLAYER: "player",
	ENEMIES: "enemies",
	PICKUPS: "pickups",
	PLAYER_PROJECTILES: "player_projectiles",
	ENEMY_PROJECTILES: "enemy_projectiles",
	HAZARDS: "hazards",
	ONE_WAY_PLATFORMS: "one_way_platforms",
	RISING_THREAT: "rising_threat",
}
