extends GdUnitTestSuite

## Tests de las capas de física: nombres del proyecto y capas de cada escena.

const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")
const COIN_SCENE: PackedScene = preload("res://items/pickups/coin/coin.tscn")
const KEY_SCENE: PackedScene = preload("res://items/pickups/key/key.tscn")
const BLOCK_SCENE: PackedScene = preload("res://world/chunks/parts/blocks/block_2.tscn")
const WALL_SCENE: PackedScene = preload("res://world/chunks/parts/walls/wall_normal.tscn")


func test_project_layer_names() -> void:
	for layer: int in PhysicsLayers.NAMES:
		var setting: String = "layer_names/2d_physics/layer_%d" % layer
		assert_str(ProjectSettings.get_setting(setting)).is_equal(PhysicsLayers.NAMES[layer])


func test_player_collides_with_world_and_one_way_platforms() -> void:
	var player: Player = auto_free(PLAYER_SCENE.instantiate())
	assert_int(player.collision_layer).is_equal(_bits([PhysicsLayers.PLAYER]))
	assert_int(player.collision_mask).is_equal(
		_bits([PhysicsLayers.WORLD, PhysicsLayers.ONE_WAY_PLATFORMS])
	)


func test_pickups_detect_the_player() -> void:
	for scene: PackedScene in [COIN_SCENE, KEY_SCENE]:
		var pickup: Area2D = auto_free(scene.instantiate())
		assert_int(pickup.collision_layer).is_equal(_bits([PhysicsLayers.PICKUPS]))
		assert_int(pickup.collision_mask).is_equal(_bits([PhysicsLayers.PLAYER]))


func test_blocks_are_one_way_platforms_and_walls_are_world() -> void:
	var block: StaticBody2D = auto_free(BLOCK_SCENE.instantiate())
	var wall: StaticBody2D = auto_free(WALL_SCENE.instantiate())
	assert_int(block.collision_layer).is_equal(_bits([PhysicsLayers.ONE_WAY_PLATFORMS]))
	assert_int(wall.collision_layer).is_equal(_bits([PhysicsLayers.WORLD]))


func _bits(layers: Array[int]) -> int:
	var bits: int = 0
	for layer: int in layers:
		bits |= 1 << (layer - 1)
	return bits
