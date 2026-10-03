class_name RestShrine
extends Node2D
## Ground State (Estado fundamental, `chunk_rest`; docs/06-economy.md#curación):
## like the fountains of Hades, the player picks one of two choices: heal
## HEAL_FRACTION of the max coherence, or gain MAX_HP_BONUS max coherence
## (which comes filled). Taking one collapses the other.

signal chosen(choice: StringName)

const HEAL: StringName = &"heal"
const MAX_HP: StringName = &"max_hp"
const HEAL_FRACTION: float = 0.4
const MAX_HP_BONUS: float = 10.0
## Source of the max coherence modifier (shown in the build breakdown).
const SOURCE: StringName = &"rest_max_hp"

var choice: StringName = &""

@onready var _heal_choice: RestChoice = %HealChoice
@onready var _max_hp_choice: RestChoice = %MaxHpChoice


func _ready() -> void:
	_heal_choice.chosen.connect(_on_choice_chosen)
	_max_hp_choice.chosen.connect(_on_choice_chosen)


## Applies a choice (HEAL or MAX_HP) to the player's run, once.
func choose(id: StringName, player: Player) -> bool:
	if not choice.is_empty() or player.run == null:
		return false
	var run: RunState = player.run
	match id:
		HEAL:
			run.heal(run.get_max_hp() * HEAL_FRACTION)
		MAX_HP:
			run.stats.add_modifier(
				StatModifier.create(Stats.MAX_HP, StatModifier.Type.ADD, MAX_HP_BONUS, SOURCE)
			)
			run.heal(MAX_HP_BONUS)
		_:
			return false
	choice = id
	_heal_choice.finish(id == HEAL)
	_max_hp_choice.finish(id == MAX_HP)
	chosen.emit(id)
	return true


func get_choice_node(id: StringName) -> RestChoice:
	return _heal_choice if id == HEAL else _max_hp_choice


func _on_choice_chosen(node: RestChoice, player: Player) -> void:
	choose(HEAL if node == _heal_choice else MAX_HP, player)
