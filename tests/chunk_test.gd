extends GdUnitTestSuite

## Tests de los tramos (docs/05-world.md): todos los de la capa pasan el validador,
## la biblioteca los indexa, y un tramo se refleja, rellena sus huecos, elige
## sus partes opcionales y monta sus salidas de bifurcación o su recompensa.

const LAYER: LayerData = preload("res://data/layers/layer_k.tres")
const TEMPLATE: PackedScene = preload("res://world/chunks/chunk_template.tscn")
const LADDER: PackedScene = preload("res://world/chunks/k/k_ladder.tscn")
const ZIGZAG: PackedScene = preload("res://world/chunks/k/k_zigzag.tscn")
const FORK: PackedScene = preload("res://world/chunks/k/k_fork.tscn")
const REWARD: PackedScene = preload("res://world/chunks/k/k_reward_arch.tscn")
const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")


func test_every_layer_chunk_is_valid() -> void:
	for scene: PackedScene in LAYER.chunks:
		var chunk: Chunk = auto_free(scene.instantiate())
		(
			assert_array(ChunkValidator.validate(chunk))
			. override_failure_message(
				"%s: %s" % [scene.resource_path, ChunkValidator.validate(chunk)]
			)
			. is_empty()
		)


func test_template_only_lacks_an_id() -> void:
	var chunk: Chunk = auto_free(TEMPLATE.instantiate())
	assert_array(ChunkValidator.validate(chunk)).contains_exactly(["The ChunkData has no id."])


func test_library_indexes_the_layer() -> void:
	var library: ChunkLibrary = ChunkLibrary.from_layers([LAYER])
	assert_int(library.get_ids().size()).is_equal(LAYER.chunks.size())
	assert_int(library.get_chunks("K", ChunkData.Type.NORMAL).size()).is_equal(8)
	for type: ChunkData.Type in LAYER.template:
		assert_array(library.get_chunks("K", type)).is_not_empty()
	assert_array(library.get_chunks("K", ChunkData.Type.REWARD)).is_not_empty()
	assert_array(library.get_chunks("L", ChunkData.Type.NORMAL)).is_empty()
	var easy: Array[ChunkInfo] = library.get_chunks("K", ChunkData.Type.NORMAL, 1, 1)
	for info: ChunkInfo in easy:
		assert_int(info.data.difficulty).is_equal(1)
	# Normal chunks cover every opening, so no exit is a dead end
	var entries: int = 0
	for info: ChunkInfo in library.get_chunks("K", ChunkData.Type.NORMAL):
		entries |= info.entries
	assert_int(entries).is_equal(Chunk.ALL_OPENINGS)


func test_library_reads_markers_and_slots() -> void:
	var info: ChunkInfo = ChunkInfo.from_scene(ZIGZAG)
	assert_str(info.id).is_equal(&"k_zigzag")
	assert_int(info.entries).is_equal(Chunk.Opening.CENTER)
	assert_int(info.exits).is_equal(Chunk.Opening.LEFT)
	assert_int(info.get_exits(true)).is_equal(Chunk.Opening.RIGHT)
	assert_array(info.optional_parts).contains_exactly([&"optional_a"])
	assert_str(info.slots[&"slot_hazard_1"]).is_equal(Chunk.SLOT_HAZARD)
	assert_str(info.slots[&"slot_pickup_1"]).is_equal(Chunk.SLOT_PICKUP)


func test_openings_and_slot_kinds() -> void:
	assert_int(Chunk.opening_at(Chunk.INNER_LEFT + 1.0)).is_equal(Chunk.Opening.LEFT)
	assert_int(Chunk.opening_at(Chunk.WIDTH / 2.0)).is_equal(Chunk.Opening.CENTER)
	assert_int(Chunk.opening_at(Chunk.INNER_RIGHT - 1.0)).is_equal(Chunk.Opening.RIGHT)
	assert_int(Chunk.mirror_openings(Chunk.Opening.LEFT | Chunk.Opening.CENTER)).is_equal(
		Chunk.Opening.RIGHT | Chunk.Opening.CENTER
	)
	assert_str(Chunk.slot_kind(&"slot_enemy_air_12")).is_equal(Chunk.SLOT_ENEMY_AIR)
	assert_str(Chunk.slot_kind(&"slot_pickup")).is_empty()
	assert_str(Chunk.slot_kind(&"coin_1")).is_empty()


func test_validator_reports_broken_chunks() -> void:
	var chunk: Chunk = auto_free(TEMPLATE.instantiate())
	chunk.data = ChunkData.new()
	chunk.data.id = &"broken"
	chunk.get_walls().erase_cell(Vector2i(0, 5))
	chunk.get_walls().set_cell(Vector2i(20, 0), 0, Vector2i(0, 0))
	chunk.get_walls().set_cell(Vector2i(45, 3), 0, Vector2i(0, 0))
	(chunk.get_marker(&"entry_center") as Node2D).position.y = 300.0
	var slots: Node = chunk.get_node(^"Slots")
	var overlapping := Marker2D.new()
	overlapping.name = "slot_pickup_2"
	overlapping.position = (slots.get_child(0) as Node2D).position + Vector2(4, 0)
	slots.add_child(overlapping)
	var unknown := Marker2D.new()
	unknown.name = "treasure"
	unknown.position = Vector2(500, 300)
	slots.add_child(unknown)
	var problems: String = "\n".join(ChunkValidator.validate(chunk))
	assert_str(problems).contains("gap at row 5")
	assert_str(problems).contains("Solid tiles block exit_center")
	assert_str(problems).contains("outside the chunk")
	assert_str(problems).contains("entry_center must be on the bottom edge")
	assert_str(problems).contains("overlap")
	assert_str(problems).contains("Unknown slot kind: treasure")


func test_validator_requires_a_closed_fork_ceiling() -> void:
	var chunk: Chunk = auto_free(FORK.instantiate())
	assert_array(ChunkValidator.validate(chunk)).is_empty()
	chunk.get_walls().erase_cell(Vector2i(20, 0))
	assert_str("\n".join(ChunkValidator.validate(chunk))).contains("closed ceiling")


func test_validator_rejects_solid_optional_parts() -> void:
	var chunk: Chunk = auto_free(ZIGZAG.instantiate())
	var optional: TileMapLayer = chunk.get_optional_layers()[0]
	optional.set_cell(Vector2i(30, 15), 0, Vector2i(2, 2))
	assert_str("\n".join(ChunkValidator.validate(chunk))).contains("only use one-way")


func test_mirror_flips_tiles_and_markers() -> void:
	var chunk: Chunk = auto_free(ZIGZAG.instantiate())
	var walls: TileMapLayer = chunk.get_platforms()
	var cell: Vector2i = walls.get_used_cells()[0]
	var atlas: Vector2i = walls.get_cell_atlas_coords(cell)
	var exit_x: float = chunk.get_exit_markers()[0].position.x
	var slot: Node2D = chunk.get_slot_nodes()[0]
	var slot_x: float = slot.position.x
	chunk.apply_mirror()
	var mirrored_cell := Vector2i(Chunk.COLUMNS - 1 - cell.x, cell.y)
	assert_vector(walls.get_cell_atlas_coords(mirrored_cell)).is_equal(atlas)
	assert_int(walls.get_cell_alternative_tile(mirrored_cell)).is_equal(
		TileSetAtlasSource.TRANSFORM_FLIP_H
	)
	assert_float(chunk.get_exit_markers()[0].position.x).is_equal(Chunk.WIDTH - exit_x)
	assert_int(ChunkInfo.read_openings(chunk.get_exit_markers())).is_equal(Chunk.Opening.RIGHT)
	assert_float(slot.position.x).is_equal(Chunk.WIDTH - slot_x)
	assert_array(ChunkValidator.validate(chunk)).is_empty()


func test_optional_parts_are_enabled_by_name() -> void:
	var chunk: Chunk = auto_free(ZIGZAG.instantiate())
	chunk.set_optional_parts([])
	assert_bool(chunk.get_optional_layers()[0].enabled).is_false()
	chunk.set_optional_parts([&"optional_a"])
	assert_bool(chunk.get_optional_layers()[0].enabled).is_true()


func test_fill_slots_places_objects_on_the_slots() -> void:
	var chunk: Chunk = auto_free(LADDER.instantiate())
	add_child(chunk)
	var before: int = chunk.get_child_count()
	var plan: Dictionary[StringName, StringName] = {
		&"slot_pickup_1": Chunk.COIN, &"slot_pickup_2": Chunk.KEY
	}
	chunk.fill_slots(plan)
	assert_int(chunk.get_child_count()).is_equal(before + 2)
	var key: Node2D = chunk.get_child(chunk.get_child_count() - 1)
	assert_object(key).is_instanceof(KeyPickup)
	assert_vector(key.position).is_equal(
		(chunk.get_node(^"Slots/slot_pickup_2") as Node2D).position
	)


func test_reward_chunk_spawns_its_reward() -> void:
	var coins: Chunk = auto_free(REWARD.instantiate())
	var before: int = coins.get_child_count()
	coins.spawn_reward(LayerData.REWARD_COINS)
	assert_int(coins.get_child_count()).is_equal(before + Chunk.REWARD_COINS)
	var key: Chunk = auto_free(REWARD.instantiate())
	key.spawn_reward(LayerData.REWARD_KEY)
	assert_object(key.get_child(key.get_child_count() - 1)).is_instanceof(KeyPickup)


func test_fork_collapses_the_exit_not_taken() -> void:
	var chunk: Chunk = auto_free(FORK.instantiate())
	chunk.setup_fork([LayerData.REWARD_COINS, LayerData.REWARD_KEY])
	add_child(chunk)
	var gates: Array[ForkGate] = chunk.get_gates()
	assert_int(gates.size()).is_equal(2)
	assert_float(gates[0].position.x).is_less(gates[1].position.x)
	assert_str(gates[1].reward).is_equal(LayerData.REWARD_KEY)
	var sides: Array[int] = []
	chunk.branch_chosen.connect(func(side: int) -> void: sides.append(side))
	var player: Player = auto_free(PLAYER_SCENE.instantiate())
	gates[1]._on_trigger_body_entered(player)
	gates[0]._on_trigger_body_entered(player)
	assert_array(sides).contains_exactly([1])
	assert_bool(gates[0].collapsed).is_true()
	assert_bool(gates[1].chosen).is_true()
	await get_tree().process_frame
	assert_bool(gates[0].is_blocking()).is_true()
	assert_bool(gates[1].is_blocking()).is_false()
