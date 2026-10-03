class_name RunCounters
extends RefCounted
## Totals of the run in progress, for the end-of-run screen.

## Translation key prefix of a cause of death: CAUSE_ + the id in capitals.
const CAUSE_KEY_PREFIX: String = "CAUSE_"

var jumps: int = 0
var coins_collected: int = 0
var keys_collected: int = 0
var coins_spent: int = 0
## Observables and operators gained.
var items_collected: int = 0
var enemies_killed: int = 0
## Kills of each enemy type, by EnemyData id.
var kills_by_enemy: Dictionary[StringName, int] = {}
## What dealt the killing blow (an EnemyData id, &"spike", &"rising_threat"…),
## or &"" while alive.
var death_cause: StringName = &""


## Translation key of a cause of death (&"orbital_electron" → "CAUSE_ORBITAL_ELECTRON").
static func cause_key(cause: StringName) -> String:
	return CAUSE_KEY_PREFIX + String(cause).to_upper()
