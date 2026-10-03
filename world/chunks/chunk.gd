@tool
class_name Chunk
extends Node2D
## A hand-made section of a layer, one screen high (docs/05-world.md). Its scene
## (start from chunk_template.tscn) has TileMapLayers for walls and platforms
## (Tiles/Walls, Tiles/Platforms), optional one-way platforms (Tiles/Optional/*),
## entry, exit and special markers (Markers/), spawn slots (Slots/) and fixed
## objects (Props/). Level builds it from a ChunkPlacement: mirrors it, picks
## its optional parts, fills its slots and sets up its fork exits or its reward.
## In the editor it checks itself with ChunkValidator and shows the problems as
## configuration warnings.

## Emitted by a fork chunk when the player crosses one of its exits (0 left, 1 right).
signal branch_chosen(side: int)

## Thirds of the inner width where an entry or an exit can be; entries and
## exits are sets of these flags.
enum Opening { LEFT = 1, CENTER = 2, RIGHT = 4 }

const ALL_OPENINGS: int = Opening.LEFT | Opening.CENTER | Opening.RIGHT
## Size of a tile in px (the tileset textures are 64 px, drawn at TILE_LAYER_SCALE).
const TILE: float = 32.0
const TILE_LAYER_SCALE: float = 0.5
const COLUMNS: int = 40
## Columns of side wall on each side.
const WALL_COLUMNS: int = 3
const WIDTH: float = TILE * COLUMNS
## Inner sides of the walls: where the player can be.
const INNER_LEFT: float = TILE * WALL_COLUMNS
const INNER_RIGHT: float = WIDTH - INNER_LEFT
## Width in tiles of a fork exit and of the space kept free around entries and exits.
const OPENING_TILES: int = 4
const ENTRY_PREFIX: String = "entry_"
const EXIT_PREFIX: String = "exit_"
## Where the player starts (layer start chunks).
const SPAWN_MARKER: StringName = &"spawn"
## Where the reward of a branch appears (reward chunks).
const REWARD_MARKER: StringName = &"reward"
## Slot kinds (docs/05-world.md): a slot is a Marker2D in Slots/ named "<kind>_<n>".
const SLOT_PICKUP: StringName = &"slot_pickup"
const SLOT_CONTAINER: StringName = &"slot_container"
const SLOT_ENEMY_GROUND: StringName = &"slot_enemy_ground"
const SLOT_ENEMY_AIR: StringName = &"slot_enemy_air"
const SLOT_HAZARD: StringName = &"slot_hazard"
const SLOT_SECRET: StringName = &"slot_secret"
const SLOT_KINDS: Array[StringName] = [
	SLOT_PICKUP, SLOT_CONTAINER, SLOT_ENEMY_GROUND, SLOT_ENEMY_AIR, SLOT_HAZARD, SLOT_SECRET
]
## Objects that slots and rewards can hold (pickups: see PickupScenes).
const COIN: StringName = PickupScenes.COIN
const COIN_5: StringName = PickupScenes.COIN_5
const COIN_10: StringName = PickupScenes.COIN_10
const KEY: StringName = PickupScenes.KEY
const HEAL: StringName = PickupScenes.HEAL
const HEAL_BIG: StringName = PickupScenes.HEAL_BIG
const SPIKE: StringName = &"spike"
## Containers (docs/06-economy.md#contenedores): quantum well, bound electron, superposition.
const CHEST: StringName = &"chest"
const CHEST_SPECIAL: StringName = &"chest_special"
const CHOICE_PEDESTAL: StringName = &"choice_pedestal"
## Enemies of Layer K (their EnemyData ids).
const ORBITAL_ELECTRON: StringName = &"orbital_electron"
const FREE_NEUTRON: StringName = &"free_neutron"
const ALPHA_PARTICLE: StringName = &"alpha_particle"
const OBJECT_SCENES: Dictionary[StringName, PackedScene] = {
	COIN: preload("res://items/pickups/coin/coin.tscn"),
	COIN_5: preload("res://items/pickups/coin/coin_5.tscn"),
	COIN_10: preload("res://items/pickups/coin/coin_10.tscn"),
	KEY: preload("res://items/pickups/key/key.tscn"),
	HEAL: preload("res://items/pickups/heal/heal_pickup.tscn"),
	HEAL_BIG: preload("res://items/pickups/heal/heal_pickup_big.tscn"),
	SPIKE: preload("res://world/hazards/spike/spike.tscn"),
	CHEST: preload("res://items/containers/common_chest.tscn"),
	CHEST_SPECIAL: preload("res://items/containers/special_chest.tscn"),
	CHOICE_PEDESTAL: preload("res://items/containers/choice_pedestal.tscn"),
	ORBITAL_ELECTRON: preload("res://actors/enemies/orbital_electron/orbital_electron.tscn"),
	FREE_NEUTRON: preload("res://actors/enemies/free_neutron/free_neutron.tscn"),
	ALPHA_PARTICLE: preload("res://actors/enemies/alpha_particle/alpha_particle.tscn"),
}
const FORK_GATE_SCENE: PackedScene = preload("res://world/chunks/fork_gate.tscn")
const ITEM_PEDESTAL_SCENE: PackedScene = preload("res://items/containers/item_pedestal.tscn")
## Coins of a reward_coins reward, in a ring around the reward marker.
const REWARD_COINS: int = 8
const REWARD_RING_RADIUS: float = 44.0
## Px between the photons an enemy drops, and how high above its origin.
const DROP_SPACING: float = 20.0
const DROP_HEIGHT: float = 16.0
## Suffix of the address of what an enemy decays into.
const DECAY_KEY: StringName = &"decay"
## Prefix of the address of a branch's reward item (domain "loot").
const REWARD_KEY: StringName = &"reward"
## Chance that a reward_item is a superposition (two items) instead of a pedestal.
const REWARD_CHOICE_CHANCE: float = 0.5

@export var data: ChunkData:
	set(value):
		data = value
		update_configuration_warnings()
## Checks the chunk now (the warnings also refresh when the scene is saved).
@export_tool_button("Validate chunk") var validate_action: Callable = _validate_in_editor

## Whether apply_mirror() was called.
var mirrored: bool = false
var _gates: Array[ForkGate] = []
var _chosen_side: int = -1
## Rolls of the run, for the drops of the enemies (set by fill_slots()).
var _rng: WorldRng = null
var _layer_index: int = 0
## Item and loot rolls of the run, for containers, rewards and shops.
var _roller: LootRoller = null


## Opening (third of the inner width) that contains the x of a marker.
static func opening_at(x: float) -> Opening:
	var third: float = (INNER_RIGHT - INNER_LEFT) / 3.0
	if x < INNER_LEFT + third:
		return Opening.LEFT
	if x < INNER_LEFT + 2.0 * third:
		return Opening.CENTER
	return Opening.RIGHT


## The openings of a set once the chunk is mirrored (left and right swap).
static func mirror_openings(openings: int) -> int:
	var result: int = openings & Opening.CENTER
	if openings & Opening.LEFT:
		result |= Opening.RIGHT
	if openings & Opening.RIGHT:
		result |= Opening.LEFT
	return result


## Kind of a slot from its name ("slot_pickup_3" → slot_pickup), or &"" if the
## name does not follow the "<kind>_<n>" rule.
static func slot_kind(slot_name: StringName) -> StringName:
	var text: String = slot_name
	for kind: StringName in SLOT_KINDS:
		var prefix: String = String(kind) + "_"
		if text.begins_with(prefix) and text.trim_prefix(prefix).is_valid_int():
			return kind
	return &""


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	# Only chunk scenes are validated, not a Chunk used inside another scene
	# (the combat test room's arena)
	if owner != null:
		return PackedStringArray()
	return ChunkValidator.validate(self)


## Refreshes the warnings and prints the problems (the inspector's button).
func _validate_in_editor() -> void:
	var problems: PackedStringArray = ChunkValidator.validate(self)
	update_configuration_warnings()
	if problems.is_empty():
		print("Chunk %s: OK" % name)
	else:
		push_warning("Chunk %s:\n- %s" % [name, "\n- ".join(problems)])


func is_safe() -> bool:
	return data != null and data.is_safe()


func get_height() -> float:
	var rows: int = data.height_tiles if data != null else ChunkData.DEFAULT_HEIGHT_TILES
	return rows * TILE


func get_walls() -> TileMapLayer:
	return get_node_or_null(^"Tiles/Walls") as TileMapLayer


func get_platforms() -> TileMapLayer:
	return get_node_or_null(^"Tiles/Platforms") as TileMapLayer


func get_optional_layers() -> Array[TileMapLayer]:
	var layers: Array[TileMapLayer] = []
	var optional: Node = get_node_or_null(^"Tiles/Optional")
	if optional != null:
		for child: Node in optional.get_children():
			if child is TileMapLayer:
				layers.append(child as TileMapLayer)
	return layers


## Every TileMapLayer of the chunk: walls, platforms and optional parts.
func _tile_layers() -> Array[TileMapLayer]:
	var layers: Array[TileMapLayer] = []
	for layer: TileMapLayer in [get_walls(), get_platforms()]:
		if layer != null:
			layers.append(layer)
	layers.append_array(get_optional_layers())
	return layers


func get_marker(marker_name: StringName) -> Marker2D:
	return get_node_or_null(NodePath("Markers/" + String(marker_name))) as Marker2D


## Entry markers (bottom edge), left to right.
func get_entry_markers() -> Array[Marker2D]:
	return _markers_with_prefix(ENTRY_PREFIX)


## Exit markers (top edge), left to right: a fork's left branch is the first.
func get_exit_markers() -> Array[Marker2D]:
	return _markers_with_prefix(EXIT_PREFIX)


func get_slot_nodes() -> Array[Node2D]:
	var nodes: Array[Node2D] = []
	var slots: Node = get_node_or_null(^"Slots")
	if slots != null:
		for child: Node in slots.get_children():
			if child is Node2D:
				nodes.append(child as Node2D)
	return nodes


## Mirrors the chunk horizontally: tiles, markers, slots and props. Call it
## once, before adding the chunk to the tree.
func apply_mirror() -> void:
	assert(not mirrored, "Chunk already mirrored")
	mirrored = true
	for layer: TileMapLayer in _tile_layers():
		_mirror_layer(layer)
	for group: NodePath in [^"Markers", ^"Slots", ^"Props"]:
		var node: Node = get_node_or_null(group)
		if node == null:
			continue
		for child: Node in node.get_children():
			if child is Node2D:
				var child_2d: Node2D = child
				child_2d.position.x = WIDTH - child_2d.position.x


## Shows the optional parts in `enabled` and disables the rest (no drawing, no collision).
func set_optional_parts(enabled: Array[StringName]) -> void:
	for layer: TileMapLayer in get_optional_layers():
		layer.enabled = layer.name in enabled


## Fills the slots with {slot name: object id} from SlotFiller.plan(). The
## enemies and the containers get the address of their slot (`key` + slot
## name), which seeds their decisions, their drops and their loot with `rng`
## and `roller`; enemies scale and containers cost more with `layer_index`.
func fill_slots(
	plan: Dictionary[StringName, StringName],
	key: Array = [],
	rng: WorldRng = null,
	layer_index: int = 0,
	roller: LootRoller = null
) -> void:
	set_rolls(rng, layer_index, roller)
	for slot_name: StringName in plan:
		var slot: Node2D = get_node_or_null(NodePath("Slots/" + String(slot_name))) as Node2D
		if slot == null or not OBJECT_SCENES.has(plan[slot_name]):
			continue
		var object: Node = OBJECT_SCENES[plan[slot_name]].instantiate()
		var enemy: Enemy = object as Enemy
		var container: LootContainer = object as LootContainer
		if enemy != null:
			add_enemy(enemy, slot.position, key + [slot_name])
		elif container != null:
			container.setup_slot(key + [slot_name], _roller, _layer_index)
			_add_object(container, slot.position)
		else:
			_add_object(object as Node2D, slot.position)


## Rolls of the run for the drops of the enemies and the loot of the
## containers, and the layer index that scales them (fill_slots() sets them).
func set_rolls(rng: WorldRng, layer_index: int = 0, roller: LootRoller = null) -> void:
	_rng = rng
	_layer_index = layer_index
	_roller = roller


## Adds an enemy at `at` (chunk px) with the address of its slot. When it dies,
## the chunk drops its loot and spawns what it decays into.
func add_enemy(enemy: Enemy, at: Vector2, address: Array) -> void:
	enemy.setup(address, _rng, _layer_index)
	enemy.died.connect(_on_enemy_died)
	_add_object(enemy, at)


## Enemies of the chunk that are still alive.
func get_enemies() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for child: Node in get_children():
		if child is Enemy and not (child as Enemy).is_dying():
			enemies.append(child as Enemy)
	return enemies


## Puts the reward of the branch on the reward marker. A reward_item rolls
## its observable (or the two of a superposition) at ("reward", `key`…) with
## the roller given to set_rolls().
func spawn_reward(reward: StringName, key: Array = []) -> void:
	var marker: Marker2D = get_marker(REWARD_MARKER)
	if marker == null:
		return
	match reward:
		LayerData.REWARD_COINS:
			for i: int in REWARD_COINS:
				var offset: Vector2 = (
					Vector2.UP.rotated(TAU * i / REWARD_COINS) * REWARD_RING_RADIUS
				)
				_spawn(OBJECT_SCENES[COIN], marker.position + offset)
		LayerData.REWARD_KEY:
			_spawn(OBJECT_SCENES[KEY], marker.position)
		LayerData.REWARD_ITEM:
			_spawn_reward_item(marker.position, [REWARD_KEY] + key)


## Rolls the shops of the chunk (Shop nodes in Props/) with the roller given
## to set_rolls(), at the chunk's `key`. Returns them.
func setup_shops(key: Array) -> Array[Shop]:
	var shops: Array[Shop] = []
	var props: Node = get_node_or_null(^"Props")
	if props == null or _roller == null:
		return shops
	for child: Node in props.get_children():
		var shop: Shop = child as Shop
		if shop != null:
			shop.setup(key, _roller, _layer_index)
			shops.append(shop)
	return shops


## Puts a pickup (an OBJECT_SCENES id) at `at` (chunk px), e.g. what an item
## effect drops. Deferred, since it may happen during a physics callback.
func spawn_object(object_id: StringName, at: Vector2) -> void:
	if OBJECT_SCENES.has(object_id):
		_spawn.call_deferred(OBJECT_SCENES[object_id], at)


## Puts a ForkGate on each exit, left to right, showing the reward of its branch.
func setup_fork(rewards: Array[StringName]) -> void:
	var exits: Array[Marker2D] = get_exit_markers()
	for side: int in exits.size():
		var gate: ForkGate = FORK_GATE_SCENE.instantiate()
		gate.position = exits[side].position
		gate.width = OPENING_TILES * TILE
		gate.reward = rewards[side] if side < rewards.size() else &""
		gate.entered.connect(_on_gate_entered.bind(side))
		add_child(gate)
		_gates.append(gate)


func get_gates() -> Array[ForkGate]:
	return _gates


func _spawn_reward_item(at: Vector2, address: Array) -> void:
	if _roller == null or _rng == null:
		return
	if _rng.chance(REWARD_CHOICE_CHANCE, &"loot", address + [&"choice"]):
		var choice: ChoicePedestal = OBJECT_SCENES[CHOICE_PEDESTAL].instantiate()
		choice.setup_slot(address, _roller, _layer_index)
		_add_object(choice, at)
		return
	var item: ItemData = _roller.roll_item(ItemData.POOL_CONTAINER, address)
	if item == null:
		return
	var pedestal: ItemPedestal = ITEM_PEDESTAL_SCENE.instantiate()
	pedestal.set_item(item)
	_add_object(pedestal, at)


func _markers_with_prefix(prefix: String) -> Array[Marker2D]:
	var found: Array[Marker2D] = []
	var markers: Node = get_node_or_null(^"Markers")
	if markers == null:
		return found
	for child: Node in markers.get_children():
		if child is Marker2D and String(child.name).begins_with(prefix):
			found.append(child as Marker2D)
	found.sort_custom(func(a: Marker2D, b: Marker2D) -> bool: return a.position.x < b.position.x)
	return found


func _spawn(scene: PackedScene, at: Vector2) -> Node2D:
	return _add_object(scene.instantiate() as Node2D, at)


func _add_object(object: Node2D, at: Vector2) -> Node2D:
	object.position = at
	add_child(object)
	return object


## Drops the loot of a dead enemy and spawns what it decays into. Deferred:
## it dies during a physics callback, when areas cannot be added.
func _on_enemy_died(enemy: Enemy) -> void:
	var drops: Array[StringName] = enemy.data.roll_drops(_rng, enemy.address)
	for i: int in drops.size():
		var offset: Vector2 = Vector2((i - (drops.size() - 1) / 2.0) * DROP_SPACING, -DROP_HEIGHT)
		_spawn.call_deferred(OBJECT_SCENES[drops[i]], enemy.position + offset)
	if enemy.data.decay_scene != null:
		var product: Enemy = enemy.data.decay_scene.instantiate() as Enemy
		product.lifetime = enemy.data.decay_lifetime
		var center: Vector2 = enemy.position + enemy.body.position
		add_enemy.call_deferred(product, center, enemy.address + [DECAY_KEY])


## Mirrors the cells of a layer: column c goes to COLUMNS - 1 - c with its tile flipped.
static func _mirror_layer(layer: TileMapLayer) -> void:
	var cells: Array[Vector2i] = layer.get_used_cells()
	var sources: Array[int] = []
	var atlas_coords: Array[Vector2i] = []
	var alternatives: Array[int] = []
	for cell: Vector2i in cells:
		sources.append(layer.get_cell_source_id(cell))
		atlas_coords.append(layer.get_cell_atlas_coords(cell))
		alternatives.append(layer.get_cell_alternative_tile(cell))
	layer.clear()
	for i: int in cells.size():
		layer.set_cell(
			Vector2i(COLUMNS - 1 - cells[i].x, cells[i].y),
			sources[i],
			atlas_coords[i],
			alternatives[i] ^ TileSetAtlasSource.TRANSFORM_FLIP_H
		)


func _on_gate_entered(side: int) -> void:
	if _chosen_side != -1:
		return
	_chosen_side = side
	for i: int in _gates.size():
		if i == side:
			_gates[i].choose()
		else:
			_gates[i].collapse()
	branch_chosen.emit(side)
