extends Node2D
## Movement test room (docs/04-player.md#sala-de-pruebas-de-movimiento): platforms
## at known heights and gaps, one-way platforms, spikes and the Decoherence, with
## the player's state on screen and its trajectory drawn. Run it with F6.
## Keys: R back to the start, T switches the Decoherence on/off, F the trajectory.
## A development tool: the overlay shows code names and is not translated.

## Points of the trajectory line (4 s at 60 FPS).
const TRAIL_POINTS: int = 240
## Sides and bottom of the room, in px.
const ROOM_LEFT: float = 0.0
const ROOM_RIGHT: float = 1280.0
const ROOM_BOTTOM: float = 40.0
## Below this fraction of the max coherence the player is healed (no deaths here).
const HEAL_BELOW: float = 0.5

## Px under the player where the Decoherence appears when switched on.
@export var threat_start_distance: float = 500.0

var run: RunState = null
var _start: Vector2 = Vector2.ZERO

@onready var _player: Player = %Player
@onready var _camera: PlayerCamera = %Camera
@onready var _threat: RisingThreat = %RisingThreat
@onready var _trail: Line2D = %Trail
@onready var _overlay: Label = %Overlay


func _ready() -> void:
	run = RunState.new("MOVEMENT-ROOM", RunManager.DEFAULT_CHARACTER)
	run.hp_changed.connect(_on_hp_changed)
	_player.bind_run(run)
	_start = _player.global_position
	_trail.default_color = Color(Palette.PLAYER, 0.5)

	_camera.area_left = ROOM_LEFT
	_camera.area_right = ROOM_RIGHT
	_camera.area_bottom = ROOM_BOTTOM
	_camera.target = _player
	_camera.snap_to_target()

	_threat.scan_left = ROOM_LEFT
	_threat.scan_right = ROOM_RIGHT
	_threat.setup(_player)
	_set_threat_active("--threat" in OS.get_cmdline_user_args())


func _physics_process(_delta: float) -> void:
	_trail.add_point(_player.global_position)
	if _trail.get_point_count() > TRAIL_POINTS:
		_trail.remove_point(0)


func _process(_delta: float) -> void:
	_overlay.text = _describe()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_R:
			_player.respawn_at(_start)
			_camera.snap_to_target()
			_trail.clear_points()
		KEY_T:
			_set_threat_active(not _threat.visible)
		KEY_F:
			_trail.visible = not _trail.visible


func _set_threat_active(active: bool) -> void:
	_threat.visible = active
	_threat.set_physics_process(active)
	_threat.global_position.y = _player.global_position.y + threat_start_distance


func _describe() -> String:
	var lines: PackedStringArray = [
		(
			"%s   v = (%.0f, %.0f)"
			% [Player.State.keys()[_player.state], _player.velocity.x, _player.velocity.y]
		),
		(
			"floor %s   coyote %.2f   buffer %.2f   air jumps %d"
			% [
				_player.is_on_floor(),
				_player.coyote_left,
				_player.jump_buffer_left,
				_player.get_air_jumps_left(),
			]
		),
		(
			"dash cd %.2f   invulnerable %s   hp %.0f"
			% [_player.dash_cooldown_left, _player.is_invulnerable(), run.hp]
		),
	]
	if _threat.visible:
		lines.append(
			(
				"decoherence %.0f px/s   distance %.0f px"
				% [_threat.speed, _threat.distance_to(_player.global_position.y)]
			)
		)
	lines.append(tr("DEBUG_MOVEMENT_ROOM_HELP"))
	return "\n".join(lines)


func _on_hp_changed(value: float, max_value: float) -> void:
	if value > 0.0 and value < max_value * HEAL_BELOW:
		run.heal.call_deferred(max_value)
