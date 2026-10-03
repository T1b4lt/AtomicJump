class_name LayerGenerator
extends RefCounted
## Turns a LayerData into a LayerPlan with addressed rolls (docs/05-world.md and
## docs/08-seeds.md). Every position picks, among the chunks of its type:
## 1. the ones whose entry fits the previous exit (the branch ends also fit the
##    next main chunk, which follows whichever branch is chosen),
## 2. with a difficulty close to the position's,
## 3. used the fewest times in the layer and not equal to the previous one,
## and then one by weight with pick_weighted(). Whether the position is mirrored
## is rolled first, so it does not depend on the chunk picked. If no chunk fits,
## the conditions are relaxed in reverse order (it should never happen with a
## good library; the tests check it).

## Max distance between a chunk's difficulty and the position's.
const DIFFICULTY_TOLERANCE: int = 1
## Chance of mirroring a position (when its chunk allows it).
const MIRROR_CHANCE: float = 0.5

var _library: ChunkLibrary


func _init(library: ChunkLibrary) -> void:
	_library = library


## Whether the chunk of a position is mirrored (if it can be).
static func roll_mirror(rng: WorldRng, key: Array) -> bool:
	return rng.chance(MIRROR_CHANCE, &"layout", key + ["mirror"])


## Optional parts that appear in the chunk at the address `key`.
static func pick_optional_parts(
	rng: WorldRng, key: Array, parts: Array[StringName], chance: float
) -> Array[StringName]:
	var enabled: Array[StringName] = []
	for part: StringName in parts:
		if rng.chance(chance, &"layout", key + ["optional", part]):
			enabled.append(part)
	return enabled


## Rewards of the two branches of a fork, left first; never the same one twice.
static func pick_fork_rewards(rng: WorldRng, layer: LayerData, fork: int) -> Array[StringName]:
	var picked: Array[StringName] = []
	var pool: Dictionary[StringName, float] = layer.fork_rewards.duplicate()
	for side: String in LayerPlan.SIDES:
		var reward: StringName = rng.pick_weighted(pool, &"fork_reward", [layer.code, fork, side])
		picked.append(reward)
		if pool.size() > 1:
			pool.erase(reward)
	return picked


func generate(layer: LayerData, rng: WorldRng) -> LayerPlan:
	var plan := LayerPlan.new()
	plan.layer = layer
	var usage: Dictionary[StringName, int] = {}
	# Main path. After a fork the previous chunk is the end of a branch, which
	# adapts to this one, so there is nothing to fit
	var fork: int = 0
	for index: int in layer.template.size():
		var placement := ChunkPlacement.create(
			layer.code, LayerPlan.MAIN_BRANCH, index, layer.template[index]
		)
		var previous: ChunkPlacement = plan.main.back() if index > 0 else null
		var after: int = Chunk.ALL_OPENINGS
		if previous != null and previous.type != ChunkData.Type.FORK:
			after = _exits_of(previous)
		var previous_id: StringName = previous.chunk_id if previous != null else &""
		_pick(
			placement,
			rng,
			[after, Chunk.ALL_OPENINGS],
			layer.difficulty_at(index),
			previous_id,
			usage
		)
		if placement.type == ChunkData.Type.FORK:
			fork += 1
			placement.fork = fork
		plan.main.append(placement)
	# Branches of each fork
	for index: int in plan.main.size():
		var fork_placement: ChunkPlacement = plan.main[index]
		if fork_placement.type != ChunkData.Type.FORK:
			continue
		var fork_rewards: Array[StringName] = pick_fork_rewards(rng, layer, fork_placement.fork)
		var exit_openings: Array[int] = (
			_library.get_info(fork_placement.chunk_id).get_exit_openings(fork_placement.mirrored)
		)
		var next_entries: int = Chunk.ALL_OPENINGS
		if index + 1 < plan.main.size():
			next_entries = _entries_of(plan.main[index + 1])
		for side_index: int in LayerPlan.SIDES.size():
			var branch: String = LayerPlan.branch_id(
				fork_placement.fork, LayerPlan.SIDES[side_index]
			)
			var start: int = (
				exit_openings[side_index]
				if side_index < exit_openings.size()
				else Chunk.ALL_OPENINGS
			)
			plan.branches[branch] = _branch(
				layer,
				rng,
				fork_placement,
				LayerPlan.SIDES[side_index],
				[start, next_entries],
				layer.difficulty_at(index),
				usage
			)
			plan.rewards[branch] = fork_rewards[side_index]
			var branch_chunks: Array = plan.branches[branch]
			var reward_chunk: ChunkPlacement = branch_chunks.back()
			reward_chunk.reward = fork_rewards[side_index]
	return plan


## Chunks of one branch of a fork: normal ones and a reward chunk. `ends` are
## the openings of the fork's exit for this side and of the next main entry.
func _branch(
	layer: LayerData,
	rng: WorldRng,
	fork_placement: ChunkPlacement,
	side: String,
	ends: Array[int],
	difficulty: int,
	usage: Dictionary[StringName, int]
) -> Array[ChunkPlacement]:
	var branch: String = LayerPlan.branch_id(fork_placement.fork, side)
	var length: int = rng.roll_range(
		layer.branch_length.x, layer.branch_length.y, &"layout", [layer.code, branch, "length"]
	)
	var chunks: Array[ChunkPlacement] = []
	var previous: ChunkPlacement = fork_placement
	var after: int = ends[0]
	for index: int in length + 1:
		var is_reward: bool = index == length
		var type: ChunkData.Type = ChunkData.Type.REWARD if is_reward else ChunkData.Type.NORMAL
		var placement := ChunkPlacement.create(layer.code, branch, index, type)
		var before: int = ends[1] if is_reward else Chunk.ALL_OPENINGS
		_pick(placement, rng, [after, before], difficulty, previous.chunk_id, usage)
		after = _exits_of(placement)
		previous = placement
		chunks.append(placement)
	return chunks


## Picks the chunk of a placement. `fits`: openings its entry must touch (the
## previous exit) and openings its exit must touch (the next entry).
func _pick(
	placement: ChunkPlacement,
	rng: WorldRng,
	fits: Array[int],
	difficulty: int,
	previous_id: StringName,
	usage: Dictionary[StringName, int]
) -> void:
	var key: Array = placement.key()
	var mirror_roll: bool = roll_mirror(rng, key)
	var all: Array[ChunkInfo] = _library.get_chunks(placement.layer, placement.type)
	assert(
		not all.is_empty(), "No chunks of type %s in layer %s" % [placement.type, placement.layer]
	)
	var candidates: Array[ChunkInfo] = []
	for info: ChunkInfo in all:
		var mirrored: bool = mirror_roll and info.data.mirrorable
		if (
			_touches(info.get_entries(mirrored), fits[0])
			and _touches(info.get_exits(mirrored), fits[1])
		):
			candidates.append(info)
	if candidates.is_empty():
		push_warning("No chunk fits %s: compatibility ignored" % placement.label())
		candidates = all
	var close: Array[ChunkInfo] = []
	for info: ChunkInfo in candidates:
		if absi(info.data.difficulty - difficulty) <= DIFFICULTY_TOLERANCE:
			close.append(info)
	if not close.is_empty():
		candidates = close
	if candidates.size() > 1:
		candidates = candidates.filter(func(info: ChunkInfo) -> bool: return info.id != previous_id)
	candidates = _least_used(candidates, usage)
	var weights: Dictionary[StringName, float] = {}
	for info: ChunkInfo in candidates:
		weights[info.id] = info.data.weight
	placement.chunk_id = rng.pick_weighted(weights, &"layout", key)
	placement.mirrored = mirror_roll and _library.get_info(placement.chunk_id).data.mirrorable
	usage[placement.chunk_id] = usage.get(placement.chunk_id, 0) + 1


## Whether a set of openings touches the required ones (all of them: anything fits).
static func _touches(openings: int, required: int) -> bool:
	return required == Chunk.ALL_OPENINGS or openings & required != 0


## The candidates used the fewest times so far (no repeats while there are alternatives).
static func _least_used(
	candidates: Array[ChunkInfo], usage: Dictionary[StringName, int]
) -> Array[ChunkInfo]:
	var fewest: int = -1
	for info: ChunkInfo in candidates:
		var used: int = usage.get(info.id, 0)
		if fewest == -1 or used < fewest:
			fewest = used
	var least_used: Array[ChunkInfo] = []
	for info: ChunkInfo in candidates:
		if usage.get(info.id, 0) == fewest:
			least_used.append(info)
	return least_used


func _exits_of(placement: ChunkPlacement) -> int:
	return _library.get_info(placement.chunk_id).get_exits(placement.mirrored)


func _entries_of(placement: ChunkPlacement) -> int:
	return _library.get_info(placement.chunk_id).get_entries(placement.mirrored)
