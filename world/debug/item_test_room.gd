extends Node2D
## Item test room (docs/07-items.md#sala-de-pruebas-de-objetos): every pickup
## and container on one floor, with the HUD and the build screen, to try the
## economy and the items. Run it with F6. The objects live in an empty Chunk
## (as in a run) and its loot uses the run's rolls.
## Keys: C photons and a positron, I next observable of the catalog, O next
## operator, H lose coherence, 1 spawn a free neutron (to try the operators),
## R rebuild the room. A development tool: the overlay shows code names.

## Room bounds in px (the floor's top is at y = 0).
const ROOM_LEFT: float = 0.0
const ROOM_RIGHT: float = 1280.0
const ROOM_BOTTOM: float = 40.0
const DEBUG_COINS: int = 50
const DEBUG_DAMAGE: float = 30.0
## Objects of the room (Chunk object ids) and where they go (room px).
const LAYOUT: Dictionary[StringName, Vector2] = {
	Chunk.COIN: Vector2(120, -20),
	Chunk.COIN_5: Vector2(160, -20),
	Chunk.COIN_10: Vector2(205, -20),
	Chunk.KEY: Vector2(260, -20),
	Chunk.HEAL: Vector2(310, -20),
	Chunk.HEAL_BIG: Vector2(360, -24),
	Chunk.CHEST: Vector2(480, 0),
	Chunk.CHEST_SPECIAL: Vector2(620, 0),
	Chunk.CHOICE_PEDESTAL: Vector2(780, 0),
}
const PEDESTAL_POSITION: Vector2 = Vector2(980, 0)
const ENEMY_POSITION: Vector2 = Vector2(1120, -200)

var run: RunState = null
var _start: Vector2 = Vector2.ZERO
var _rebuilds: int = 0
var _next_item: int = 0
var _next_active: int = 0
var _pedestal: ItemPedestal = null
var _arena: Chunk = null

@onready var _player: Player = %Player
@onready var _camera: PlayerCamera = %Camera
@onready var _projectiles: Node2D = %Projectiles
@onready var _hud: Hud = %Hud
@onready var _build_screen: BuildScreen = %BuildScreen
@onready var _overlay: Label = %Overlay


func _ready() -> void:
	_start = _player.global_position
	_camera.area_left = ROOM_LEFT
	_camera.area_right = ROOM_RIGHT
	_camera.area_bottom = ROOM_BOTTOM
	_camera.target = _player
	_build()


func _exit_tree() -> void:
	if RunManager.run == run:
		RunManager.run = null


func _process(_delta: float) -> void:
	_overlay.text = _describe()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_C:
			run.add_coins(DEBUG_COINS)
			run.add_keys(1)
		KEY_I:
			_put_next(ItemData.Kind.PASSIVE)
		KEY_O:
			_put_next(ItemData.Kind.ACTIVE)
		KEY_H:
			run.take_damage(DEBUG_DAMAGE, false, &"debug")
		KEY_1:
			_arena.add_enemy(
				Chunk.OBJECT_SCENES[Chunk.FREE_NEUTRON].instantiate() as Enemy,
				ENEMY_POSITION,
				[&"item_room", _rebuilds]
			)
		KEY_R:
			_build()


## (Re)builds the room with a new run.
func _build() -> void:
	if _arena != null:
		_arena.queue_free()
	_rebuilds += 1
	run = RunState.new("ITEM-ROOM-%d" % _rebuilds, RunManager.DEFAULT_CHARACTER, RunManager.CATALOG)
	run.hp_changed.connect(_on_hp_changed)
	run.build.spawner = _spawn_object
	# The pickups report to RunManager's run: make this room's run that one
	RunManager.run = run
	_player.bind_run(run)
	_player.set_projectile_parent(_projectiles)
	_hud.bind_run(run)
	_build_screen.bind_run(run)
	var roller := LootRoller.new(run.world_rng, run.build.catalog, run)
	_arena = Chunk.new()
	_arena.set_rolls(run.world_rng, 0, roller)
	for object_id: StringName in LAYOUT:
		var object: Node2D = Chunk.OBJECT_SCENES[object_id].instantiate()
		object.position = LAYOUT[object_id]
		var container: LootContainer = object as LootContainer
		if container != null:
			container.setup_slot([&"item_room", object_id], roller)
		_arena.add_child(object)
	_pedestal = Chunk.ITEM_PEDESTAL_SCENE.instantiate()
	_pedestal.position = PEDESTAL_POSITION
	_arena.add_child(_pedestal)
	add_child(_arena)
	_player.respawn_at(_start)
	_camera.snap_to_target()


## Puts the next observable or operator of the catalog on the pedestal.
func _put_next(kind: ItemData.Kind) -> void:
	var items: Array[ItemData] = []
	for item: ItemData in run.build.catalog.items:
		if item.kind == kind:
			items.append(item)
	if items.is_empty():
		return
	var index: int = _next_item if kind == ItemData.Kind.PASSIVE else _next_active
	if kind == ItemData.Kind.PASSIVE:
		_next_item += 1
	else:
		_next_active += 1
	if not is_instance_valid(_pedestal) or _pedestal.collapsed:
		_pedestal = Chunk.ITEM_PEDESTAL_SCENE.instantiate()
		_pedestal.position = PEDESTAL_POSITION
		_arena.add_child(_pedestal)
	_pedestal.set_item(items[index % items.size()])


func _spawn_object(object_id: StringName, at: Vector2) -> void:
	_arena.spawn_object(object_id, _arena.to_local(at))


func _describe() -> String:
	return (
		"\n"
		. join(
			PackedStringArray(
				[
					(
						"photons %d   positrons %d   coherence %.0f/%.0f   items %d   operator %s"
						% [
							run.coins,
							run.keys,
							run.hp,
							run.get_max_hp(),
							run.build.passive_items.size(),
							run.build.active_item.id if run.build.active_item != null else "-",
						]
					),
					tr("DEBUG_ITEM_ROOM_HELP"),
				]
			)
		)
	)


## No deaths in the test room.
func _on_hp_changed(value: float, max_value: float) -> void:
	if value <= 0.0:
		run.heal(max_value)
