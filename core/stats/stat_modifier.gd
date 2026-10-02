class_name StatModifier
extends Resource
## A change to one statistic, tagged with the source that applies it (an item, an
## upgrade...) so it can be removed later and shown in the build breakdown.

enum Type { ADD, MULT }

## Statistic it modifies (one of Stats.ALL).
@export var stat: StringName
@export var type: Type = Type.ADD
## ADD: added to the base. MULT: fraction applied as (1 + value), so 0.25 is +25 %.
@export var value: float = 0.0
## Id of what applies the modifier (item, boon, upgrade...).
@export var source: StringName


static func create(
	p_stat: StringName, p_type: Type, p_value: float, p_source: StringName
) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat = p_stat
	modifier.type = p_type
	modifier.value = p_value
	modifier.source = p_source
	return modifier
