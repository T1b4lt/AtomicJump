class_name StatusEffectData
extends Resource
## An altered state that a hit leaves on an enemy (docs/02-universe.md, "Estados
## alterados"): how long it lasts, how it stacks and what it does while active
## (damage over time, slowing, rooting). StatusEffects keeps the active ones.
## The data lives in data/statuses/; the effects with their own rules (charged,
## linked) will build on this.

## Ids of the altered states (the code names of the glossary).
const DECAY: StringName = &"status_decay"
const SLOW: StringName = &"status_slow"
const ROOT: StringName = &"status_root"
const CHARGED: StringName = &"status_charged"
const LINKED: StringName = &"status_linked"

@export var id: StringName = &""
@export var name_key: String = ""
## Seconds it lasts; applying it again refreshes the time.
@export var duration: float = 3.0
## Stacks it can accumulate (each new application adds one).
@export var max_stacks: int = 1
## Damage per stack every `tick_interval` seconds (0: no damage over time).
@export var damage_per_tick: float = 0.0
@export var tick_interval: float = 0.5
## Multiplier of the target's speed and timers while active (1: unchanged).
@export_range(0.0, 1.0) var speed_multiplier: float = 1.0
## Whether the target cannot move while active.
@export var immobilizes: bool = false
