class_name Hurtbox
extends Area2D
## Area that receives hits from Hitboxes (docs/12-architecture.md#combate). It
## sits on its owner's physics layer (`player` or `enemies`) and detects
## nothing itself. It passes each hit to `health`, or to `handler` when the
## owner keeps its health elsewhere (the Player: its coherence is the run's).

## A hit was accepted.
signal hit_received(info: DamageInfo)

@export var health: HealthComponent = null

## func(info: DamageInfo) -> bool that applies a hit and says whether it was
## accepted. Takes precedence over `health`.
var handler: Callable = Callable()


func _ready() -> void:
	monitoring = false


## Applies a hit. Returns whether it was accepted (not dead nor invulnerable).
func receive(info: DamageInfo) -> bool:
	var accepted: bool = false
	if handler.is_valid():
		accepted = handler.call(info)
	elif health != null:
		accepted = health.take_hit(info)
	if accepted:
		hit_received.emit(info)
	return accepted


## Stops (or resumes) receiving hits. Safe to call during physics callbacks.
func set_enabled(enabled: bool) -> void:
	set_deferred(&"monitorable", enabled)
