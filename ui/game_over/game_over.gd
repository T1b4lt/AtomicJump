class_name GameOver
extends CanvasLayer
## End-of-run screen. Shows the RunState passed by SceneRouter as "run".

@onready var _seed_label: Label = %SeedLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _jumps_label: Label = %JumpsLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _keys_label: Label = %KeysLabel


func _ready() -> void:
	var param: Variant = SceneRouter.get_param("run")
	if param is RunState:
		var run: RunState = param
		show_run(run)


func show_run(run: RunState) -> void:
	_seed_label.text = tr("GAME_OVER_SEED") % run.seed_value
	_score_label.text = tr("GAME_OVER_SCORE") % ("%.2f" % run.altitude)
	_jumps_label.text = tr("GAME_OVER_JUMPS") % run.counters.jumps
	_coins_label.text = tr("GAME_OVER_COINS") % run.counters.coins_collected
	_keys_label.text = tr("GAME_OVER_KEYS") % run.counters.keys_collected


func _on_menu_button_pressed() -> void:
	SceneRouter.go_to(SceneRouter.MAIN_MENU)
