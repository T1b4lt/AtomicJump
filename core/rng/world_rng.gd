class_name WorldRng
extends RefCounted
## Addressed world rolls (docs/08-seeds.md). Every random decision of the world
## has a stable address (a domain plus a key) and its result is a pure function
## of the seed and that address: the order of the rolls does not matter and
## nothing the player does shifts them.
##
## Keys are arrays of strings, string names and ints (never floats), for
## example roll(&"layout", ["K", "main", 2]).

## Bumped whenever a change alters what an existing seed generates (new chunks,
## spawn tables, item pools…). Shown next to the seed as "K7QX-2MPA · g1".
const GENERATION_VERSION: int = 2

var seed_value: int
## Seed mixed once, so close seeds give unrelated rolls.
var _seed_hash: int


func _init(p_seed: int) -> void:
	seed_value = p_seed
	_seed_hash = SeedHash.mix(p_seed)


## Text that tells which generation a seed belongs to ("g1").
static func version_label() -> String:
	return "g%d" % GENERATION_VERSION


## 64-bit hash of the address. Use it to seed a local RNG or as raw randomness.
func roll_int(domain: StringName, key: Array = []) -> int:
	return SeedHash.mix(_seed_hash ^ SeedHash.hash_parts([domain] + key))


## Float in [0, 1) for the address.
func roll(domain: StringName, key: Array = []) -> float:
	return SeedHash.to_unit_float(roll_int(domain, key))


## Integer in [from, to] (both included) for the address.
func roll_range(from: int, to: int, domain: StringName, key: Array = []) -> int:
	assert(from <= to, "Empty range")
	return from + mini(floori(roll(domain, key) * (to - from + 1)), to - from)


## Whether the address passes a probability check. The roll is fixed, so raising
## the probability only adds passes, never removes them (monotonic).
func chance(probability: float, domain: StringName, key: Array = []) -> bool:
	return roll(domain, key) < probability


## Picks one id from {id: weight} with rendezvous hashing: each candidate gets
## the score roll^(1/weight) for its own address and the highest one wins.
## Adding a candidate only changes the picks the new one wins, and the order of
## the dictionary does not matter. Weights <= 0 never win. Returns &"" if no
## candidate can win.
func pick_weighted(
	weights: Dictionary[StringName, float], domain: StringName, key: Array = []
) -> StringName:
	var best_id: StringName = &""
	var best_score: float = -INF
	for id: StringName in weights:
		var weight: float = weights[id]
		if weight <= 0.0:
			continue
		# log(roll^(1/w)) keeps the same order without underflow; 1 - roll is in (0, 1]
		var score: float = log(1.0 - roll(domain, key + [id])) / weight
		if score > best_score or (score == best_score and String(id) < String(best_id)):
			best_score = score
			best_id = id
	return best_id


## Disposable RNG for decisions that need a sequence (shuffles, picking several
## items without repeats). It is seeded from the address, so it is stable too.
func local_rng(domain: StringName, key: Array = []) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = roll_int(domain, key)
	return rng


## Shuffles a copy of the array with the address's local RNG (Fisher-Yates). The
## array's own shuffle() uses the global RNG and is not reproducible.
func shuffled(items: Array, domain: StringName, key: Array = []) -> Array:
	var result: Array = items.duplicate()
	var rng: RandomNumberGenerator = local_rng(domain, key)
	for i: int in range(result.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Variant = result[i]
		result[i] = result[j]
		result[j] = swap
	return result
