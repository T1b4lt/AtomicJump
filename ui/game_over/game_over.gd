class_name GameOver
extends CanvasLayer
## End-of-run screen. Shows the RunState passed by SceneRouter as "run" (its
## counters, enemies killed and cause of death), with a button that copies its
## seed. With "completed" (the top of the layer was
## reached) the title says so instead of the Decoherence.

const COMPLETED_TITLE: String = "GAME_OVER_TITLE_COMPLETED"

var _seed_code: String = ""

@onready var _title: Label = %Title
@onready var _seed_label: Label = %SeedLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _jumps_label: Label = %JumpsLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _keys_label: Label = %KeysLabel
@onready var _kills_label: Label = %KillsLabel
@onready var _cause_label: Label = %CauseLabel
@onready var _copy_seed_button: Button = %CopySeedButton


func _ready() -> void:
	var param: Variant = SceneRouter.get_param("run")
	if param is RunState:
		var run: RunState = param
		show_run(run)
	if SceneRouter.get_param("completed") == true:
		_title.text = COMPLETED_TITLE


func show_run(run: RunState) -> void:
	_seed_code = run.seed_code
	_copy_seed_button.disabled = false
	_seed_label.text = tr("GAME_OVER_SEED") % run.get_seed_label()
	_score_label.text = tr("GAME_OVER_SCORE") % ("%.2f" % run.altitude)
	_jumps_label.text = tr("GAME_OVER_JUMPS") % run.counters.jumps
	_coins_label.text = tr("GAME_OVER_COINS") % run.counters.coins_collected
	_keys_label.text = tr("GAME_OVER_KEYS") % run.counters.keys_collected
	_kills_label.text = tr("GAME_OVER_KILLS") % run.counters.enemies_killed
	var cause: StringName = run.counters.death_cause
	_cause_label.visible = not cause.is_empty()
	if not cause.is_empty():
		_cause_label.text = tr("GAME_OVER_CAUSE") % tr(RunCounters.cause_key(cause))


## Seed that the copy button puts in the clipboard ("" without a run).
func get_seed_code() -> String:
	return _seed_code


func _on_copy_seed_button_pressed() -> void:
	DisplayServer.clipboard_set(_seed_code)


func _on_menu_button_pressed() -> void:
	SceneRouter.go_to(SceneRouter.MAIN_MENU)
