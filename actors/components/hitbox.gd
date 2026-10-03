class_name Hitbox
extends Area2D
## Area that deals damage to the Hurtboxes it touches (docs/12-architecture.md#combate):
## its mask holds the layers of its targets (`player` for enemies and hazards,
## `enemies` for the player's projectiles). With `continuous` it keeps hitting
## while the contact lasts, so the target's invulnerability sets the rate;
## otherwise it hits each Hurtbox once. `max_hits` limits how many it hits.

## A hit was accepted by a Hurtbox.
signal hit_landed(hurtbox: Hurtbox, info: DamageInfo)

@export var damage: float = 10.0
@export var kind: DamageInfo.Kind = DamageInfo.Kind.CONTACT
## Cause of death if this kills the player (an EnemyData id, &"spike"…).
@export var source_id: StringName = &""
## Knockback speed (px/s) given to the target.
@export var knockback: float = 0.0
## Keep hitting the Hurtboxes that stay in contact.
@export var continuous: bool = true
## Hits accepted before the hitbox stops (-1: no limit).
@export var max_hits: int = -1

## Status effects every hit applies.
var statuses: Array[StatusEffectData] = []
## Hits accepted so far.
var hits: int = 0
var _touching: Array[Hurtbox] = []
var _already_hit: Array[Hurtbox] = []


func _ready() -> void:
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	for hurtbox: Hurtbox in _touching.duplicate():
		if is_instance_valid(hurtbox):
			hit(hurtbox)
		else:
			_touching.erase(hurtbox)
	if _touching.is_empty():
		set_physics_process(false)


## The DamageInfo of one hit from this hitbox.
func make_damage() -> DamageInfo:
	var info := DamageInfo.create(damage, kind, source_id, global_position)
	info.knockback = knockback
	info.statuses = statuses.duplicate()
	return info


## Hits a Hurtbox now. Returns whether the hit was accepted.
func hit(hurtbox: Hurtbox) -> bool:
	if is_spent() or (not continuous and hurtbox in _already_hit):
		return false
	var info: DamageInfo = make_damage()
	if not hurtbox.receive(info):
		return false
	hits += 1
	if not continuous:
		_already_hit.append(hurtbox)
	hit_landed.emit(hurtbox, info)
	return true


## Whether it already hit `max_hits` times.
func is_spent() -> bool:
	return max_hits >= 0 and hits >= max_hits


## Stops (or resumes) detecting Hurtboxes. Safe to call during physics callbacks.
func set_enabled(enabled: bool) -> void:
	set_deferred(&"monitoring", enabled)
	if not enabled:
		_touching.clear()
		set_physics_process(false)


func _on_area_entered(area: Area2D) -> void:
	var hurtbox: Hurtbox = area as Hurtbox
	if hurtbox == null:
		return
	hit(hurtbox)
	if continuous and hurtbox not in _touching:
		_touching.append(hurtbox)
		set_physics_process(true)


func _on_area_exited(area: Area2D) -> void:
	var hurtbox: Hurtbox = area as Hurtbox
	if hurtbox != null:
		_touching.erase(hurtbox)
