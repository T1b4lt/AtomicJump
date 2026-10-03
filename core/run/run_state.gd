class_name RunState
extends RefCounted
## State of one run. RunManager creates a new one for every run, so starting
## over never needs a manual reset. The UI listens to its signals.

signal hp_changed(value: float, max_value: float)
signal coins_changed(value: int)
signal keys_changed(value: int)
signal altitude_changed(value: float)
## Distance (pm) from the player's feet down to the Decoherence.
signal threat_distance_changed(value: float)
signal died
## A fork's branch was chosen: its id ("K/1/L").
signal branch_chosen(branch: String)
## An observable or an operator was gained (the HUD shows its name).
signal item_gained(item: ItemData)

## Seed as shown to the player ("K7QX-2MPA" or a normalized text).
var seed_code: String
## Addressed rolls of this run's world, from the seed.
var world_rng: WorldRng
var character: CharacterData
var stats: Stats
var hp: float
## Current balance (spent in shops from Phase 7); totals live in counters.
var coins: int = 0
var keys: int = 0
## Highest altitude reached, in pm.
var altitude: float = 0.0
var threat_distance: float = INF
## Index of the layer being played in the level's list of layers.
var layer_index: int = 0
## Branches chosen at the forks, in order: ["K/1/L", "K/2/R"…].
var path: PackedStringArray = []
var counters := RunCounters.new()
## Items of the run (observables, operator, transformations) and their effects.
var build: Build
## Index in the level's column of the highest chunk entered so far.
var chunk_index: int = 0


## Takes the seed as typed by the player; see SeedCode.normalize(). Without a
## catalog the run has no transformations (tests).
func _init(p_seed_text: String, p_character: CharacterData, catalog: ItemCatalog = null) -> void:
	seed_code = SeedCode.from_text(p_seed_text)
	world_rng = WorldRng.new(SeedCode.to_int(p_seed_text))
	character = p_character
	stats = Stats.new(character.base_stats)
	hp = get_max_hp()
	stats.stat_changed.connect(_on_stat_changed)
	build = Build.new(self, catalog)


## Seed with its generation version, as shown in the HUD: "K7QX-2MPA · g1".
func get_seed_label() -> String:
	return "%s · %s" % [seed_code, WorldRng.version_label()]


func get_max_hp() -> float:
	return stats.get_value(Stats.MAX_HP)


func is_dead() -> bool:
	return hp <= 0.0


## Applies damage, reduced by defense unless `reducible` is false (the
## Decoherence). `source_id` (an enemy, &"spike"…) is the cause of death if it
## kills. Returns the damage actually taken.
func take_damage(amount: float, reducible: bool = true, source_id: StringName = &"") -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	if reducible:
		amount *= 1.0 - stats.get_value(Stats.DEFENSE)
	var final_damage: float = minf(hp, amount)
	hp -= final_damage
	hp_changed.emit(hp, get_max_hp())
	if is_dead():
		counters.death_cause = source_id
		died.emit()
	return final_damage


func heal(amount: float) -> void:
	if is_dead() or amount <= 0.0:
		return
	hp = minf(get_max_hp(), hp + amount)
	hp_changed.emit(hp, get_max_hp())


func is_hp_full() -> bool:
	return hp >= get_max_hp()


func add_coins(amount: int) -> void:
	coins += amount
	counters.coins_collected += amount
	coins_changed.emit(coins)
	build.on_coins_collected(amount)


func add_keys(amount: int) -> void:
	keys += amount
	counters.keys_collected += amount
	keys_changed.emit(keys)


## Pays photons if there are enough. Returns whether they were paid.
func spend_coins(amount: int) -> bool:
	if amount < 0 or coins < amount:
		return false
	coins -= amount
	counters.coins_spent += amount
	coins_changed.emit(coins)
	return true


## Uses positrons if there are enough. Returns whether they were used.
func spend_keys(amount: int = 1) -> bool:
	if amount < 0 or keys < amount:
		return false
	keys -= amount
	keys_changed.emit(keys)
	return true


## Gains an item (see Build.add_item()) and counts it. Returns the operator it
## replaced, if any.
func add_item(item: ItemData) -> ItemData:
	counters.items_collected += 1
	var replaced: ItemData = build.add_item(item)
	item_gained.emit(item)
	return replaced


## The player reached the chunk at `index` of the column: a new one recharges
## the operator and wakes the effects that act per chunk.
func enter_chunk(index: int) -> void:
	if index <= chunk_index:
		return
	for entered: int in range(chunk_index + 1, index + 1):
		build.on_chunk_entered(entered)
	chunk_index = index


func register_jump() -> void:
	counters.jumps += 1


## An enemy was killed (its EnemyData id).
func register_kill(enemy_id: StringName) -> void:
	counters.enemies_killed += 1
	counters.kills_by_enemy[enemy_id] = counters.kills_by_enemy.get(enemy_id, 0) + 1


func choose_branch(branch: String) -> void:
	path.append(branch)
	branch_chosen.emit(branch)


## Sides chosen at the forks of a layer, in order (["L", "R"…]).
func get_choices(layer_code: String) -> PackedStringArray:
	var choices: PackedStringArray = []
	for branch: String in path:
		var parts: PackedStringArray = branch.split("/")
		if parts.size() == 3 and parts[0] == layer_code:
			choices.append(parts[2])
	return choices


func set_altitude(value: float) -> void:
	if is_equal_approx(value, altitude):
		return
	altitude = value
	altitude_changed.emit(altitude)


func set_threat_distance(value: float) -> void:
	if is_equal_approx(value, threat_distance):
		return
	threat_distance = value
	threat_distance_changed.emit(threat_distance)


func _on_stat_changed(stat: StringName, value: float) -> void:
	if stat == Stats.MAX_HP:
		hp = minf(hp, value)
		hp_changed.emit(hp, value)
