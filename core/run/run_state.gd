class_name RunState
extends RefCounted
## State of one run. RunManager creates a new one for every run, so starting
## over never needs a manual reset. The UI listens to its signals.

signal hp_changed(value: float, max_value: float)
signal coins_changed(value: int)
signal keys_changed(value: int)
signal altitude_changed(value: float)
signal died

var seed_value: int
var character: CharacterData
var stats: Stats
var hp: float
## Current balance (spent in shops from Phase 7); totals live in counters.
var coins: int = 0
var keys: int = 0
var altitude: float = 0.0
var counters := RunCounters.new()


func _init(p_seed: int, p_character: CharacterData) -> void:
	seed_value = p_seed
	character = p_character
	stats = Stats.new(character.base_stats)
	hp = get_max_hp()
	stats.stat_changed.connect(_on_stat_changed)


func get_max_hp() -> float:
	return stats.get_value(Stats.MAX_HP)


func is_dead() -> bool:
	return hp <= 0.0


## Applies damage reduced by defense. Returns the damage actually taken.
func take_damage(amount: float) -> float:
	if is_dead() or amount <= 0.0:
		return 0.0
	var final_damage: float = minf(hp, amount * (1.0 - stats.get_value(Stats.DEFENSE)))
	hp -= final_damage
	hp_changed.emit(hp, get_max_hp())
	if is_dead():
		died.emit()
	return final_damage


func heal(amount: float) -> void:
	if is_dead() or amount <= 0.0:
		return
	hp = minf(get_max_hp(), hp + amount)
	hp_changed.emit(hp, get_max_hp())


func add_coins(amount: int) -> void:
	coins += amount
	counters.coins_collected += amount
	coins_changed.emit(coins)


func add_keys(amount: int) -> void:
	keys += amount
	counters.keys_collected += amount
	keys_changed.emit(keys)


func register_jump() -> void:
	counters.jumps += 1


func set_altitude(value: float) -> void:
	if is_equal_approx(value, altitude):
		return
	altitude = value
	altitude_changed.emit(altitude)


func _on_stat_changed(stat: StringName, value: float) -> void:
	if stat == Stats.MAX_HP:
		hp = minf(hp, value)
		hp_changed.emit(hp, value)
