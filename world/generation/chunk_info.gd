class_name ChunkInfo
extends RefCounted
## What the generator needs to know about a chunk scene, read once by
## ChunkLibrary: its metadata and what its markers and nodes declare.

var id: StringName
var scene: PackedScene
var data: ChunkData
## Openings (Chunk.Opening flags) of its entries and exits, unmirrored.
var entries: int = 0
var exits: int = 0
## Opening of each exit, left to right (a fork's left branch first).
var exit_openings: Array[int] = []
## Spawn slots as {name: kind}.
var slots: Dictionary[StringName, StringName] = {}
var optional_parts: Array[StringName] = []


static func from_scene(scene: PackedScene) -> ChunkInfo:
	var chunk: Chunk = scene.instantiate() as Chunk
	assert(chunk != null and chunk.data != null, "Not a chunk scene: %s" % scene.resource_path)
	var info := ChunkInfo.new()
	info.scene = scene
	info.data = chunk.data
	info.id = chunk.data.id
	info.entries = read_openings(chunk.get_entry_markers())
	info.exits = read_openings(chunk.get_exit_markers())
	for marker: Marker2D in chunk.get_exit_markers():
		info.exit_openings.append(Chunk.opening_at(marker.position.x))
	info.slots = read_slots(chunk)
	info.optional_parts = read_optional_parts(chunk)
	chunk.free()
	return info


## Openings (set of Chunk.Opening flags) of some entry or exit markers.
static func read_openings(markers: Array[Marker2D]) -> int:
	var openings: int = 0
	for marker: Marker2D in markers:
		openings |= Chunk.opening_at(marker.position.x)
	return openings


## Spawn slots of a chunk as {name: kind}, sorted by name. Nodes with an
## unknown kind are left out (the validator reports them).
static func read_slots(chunk: Chunk) -> Dictionary[StringName, StringName]:
	var names: Array[StringName] = []
	for node: Node2D in chunk.get_slot_nodes():
		if not Chunk.slot_kind(node.name).is_empty():
			names.append(node.name)
	names.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	var slots: Dictionary[StringName, StringName] = {}
	for slot_name: StringName in names:
		slots[slot_name] = Chunk.slot_kind(slot_name)
	return slots


## Names of a chunk's optional parts, sorted (their order never matters).
static func read_optional_parts(chunk: Chunk) -> Array[StringName]:
	var names: Array[StringName] = []
	for layer: TileMapLayer in chunk.get_optional_layers():
		names.append(layer.name)
	names.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return names


## Entry openings, mirrored or not.
func get_entries(mirrored: bool) -> int:
	return Chunk.mirror_openings(entries) if mirrored else entries


func get_exits(mirrored: bool) -> int:
	return Chunk.mirror_openings(exits) if mirrored else exits


## Exit openings left to right as placed: mirroring swaps the order and the sides.
func get_exit_openings(mirrored: bool) -> Array[int]:
	if not mirrored:
		return exit_openings.duplicate()
	var openings: Array[int] = []
	for i: int in range(exit_openings.size() - 1, -1, -1):
		openings.append(Chunk.mirror_openings(exit_openings[i]))
	return openings
