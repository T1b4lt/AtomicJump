class_name LayerPlan
extends RefCounted
## The whole sequence of a layer, worked out when entering it
## (docs/05-world.md#generación-de-una-capa): the main path and both branches
## of every fork with their rewards. The column the player climbs depends on
## the sides chosen at the forks, so it is built with column().

const MAIN_BRANCH: String = "main"
const SIDES: PackedStringArray = ["L", "R"]

var layer: LayerData
var main: Array[ChunkPlacement] = []
## Branch id ("1/L") -> its chunks, the reward chunk last.
var branches: Dictionary[String, Array] = {}
## Branch id -> its reward.
var rewards: Dictionary[String, StringName] = {}


static func branch_id(fork: int, side: String) -> String:
	return "%d/%s" % [fork, side]


func get_fork_count() -> int:
	return main.filter(func(p: ChunkPlacement) -> bool: return p.type == ChunkData.Type.FORK).size()


## Rewards of a fork's branches, left first.
func get_fork_rewards(fork: int) -> Array[StringName]:
	var fork_rewards: Array[StringName] = []
	for side: String in SIDES:
		fork_rewards.append(rewards.get(branch_id(fork, side), &""))
	return fork_rewards


## Chunks of the column for the sides chosen so far (in fork order). It stops
## after the first fork without a choice: nothing above it exists yet.
func column(choices: PackedStringArray) -> Array[ChunkPlacement]:
	var result: Array[ChunkPlacement] = []
	for placement: ChunkPlacement in main:
		result.append(placement)
		if placement.type != ChunkData.Type.FORK:
			continue
		if placement.fork > choices.size():
			break
		var branch: Array = branches[branch_id(placement.fork, choices[placement.fork - 1])]
		for branch_placement: ChunkPlacement in branch:
			result.append(branch_placement)
	return result


## Whether the column reaches the end of the layer with these choices.
func is_complete(choices: PackedStringArray) -> bool:
	return choices.size() >= get_fork_count()
