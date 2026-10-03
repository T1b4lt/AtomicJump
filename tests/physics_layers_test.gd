extends GdUnitTestSuite

## Tests de las capas de física: nombres del proyecto y capas de cada escena.

const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")
const COIN_SCENE: PackedScene = preload("res://items/pickups/coin/coin.tscn")
const KEY_SCENE: PackedScene = preload("res://items/pickups/key/key.tscn")
const TILESET: TileSet = preload("res://world/tilesets/layer_k_tileset.tres")
const SPIKE_SCENE: PackedScene = preload("res://world/hazards/spike/spike.tscn")


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


func test_tileset_solid_tiles_are_world_and_virtual_levels_one_way() -> void:
	assert_int(TILESET.get_physics_layers_count()).is_equal(2)
	assert_int(TILESET.get_physics_layer_collision_layer(0)).is_equal(_bits([PhysicsLayers.WORLD]))
	assert_int(TILESET.get_physics_layer_collision_layer(1)).is_equal(
		_bits([PhysicsLayers.ONE_WAY_PLATFORMS])
	)
	var source: TileSetAtlasSource = TILESET.get_source(0)
	var wall: TileData = source.get_tile_data(Vector2i(0, 0), 0)
	var energy_level: TileData = source.get_tile_data(Vector2i(2, 2), 0)
	var virtual_level: TileData = source.get_tile_data(Vector2i(4, 2), 0)
	assert_int(wall.get_collision_polygons_count(0)).is_equal(1)
	assert_int(energy_level.get_collision_polygons_count(0)).is_equal(1)
	assert_int(virtual_level.get_collision_polygons_count(0)).is_equal(0)
	assert_bool(virtual_level.is_collision_polygon_one_way(1, 0)).is_true()


func test_spikes_are_hazards_that_detect_the_player() -> void:
	var spike: Area2D = auto_free(SPIKE_SCENE.instantiate())
	assert_int(spike.collision_layer).is_equal(_bits([PhysicsLayers.HAZARDS]))
	assert_int(spike.collision_mask).is_equal(_bits([PhysicsLayers.PLAYER]))


func _bits(layers: Array[int]) -> int:
	var bits: int = 0
	for layer: int in layers:
		bits |= 1 << (layer - 1)
	return bits
