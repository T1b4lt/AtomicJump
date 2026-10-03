class_name StatusEffects
extends Node
## Altered states active on an enemy (Inestable, Dilatado, Confinado…): their
## time left, their stacks and their effects. Damage over time goes to `health`
## as STATUS hits (no invulnerability, no knockback); the speed multiplier is
## read by the enemy every frame. See StatusEffectData.

signal status_applied(id: StringName, stacks: int)
signal status_removed(id: StringName)

## Tint of the target while a state is active (the first one applied wins).
const TINTS: Dictionary[StringName, Color] = {
	StatusEffectData.DECAY: Palette.FAMILY_WEAK,
	StatusEffectData.SLOW: Palette.FAMILY_GRAVITY,
	StatusEffectData.ROOT: Palette.FAMILY_STRONG,
	StatusEffectData.CHARGED: Palette.FAMILY_ELECTROMAGNETIC,
	StatusEffectData.LINKED: Palette.FAMILY_QUANTUM,
}

@export var health: HealthComponent = null

## Active states by id, in the order they were applied.
var _active: Dictionary[StringName, ActiveStatus] = {}


## One active state.
class ActiveStatus:
	extends RefCounted
	var data: StatusEffectData
	var stacks: int = 1
	var time_left: float = 0.0
	var tick_left: float = 0.0


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	tick(delta)


## Applies a state (or adds a stack and refreshes its time).
func apply(data: StatusEffectData) -> void:
	var status: ActiveStatus = _active.get(data.id)
	if status == null:
		status = ActiveStatus.new()
		status.data = data
		status.tick_left = data.tick_interval
		_active[data.id] = status
	else:
		status.stacks = mini(status.stacks + 1, data.max_stacks)
	status.time_left = data.duration
	set_physics_process(true)
	status_applied.emit(data.id, status.stacks)


func has(id: StringName) -> bool:
	return _active.has(id)


func get_stacks(id: StringName) -> int:
	var status: ActiveStatus = _active.get(id)
	return status.stacks if status != null else 0


## Multiplier of the target's speed and timers: the product of the active
## states' multipliers, or 0 while one immobilizes it.
func get_speed_multiplier() -> float:
	var multiplier: float = 1.0
	for status: ActiveStatus in _active.values():
		if status.data.immobilizes:
			return 0.0
		multiplier *= status.data.speed_multiplier
	return multiplier


## Tint of the first active state with one, or WHITE.
func get_tint() -> Color:
	for id: StringName in _active:
		if TINTS.has(id):
			return TINTS[id]
	return Color.WHITE


func clear() -> void:
	for id: StringName in _active.keys():
		_remove(id)


## Advances the states `delta` seconds: damage ticks and expiry.
func tick(delta: float) -> void:
	for id: StringName in _active.keys():
		var status: ActiveStatus = _active[id]
		if status.data.damage_per_tick > 0.0 and status.data.tick_interval > 0.0:
			status.tick_left -= delta
			while status.tick_left <= 0.0 and status.time_left > 0.0:
				status.tick_left += status.data.tick_interval
				_damage(status)
		status.time_left -= delta
		if status.time_left <= 0.0:
			_remove(id)
	if _active.is_empty():
		set_physics_process(false)


func _damage(status: ActiveStatus) -> void:
	if health == null or health.is_dead():
		return
	var info := DamageInfo.create(
		status.data.damage_per_tick * status.stacks, DamageInfo.Kind.STATUS, status.data.id
	)
	info.ignores_invulnerability = true
	health.take_hit(info)


func _remove(id: StringName) -> void:
	if _active.erase(id):
		status_removed.emit(id)
