extends Node
## Owns the run in progress (autoload `RunManager`). Creates a new RunState on
## every start and drops it when the run ends.

const DEFAULT_CHARACTER: CharacterData = preload("res://data/characters/wilas.tres")

## Run in progress, or null between runs.
var run: RunState = null


func _ready() -> void:
	Events.coin_collected.connect(_on_coin_collected)
	Events.key_collected.connect(_on_key_collected)


## Starts a run with the seed typed by the player. Without a usable seed (empty
## text) it starts a random one.
func start_run(seed_text: String = "", character: CharacterData = DEFAULT_CHARACTER) -> RunState:
	if not SeedCode.is_valid_text(seed_text):
		seed_text = SeedCode.generate()
	run = RunState.new(seed_text, character)
	Events.run_started.emit(run)
	return run


## Ends the run in progress and returns it, so the end screen can still read it.
func end_run() -> RunState:
	var ended: RunState = run
	run = null
	if ended != null:
		Events.run_ended.emit(ended)
	return ended


func has_run() -> bool:
	return run != null


func _on_coin_collected(amount: int) -> void:
	if has_run():
		run.add_coins(amount)


func _on_key_collected(amount: int) -> void:
	if has_run():
		run.add_keys(amount)
