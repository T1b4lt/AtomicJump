@tool
class_name ChunkValidator
extends RefCounted
## Checks the authoring rules of a chunk (docs/05-world.md#herramientas-de-autoría):
## metadata, entry and exit markers on their edges, tiles inside the bounds,
## continuous side walls, free openings, a fork's ceiling, slots that do not
## overlap and optional parts that cannot block the way. Returns one message
## per problem (none if the chunk is valid). Chunk shows them as configuration
## warnings in the editor and the tests require every chunk to pass.

## Minimum distance (px) from the center of a slot to anything else, per kind:
## two slots overlap when they are closer than the sum of their radii.
const SLOT_RADIUS: Dictionary[StringName, float] = {
	Chunk.SLOT_PICKUP: 16.0,
	Chunk.SLOT_CONTAINER: 32.0,
	Chunk.SLOT_ENEMY_GROUND: 32.0,
	Chunk.SLOT_ENEMY_AIR: 32.0,
	Chunk.SLOT_HAZARD: 32.0,
	Chunk.SLOT_SECRET: 32.0,
}
## Rows next to the edge kept free of solid tiles around entries (bottom) and exits (top).
const OPENING_ROWS: int = 2
## How far (px) a marker may be from the edge it belongs to.
const EDGE_TOLERANCE: float = Chunk.TILE
## Physics layer of the tileset with the solid (not one-way) collisions.
const SOLID_PHYSICS_LAYER: int = 0


static func validate(chunk: Chunk) -> PackedStringArray:
	var problems: PackedStringArray = []
	if chunk.data == null:
		problems.append("Missing the ChunkData resource in `data`.")
		return problems
	if chunk.data.id.is_empty():
		problems.append("The ChunkData has no id.")
	if chunk.get_walls() == null or chunk.get_platforms() == null:
		problems.append("Missing the Tiles/Walls or Tiles/Platforms TileMapLayer.")
		return problems
	_check_markers(chunk, problems)
	_check_bounds(chunk, problems)
	_check_side_walls(chunk, problems)
	_check_openings(chunk, problems)
	if chunk.data.type == ChunkData.Type.FORK:
		_check_fork(chunk, problems)
	_check_slots(chunk, problems)
	_check_optional_parts(chunk, problems)
	return problems


## Whether the cell of the layer has a solid (not one-way) collision.
static func is_solid(layer: TileMapLayer, cell: Vector2i) -> bool:
	var tile: TileData = layer.get_cell_tile_data(cell)
	return tile != null and tile.get_collision_polygons_count(SOLID_PHYSICS_LAYER) > 0


## Whether any of the chunk's required layers (walls, platforms) is solid at the cell.
static func is_solid_at(chunk: Chunk, cell: Vector2i) -> bool:
	return is_solid(chunk.get_walls(), cell) or is_solid(chunk.get_platforms(), cell)


## Cell that contains a point in chunk px.
static func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / Chunk.TILE), floori(point.y / Chunk.TILE))


## Columns of the opening centered on a marker's x.
static func opening_columns(x: float) -> Array[int]:
	var first: int = floori(x / Chunk.TILE - Chunk.OPENING_TILES / 2.0)
	var columns: Array[int] = []
	for column: int in range(first, first + Chunk.OPENING_TILES):
		columns.append(column)
	return columns


static func _check_markers(chunk: Chunk, problems: PackedStringArray) -> void:
	var type: ChunkData.Type = chunk.data.type
	var entries: Array[Marker2D] = chunk.get_entry_markers()
	var exits: Array[Marker2D] = chunk.get_exit_markers()
	if entries.is_empty() and type != ChunkData.Type.LAYER_START:
		problems.append("Needs at least one entry_* marker on the bottom edge.")
	if exits.is_empty():
		problems.append("Needs at least one exit_* marker on the top edge.")
	for marker: Marker2D in entries:
		if absf(marker.position.y - chunk.get_height()) > EDGE_TOLERANCE:
			problems.append("%s must be on the bottom edge." % marker.name)
		_check_inside_walls(marker, problems)
	for marker: Marker2D in exits:
		if absf(marker.position.y) > EDGE_TOLERANCE:
			problems.append("%s must be on the top edge." % marker.name)
		_check_inside_walls(marker, problems)
	if type == ChunkData.Type.LAYER_START and chunk.get_marker(Chunk.SPAWN_MARKER) == null:
		problems.append("A layer start needs a `spawn` marker.")
	if type == ChunkData.Type.REWARD and chunk.get_marker(Chunk.REWARD_MARKER) == null:
		problems.append("A reward chunk needs a `reward` marker.")


static func _check_inside_walls(marker: Node2D, problems: PackedStringArray) -> void:
	if marker.position.x <= Chunk.INNER_LEFT or marker.position.x >= Chunk.INNER_RIGHT:
		problems.append("%s must be between the side walls." % marker.name)


static func _check_bounds(chunk: Chunk, problems: PackedStringArray) -> void:
	var rows: int = chunk.data.height_tiles
	for layer: TileMapLayer in chunk.get_tile_layers():
		for cell: Vector2i in layer.get_used_cells():
			if cell.x < 0 or cell.x >= Chunk.COLUMNS or cell.y < 0 or cell.y >= rows:
				problems.append("%s has tiles outside the chunk (cell %s)." % [layer.name, cell])
				break


static func _check_side_walls(chunk: Chunk, problems: PackedStringArray) -> void:
	var walls: TileMapLayer = chunk.get_walls()
	for row: int in chunk.data.height_tiles:
		for column: int in [0, Chunk.COLUMNS - 1]:
			if walls.get_cell_source_id(Vector2i(column, row)) == -1:
				problems.append("The side walls must be continuous (gap at row %d)." % row)
				return


static func _check_openings(chunk: Chunk, problems: PackedStringArray) -> void:
	var rows: int = chunk.data.height_tiles
	for marker: Marker2D in chunk.get_entry_markers():
		if _blocked(chunk, marker.position.x, range(rows - OPENING_ROWS, rows)):
			problems.append("Solid tiles block %s." % marker.name)
	for marker: Marker2D in chunk.get_exit_markers():
		if _blocked(chunk, marker.position.x, range(OPENING_ROWS)):
			problems.append("Solid tiles block %s." % marker.name)


static func _blocked(chunk: Chunk, x: float, rows: Array) -> bool:
	for row: int in rows:
		for column: int in opening_columns(x):
			if is_solid_at(chunk, Vector2i(column, row)):
				return true
	return false


static func _check_fork(chunk: Chunk, problems: PackedStringArray) -> void:
	var exits: Array[Marker2D] = chunk.get_exit_markers()
	if exits.size() != 2:
		problems.append("A fork needs exactly two exits.")
		return
	if Chunk.opening_at(exits[0].position.x) == Chunk.opening_at(exits[1].position.x):
		problems.append("The exits of a fork must be in different openings.")
	var open_columns: Array[int] = []
	for marker: Marker2D in exits:
		open_columns.append_array(opening_columns(marker.position.x))
	for column: int in range(Chunk.WALL_COLUMNS, Chunk.COLUMNS - Chunk.WALL_COLUMNS):
		if column not in open_columns and not is_solid(chunk.get_walls(), Vector2i(column, 0)):
			problems.append("A fork needs a closed ceiling (row 0) except at its exits.")
			return


static func _check_slots(chunk: Chunk, problems: PackedStringArray) -> void:
	var slots: Array[Node2D] = chunk.get_slot_nodes()
	for slot: Node2D in slots:
		if Chunk.slot_kind(slot.name).is_empty():
			problems.append("Unknown slot kind: %s (use <kind>_<n>)." % slot.name)
			continue
		var position: Vector2 = slot.position
		if (
			position.x <= Chunk.INNER_LEFT
			or position.x >= Chunk.INNER_RIGHT
			or position.y <= 0.0
			or position.y > chunk.get_height()
		):
			problems.append("%s is outside the chunk." % slot.name)
		# A point just above the slot: hazards stand on the surface of a platform
		elif is_solid_at(chunk, cell_at(position + Vector2.UP)):
			problems.append("%s is inside a solid tile." % slot.name)
	for i: int in slots.size():
		for j: int in range(i + 1, slots.size()):
			var radius_i: float = SLOT_RADIUS.get(Chunk.slot_kind(slots[i].name), 0.0)
			var radius_j: float = SLOT_RADIUS.get(Chunk.slot_kind(slots[j].name), 0.0)
			if slots[i].position.distance_to(slots[j].position) < radius_i + radius_j:
				problems.append("Slots %s and %s overlap." % [slots[i].name, slots[j].name])


static func _check_optional_parts(chunk: Chunk, problems: PackedStringArray) -> void:
	for layer: TileMapLayer in chunk.get_optional_layers():
		for cell: Vector2i in layer.get_used_cells():
			if is_solid(layer, cell):
				problems.append(
					(
						"%s has solid tiles: optional parts may only use one-way platforms."
						% layer.name
					)
				)
				break
			if (
				chunk.get_walls().get_cell_source_id(cell) != -1
				or chunk.get_platforms().get_cell_source_id(cell) != -1
			):
				problems.append("%s overlaps the required tiles (cell %s)." % [layer.name, cell])
				break
