extends Node2D
## Combat test room (docs/09-enemies.md#sala-de-pruebas-de-combate): a floor, a
## long platform and the player, to fight the enemies of Layer K one by one.
## Run it with F6. The enemies live in an empty Chunk, so their drops and their
## decay work as in a run. Pass `-- --spawn=all` to start with one of each.
## Keys: 1 orbital electron, 2 free neutron, 3 alpha particle, K kill all,
## 4 / 5 / 6 apply Inestable / Dilatado / Confinado to every enemy, R back to
## the start. A development tool: the overlay shows code names.

const SPAWN_ARG: String = "--spawn="
## Room bounds in px (the floor's top is at y = 0).
const ROOM_LEFT: float = 0.0
const ROOM_RIGHT: float = 1280.0
const ROOM_BOTTOM: float = 40.0
## Below this fraction of the max coherence the player is healed (no deaths here).
const HEAL_BELOW: float = 0.5
const STATUS_DECAY: StatusEffectData = preload("res://data/statuses/status_decay.tres")
const STATUS_SLOW: StatusEffectData = preload("res://data/statuses/status_slow.tres")
const STATUS_ROOT: StatusEffectData = preload("res://data/statuses/status_root.tres")

## Where each enemy appears (room px), by its key.
@export var spawn_points: Dictionary[StringName, Vector2] = {
	Chunk.ORBITAL_ELECTRON: Vector2(230, -470),
	Chunk.FREE_NEUTRON: Vector2(576, -200),
	Chunk.ALPHA_PARTICLE: Vector2(760, 0),
}

var run: RunState = null
var _start: Vector2 = Vector2.ZERO
var _spawned: int = 0

@onready var _arena: Chunk = %Arena
@onready var _player: Player = %Player
@onready var _camera: PlayerCamera = %Camera
@onready var _projectiles: Node2D = %Projectiles
@onready var _overlay: Label = %Overlay
@onready var _hit_stop: HitStop = %HitStop


func _ready() -> void:
	run = RunState.new("COMBAT-ROOM", RunManager.DEFAULT_CHARACTER)
	run.hp_changed.connect(_on_hp_changed)
	_arena.set_rolls(run.world_rng)
	_player.bind_run(run)
	_player.set_projectile_parent(_projectiles)
	_start = _player.global_position
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.enemy_damaged.connect(_on_enemy_damaged)
	_player.hurt.connect(func() -> void: _hit_stop.stop(_hit_stop.player_hurt_time))

	_camera.area_left = ROOM_LEFT
	_camera.area_right = ROOM_RIGHT
	_camera.area_bottom = ROOM_BOTTOM
	_camera.target = _player
	_camera.snap_to_target()
	if SPAWN_ARG + "all" in OS.get_cmdline_user_args():
		for id: StringName in spawn_points:
			spawn(id)


func _process(_delta: float) -> void:
	_overlay.text = _describe()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1:
			spawn(Chunk.ORBITAL_ELECTRON)
		KEY_2:
			spawn(Chunk.FREE_NEUTRON)
		KEY_3:
			spawn(Chunk.ALPHA_PARTICLE)
		KEY_4:
			_apply_to_all(STATUS_DECAY)
		KEY_5:
			_apply_to_all(STATUS_SLOW)
		KEY_6:
			_apply_to_all(STATUS_ROOT)
		KEY_K:
			for enemy: Enemy in _arena.get_enemies():
				enemy.health.take_hit(DamageInfo.create(enemy.health.hp))
		KEY_R:
			_player.respawn_at(_start)
			_camera.snap_to_target()


## Adds an enemy at its spawn point. Each one gets its own address.
func spawn(id: StringName) -> Enemy:
	var enemy: Enemy = Chunk.OBJECT_SCENES[id].instantiate()
	_spawned += 1
	_arena.add_enemy(enemy, spawn_points[id], ["room", _spawned])
	return enemy


func _apply_to_all(status: StatusEffectData) -> void:
	for enemy: Enemy in _arena.get_enemies():
		enemy.statuses.apply(status)


func _describe() -> String:
	var lines: PackedStringArray = [
		(
			"hp %.0f   kills %d   cooldown %.2f"
			% [run.hp, run.counters.enemies_killed, _player.get_shooter().cooldown_left]
		)
	]
	for enemy: Enemy in _arena.get_enemies():
		(
			lines
			. append(
				(
					"%s  hp %.1f/%.0f  x%.2f"
					% [
						enemy.data.id,
						enemy.health.hp,
						enemy.health.max_hp,
						enemy.get_time_scale(),
					]
				)
			)
		)
	lines.append(tr("DEBUG_COMBAT_ROOM_HELP"))
	return "\n".join(lines)


func _on_enemy_killed(enemy_id: StringName, _position: Vector2) -> void:
	run.register_kill(enemy_id)
	_hit_stop.stop(_hit_stop.enemy_kill_time)


func _on_enemy_damaged(_enemy_id: StringName) -> void:
	_hit_stop.stop(_hit_stop.enemy_hit_time)


func _on_hp_changed(value: float, max_value: float) -> void:
	if value > 0.0 and value < max_value * HEAL_BELOW:
		run.heal.call_deferred(max_value)
