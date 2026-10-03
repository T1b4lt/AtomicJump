class_name SpecialChest
extends Chest
## Bound electron (electrón ligado, `chest_special`): opens when the player
## touches it carrying a positron, which annihilates with its electron
## (e⁺ + e⁻ → γ γ). A positron icon floats above it as a hint.

## Seconds per turn of its electron (docs/13-art-style.md: 1.5 s per turn).
@export var orbit_period: float = 1.5
## Radii of the orbit the electron follows and its tilt (as drawn).
@export var orbit_radius: Vector2 = Vector2(26.0, 12.0)
@export var orbit_tilt_degrees: float = -20.0

var _time: float = 0.0

@onready var _visual: Node2D = %Visual
@onready var _electron: Sprite2D = %Electron
@onready var _hint: Sprite2D = %Hint
@onready var _touch: Area2D = %Touch


func _ready() -> void:
	_touch.collision_layer = 0
	_touch.collision_mask = 0
	_touch.set_collision_mask_value(PhysicsLayers.PLAYER, true)
	_touch.body_entered.connect(_on_touch_body_entered)


func _process(delta: float) -> void:
	_time += delta
	var angle: float = TAU * _time / orbit_period
	var point := Vector2(cos(angle) * orbit_radius.x, sin(angle) * orbit_radius.y)
	_electron.position = point.rotated(deg_to_rad(orbit_tilt_degrees))
	_hint.position.y = -40.0 + sin(TAU * _time / 1.6) * 3.0


## Uses a positron of the player's run and opens. Returns whether it opened.
func try_open(player: Player) -> bool:
	if is_open or player.run == null or not player.run.spend_keys(1):
		return false
	open()
	return true


func _play_open() -> void:
	_touch.set_deferred(&"monitoring", false)
	var flash := ImpactEffect.new()
	flash.radius = 30.0
	flash.duration = 0.5
	flash.color_a = Palette.POSITRON
	flash.color_b = Palette.NEGATIVE
	flash.position = _visual.position
	add_child(flash)
	flash.finished.connect(flash.queue_free)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, ^"modulate:a", 0.0, 0.25)


func _on_touch_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player != null:
		try_open(player)
