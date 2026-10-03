class_name HealthComponent
extends Node
## Health of anything that can be destroyed except the player, whose coherence
## lives in the RunState (docs/12-architecture.md#combate). A Hurtbox passes it
## the hits; after one it can stay invulnerable for a while.

signal hp_changed(value: float, max_value: float)
## A hit was applied: `amount` is the hp actually lost.
signal damaged(info: DamageInfo, amount: float)
signal died(info: DamageInfo)

@export var max_hp: float = 10.0
## Seconds without taking damage after a hit (0: every hit counts).
@export var invulnerability_time: float = 0.0

var hp: float = 0.0
var invulnerability_left: float = 0.0


func _ready() -> void:
	if hp <= 0.0:
		hp = max_hp
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	if invulnerability_left == 0.0:
		set_physics_process(false)


## Sets the maximum and fills the health.
func setup(p_max_hp: float) -> void:
	max_hp = p_max_hp
	hp = max_hp
	hp_changed.emit(hp, max_hp)


func is_dead() -> bool:
	return hp <= 0.0


func is_invulnerable() -> bool:
	return invulnerability_left > 0.0


## Applies a hit unless dead or invulnerable (status ticks ignore the
## invulnerability and never start it). Returns whether it was applied.
func take_hit(info: DamageInfo) -> bool:
	if is_dead() or (is_invulnerable() and not info.ignores_invulnerability):
		return false
	var lost: float = clampf(info.amount, 0.0, hp)
	hp -= lost
	if invulnerability_time > 0.0 and not info.ignores_invulnerability:
		invulnerability_left = invulnerability_time
		set_physics_process(true)
	hp_changed.emit(hp, max_hp)
	damaged.emit(info, lost)
	if is_dead():
		died.emit(info)
	return true


func heal(amount: float) -> void:
	if is_dead() or amount <= 0.0:
		return
	hp = minf(max_hp, hp + amount)
	hp_changed.emit(hp, max_hp)
