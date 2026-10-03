class_name Hud
extends CanvasLayer
## In-run HUD. Listens to the RunState given in bind_run(): nothing is refreshed
## every frame.

## Label font sizes: names of the values and the values themselves.
const NAME_FONT_SIZE: int = 15
const VALUE_FONT_SIZE: int = 20
const OUTLINE_SIZE: int = 5
## Translation key of each stat name: STAT_ + the stat id in capitals.
const STAT_KEY_PREFIX: String = "STAT_"

## Distance (pm) to the Decoherence under which the bottom edge starts to glow.
@export var threat_warning_distance: float = 8.0

var _run: RunState = null
var _stat_labels: Dictionary[StringName, Label] = {}

@onready var _altitude_value: Label = %AltitudeValue
@onready var _coins_value: Label = %CoinsValue
@onready var _keys_value: Label = %KeysValue
@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _seed_value: Label = %SeedValue
@onready var _threat_value: Label = %ThreatValue
@onready var _threat_glow: TextureRect = %ThreatGlow


## Formats a stat value for display.
static func format_stat(stat: StringName, value: float) -> String:
	match stat:
		Stats.MAX_JUMPS:
			return str(roundi(value))
		Stats.LUCK:
			return "%.2f %%" % value
		Stats.DEFENSE:
			return "%.0f %%" % (value * 100.0)
		_:
			return "%.2f" % value


## How strong the Decoherence warning is (0 far, 1 touching) for a distance.
static func threat_danger(distance: float, warning_distance: float) -> float:
	if warning_distance <= 0.0:
		return 0.0
	return 1.0 - clampf(distance / warning_distance, 0.0, 1.0)


func _ready() -> void:
	for stat: StringName in Stats.ALL:
		_stats_grid.add_child(
			_make_label(STAT_KEY_PREFIX + String(stat).to_upper(), NAME_FONT_SIZE)
		)
		var value_label: Label = _make_label("", VALUE_FONT_SIZE)
		value_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_stats_grid.add_child(value_label)
		_stat_labels[stat] = value_label


func bind_run(run: RunState) -> void:
	if _run != null:
		_run.coins_changed.disconnect(_on_coins_changed)
		_run.keys_changed.disconnect(_on_keys_changed)
		_run.altitude_changed.disconnect(_on_altitude_changed)
		_run.threat_distance_changed.disconnect(_on_threat_distance_changed)
		_run.stats.stat_changed.disconnect(_on_stat_changed)
	_run = run
	_run.coins_changed.connect(_on_coins_changed)
	_run.keys_changed.connect(_on_keys_changed)
	_run.altitude_changed.connect(_on_altitude_changed)
	_run.threat_distance_changed.connect(_on_threat_distance_changed)
	_run.stats.stat_changed.connect(_on_stat_changed)

	_seed_value.text = run.get_seed_label()
	_on_coins_changed(run.coins)
	_on_keys_changed(run.keys)
	_on_altitude_changed(run.altitude)
	_on_threat_distance_changed(run.threat_distance)
	for stat: StringName in Stats.ALL:
		_on_stat_changed(stat, run.stats.get_value(stat))


func get_stat_text(stat: StringName) -> String:
	return _stat_labels[stat].text


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	label.add_theme_constant_override(&"outline_size", OUTLINE_SIZE)
	label.add_theme_font_size_override(&"font_size", font_size)
	return label


func _on_coins_changed(value: int) -> void:
	_coins_value.text = str(value)


func _on_keys_changed(value: int) -> void:
	_keys_value.text = str(value)


func _on_altitude_changed(value: float) -> void:
	_altitude_value.text = "%.2f" % value


func _on_threat_distance_changed(value: float) -> void:
	_threat_value.text = "%.1f" % value if is_finite(value) else "-"
	_threat_glow.modulate.a = threat_danger(value, threat_warning_distance)


func _on_stat_changed(stat: StringName, value: float) -> void:
	_stat_labels[stat].text = format_stat(stat, value)
