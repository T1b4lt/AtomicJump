class_name Stats
extends RefCounted
## Final statistics of a character: base values plus modifiers, cached.
##
## final = (base + Σ adds) × Π (1 + mults), clamped to the stat limits.
## See docs/04-player.md#cómo-se-calculan-las-estadísticas.

signal stat_changed(stat: StringName, value: float)

const MAX_HP: StringName = &"max_hp"
const LUCK: StringName = &"luck"
const SPEED: StringName = &"speed"
const JUMP_FORCE: StringName = &"jump_force"
const MAX_JUMPS: StringName = &"max_jumps"
const SIZE: StringName = &"size"
const ATTACK_POWER: StringName = &"attack_power"
const ATTACK_RATE: StringName = &"attack_rate"
const ATTACK_RANGE: StringName = &"attack_range"
const DEFENSE: StringName = &"defense"

const ALL: Array[StringName] = [
	MAX_HP,
	LUCK,
	SPEED,
	JUMP_FORCE,
	MAX_JUMPS,
	SIZE,
	ATTACK_POWER,
	ATTACK_RATE,
	ATTACK_RANGE,
	DEFENSE
]

## Limits of each stat (docs/04-player.md). INF means no upper limit.
const MIN_VALUES: Dictionary[StringName, float] = {
	MAX_HP: 1.0,
	LUCK: 0.0,
	SPEED: 0.0,
	JUMP_FORCE: 0.0,
	MAX_JUMPS: 1.0,
	SIZE: 0.6,
	ATTACK_POWER: 0.0,
	ATTACK_RATE: 0.0,
	ATTACK_RANGE: 0.0,
	DEFENSE: 0.0,
}
const MAX_VALUES: Dictionary[StringName, float] = {
	MAX_HP: 400.0,
	LUCK: 100.0,
	SPEED: 550.0,
	JUMP_FORCE: 750.0,
	MAX_JUMPS: 5.0,
	SIZE: 1.4,
	ATTACK_POWER: INF,
	ATTACK_RATE: 10.0,
	ATTACK_RANGE: 1200.0,
	DEFENSE: 0.6,
}

var _base: StatBlock
var _modifiers: Array[StatModifier] = []
var _cache: Dictionary[StringName, float] = {}


func _init(base: StatBlock) -> void:
	_base = base


func get_value(stat: StringName) -> float:
	if not _cache.has(stat):
		_cache[stat] = _compute(stat)
	return _cache[stat]


## For stats that count things (max_jumps).
func get_int(stat: StringName) -> int:
	return roundi(get_value(stat))


func get_base(stat: StringName) -> float:
	return _base.get_base(stat)


func add_modifier(modifier: StatModifier) -> void:
	assert(modifier.stat in ALL, "Unknown stat: %s" % modifier.stat)
	var old_value: float = get_value(modifier.stat)
	_modifiers.append(modifier)
	_refresh(modifier.stat, old_value)


func remove_modifier(modifier: StatModifier) -> void:
	if modifier not in _modifiers:
		return
	var old_value: float = get_value(modifier.stat)
	_modifiers.erase(modifier)
	_refresh(modifier.stat, old_value)


## Removes every modifier applied by a source. Returns how many were removed.
func remove_modifiers_from(source: StringName) -> int:
	var old_values: Dictionary[StringName, float] = {}
	var kept: Array[StatModifier] = []
	for modifier: StatModifier in _modifiers:
		if modifier.source == source:
			old_values[modifier.stat] = get_value(modifier.stat)
		else:
			kept.append(modifier)
	var removed: int = _modifiers.size() - kept.size()
	_modifiers = kept
	for stat: StringName in old_values:
		_refresh(stat, old_values[stat])
	return removed


## Modifiers of one stat, for the build breakdown.
func get_modifiers(stat: StringName) -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	for modifier: StatModifier in _modifiers:
		if modifier.stat == stat:
			result.append(modifier)
	return result


## Recomputes a stat after its modifiers change and notifies if the value moved.
func _refresh(stat: StringName, old_value: float) -> void:
	_cache.erase(stat)
	var new_value: float = get_value(stat)
	if not is_equal_approx(old_value, new_value):
		stat_changed.emit(stat, new_value)


func _compute(stat: StringName) -> float:
	var added: float = 0.0
	var multiplier: float = 1.0
	for modifier: StatModifier in _modifiers:
		if modifier.stat != stat:
			continue
		match modifier.type:
			StatModifier.Type.ADD:
				added += modifier.value
			StatModifier.Type.MULT:
				multiplier *= 1.0 + modifier.value
	var value: float = (_base.get_base(stat) + added) * multiplier
	return clampf(value, MIN_VALUES[stat], MAX_VALUES[stat])
