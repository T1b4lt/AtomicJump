class_name ChunkLibrary
extends RefCounted
## Index of the chunks of the layers by layer, type and difficulty
## (docs/05-world.md). Each scene is instantiated once to read its markers.

var _by_id: Dictionary[StringName, ChunkInfo] = {}
## Layer code -> its chunks.
var _by_layer: Dictionary[String, Array] = {}


static func from_layers(layers: Array[LayerData]) -> ChunkLibrary:
	var library := ChunkLibrary.new()
	for layer: LayerData in layers:
		for scene: PackedScene in layer.chunks:
			library.add(layer.code, scene)
	return library


## Adds a chunk scene to a layer. A chunk can be in several layers.
func add(layer_code: String, scene: PackedScene) -> ChunkInfo:
	var info: ChunkInfo = null
	for known: ChunkInfo in _by_id.values():
		if known.scene == scene:
			info = known
	if info == null:
		info = ChunkInfo.from_scene(scene)
		assert(not _by_id.has(info.id), "Repeated chunk id: %s" % info.id)
		_by_id[info.id] = info
	if not _by_layer.has(layer_code):
		_by_layer[layer_code] = []
	if info not in _by_layer[layer_code]:
		_by_layer[layer_code].append(info)
	return info


func has(id: StringName) -> bool:
	return _by_id.has(id)


func get_info(id: StringName) -> ChunkInfo:
	return _by_id.get(id)


func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_by_id.keys())
	return ids


## Chunks of a layer and a type, optionally limited to a difficulty range.
func get_chunks(
	layer_code: String,
	type: ChunkData.Type,
	min_difficulty: int = ChunkData.MIN_DIFFICULTY,
	max_difficulty: int = ChunkData.MAX_DIFFICULTY
) -> Array[ChunkInfo]:
	var found: Array[ChunkInfo] = []
	var layer_chunks: Array = _by_layer.get(layer_code, [])
	for info: ChunkInfo in layer_chunks:
		if (
			info.data.type == type
			and info.data.difficulty >= min_difficulty
			and info.data.difficulty <= max_difficulty
		):
			found.append(info)
	return found
