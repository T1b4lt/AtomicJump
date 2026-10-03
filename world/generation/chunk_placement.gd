class_name ChunkPlacement
extends RefCounted
## One position of a LayerPlan: which chunk goes there, mirrored or not, and
## what a fork or a reward chunk needs. Its address key is
## [layer, branch, index], with branch "main" or "<fork>/<side>" ("2/L").

var layer: String = ""
var branch: String = ""
var index: int = 0
var chunk_id: StringName = &""
var type: ChunkData.Type = ChunkData.Type.NORMAL
var mirrored: bool = false
## Fork number in the layer (1, 2…), only in fork chunks.
var fork: int = 0
## Reward of the branch, only in its reward chunk (LayerData.REWARD_*).
var reward: StringName = &""


static func create(
	p_layer: String, p_branch: String, p_index: int, p_type: ChunkData.Type
) -> ChunkPlacement:
	var placement := ChunkPlacement.new()
	placement.layer = p_layer
	placement.branch = p_branch
	placement.index = p_index
	placement.type = p_type
	return placement


## Address key of the position for WorldRng.
func key() -> Array:
	return [layer, branch, index]


## "K/main/3" or "K/2/L/0", for debugging and the golden seeds.
func label() -> String:
	return "%s/%s/%d" % [layer, branch, index]
