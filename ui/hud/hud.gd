class_name Hud
extends CanvasLayer
## In-run HUD (docs/11-ui.md#hud-de-partida). Listens to the RunState given in
## bind_run(): nothing is refreshed every frame. Shows the altitude, photons
## and positrons, the operator with its charge, a banner with the name and
## description of every item gained, the seed and the Decoherence warning.
## The full stats are on the build screen (Tab).

## Seconds the item banner stays and fades.
const BANNER_TIME: float = 3.0
const BANNER_FADE_TIME: float = 0.4

## Distance (pm) to the Decoherence under which the bottom edge starts to glow.
@export var threat_warning_distance: float = 8.0

var _run: RunState = null
var _banner_tween: Tween = null

@onready var _altitude_value: Label = %AltitudeValue
@onready var _coins_value: Label = %CoinsValue
@onready var _keys_value: Label = %KeysValue
@onready var _seed_value: Label = %SeedValue
@onready var _threat_value: Label = %ThreatValue
@onready var _threat_glow: TextureRect = %ThreatGlow
@onready var _active_panel: Control = %ActivePanel
@onready var _active_icon: ItemIconRect = %ActiveIcon
@onready var _active_charge: ProgressBar = %ActiveCharge
@onready var _active_key: Label = %ActiveKey
@onready var _banner: Control = %ItemBanner
@onready var _banner_title: Label = %BannerTitle
@onready var _banner_text: Label = %BannerText


## How strong the Decoherence warning is (0 far, 1 touching) for a distance.
static func threat_danger(distance: float, warning_distance: float) -> float:
	if warning_distance <= 0.0:
		return 0.0
	return 1.0 - clampf(distance / warning_distance, 0.0, 1.0)


func _ready() -> void:
	_banner.modulate.a = 0.0
	_active_key.text = "[%s]" % InputHints.key_name(&"use_active")


func bind_run(run: RunState) -> void:
	if _run != null:
		_run.coins_changed.disconnect(_on_coins_changed)
		_run.keys_changed.disconnect(_on_keys_changed)
		_run.altitude_changed.disconnect(_on_altitude_changed)
		_run.threat_distance_changed.disconnect(_on_threat_distance_changed)
		_run.item_gained.disconnect(_on_item_gained)
		_run.build.active_item_changed.disconnect(_on_active_item_changed)
		_run.build.active_charge_changed.disconnect(_on_active_charge_changed)
		_run.build.transformation_gained.disconnect(_on_transformation_gained)
	_run = run
	_run.coins_changed.connect(_on_coins_changed)
	_run.keys_changed.connect(_on_keys_changed)
	_run.altitude_changed.connect(_on_altitude_changed)
	_run.threat_distance_changed.connect(_on_threat_distance_changed)
	_run.item_gained.connect(_on_item_gained)
	_run.build.active_item_changed.connect(_on_active_item_changed)
	_run.build.active_charge_changed.connect(_on_active_charge_changed)
	_run.build.transformation_gained.connect(_on_transformation_gained)

	_seed_value.text = run.get_seed_label()
	_on_coins_changed(run.coins)
	_on_keys_changed(run.keys)
	_on_altitude_changed(run.altitude)
	_on_threat_distance_changed(run.threat_distance)
	_on_active_item_changed(run.build.active_item)


func get_coins_text() -> String:
	return _coins_value.text


## Title of the item banner (what the last item gained was called).
func get_banner_title() -> String:
	return _banner_title.text


func is_active_shown() -> bool:
	return _active_panel.visible


## Shows a title and a text in the banner for a while.
func show_banner(title: String, text: String, color: Color = Palette.INK) -> void:
	_banner_title.text = title
	_banner_title.add_theme_color_override(&"font_color", color)
	_banner_text.text = text
	if _banner_tween != null:
		_banner_tween.kill()
	_banner.modulate.a = 1.0
	_banner_tween = create_tween()
	_banner_tween.tween_interval(BANNER_TIME)
	_banner_tween.tween_property(_banner, ^"modulate:a", 0.0, BANNER_FADE_TIME)


func _on_coins_changed(value: int) -> void:
	_coins_value.text = str(value)


func _on_keys_changed(value: int) -> void:
	_keys_value.text = str(value)


func _on_altitude_changed(value: float) -> void:
	_altitude_value.text = "%.2f" % value


func _on_threat_distance_changed(value: float) -> void:
	_threat_value.text = "%.1f" % value if is_finite(value) else "-"
	_threat_glow.modulate.a = threat_danger(value, threat_warning_distance)


func _on_item_gained(item: ItemData) -> void:
	show_banner(
		tr(item.get_name_key()), tr(item.get_description_key()), ItemRarity.get_color(item.rarity)
	)


func _on_transformation_gained(transformation: TransformationData) -> void:
	show_banner(
		tr(transformation.get_name_key()), tr(transformation.get_description_key()), Palette.PLAYER
	)


func _on_active_item_changed(item: ItemData) -> void:
	_active_panel.visible = item != null
	_active_icon.set_item(item)
	if item != null:
		_on_active_charge_changed(_run.build.active_charge, _run.build.get_max_charge())


func _on_active_charge_changed(charge: int, max_charge: int) -> void:
	_active_charge.max_value = maxi(max_charge, 1)
	_active_charge.value = charge
	_active_key.modulate.a = 1.0 if charge >= max_charge else 0.35
