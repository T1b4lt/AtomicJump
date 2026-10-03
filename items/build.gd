class_name Build
extends RefCounted
## What the player carries in a run (docs/07-items.md): observables, the
## operator with its charge and the transformations by tag. It applies the
## effects of the items (ItemEffect) and passes them the hooks of the player
## and of the combat: the player calls it down (shots, hits, physics frames)
## and the run calls it when photons are collected or a chunk is entered.
##
## RunState owns it; it keeps the run through a weak reference to avoid a
## reference cycle. `player` and `spawner` are set by the level.

signal items_changed
signal active_item_changed(item: ItemData)
signal active_charge_changed(charge: int, max_charge: int)
signal transformation_gained(transformation: TransformationData)
## An operator was used.
signal active_used(item: ItemData)

var catalog: ItemCatalog = null
var passive_items: Array[ItemData] = []
var active_item: ItemData = null
## Chunks climbed since the operator was last used (full at its charge_chunks).
var active_charge: int = 0
var transformations: Array[TransformationData] = []
## The player of the run (effects that shoot or look at the screen use it).
var player: Player = null
## func(object_id: StringName, global_position: Vector2) that puts a pickup
## in the world (Chunk object ids). Set by the level.
var spawner: Callable = Callable()
## Combat randomness (domain "combat": not guaranteed by the seed).
var combat_rng := RandomNumberGenerator.new()

var _run: WeakRef = null
## Effect instances of the passive items and transformations, in order.
var _effects: Array[ItemEffect] = []
var _active_effects: Array[ItemEffect] = []


func _init(run: RunState, p_catalog: ItemCatalog = null) -> void:
	_run = weakref(run)
	catalog = p_catalog
	if run.world_rng != null:
		combat_rng = run.world_rng.local_rng(&"combat", [])


func get_run() -> RunState:
	var run: RunState = _run.get_ref()
	return run


func get_stats() -> Stats:
	var run: RunState = get_run()
	return run.stats if run != null else null


## Gains an item. An operator replaces the one carried, which is returned (so
## the pedestal can hold it); otherwise returns null.
func add_item(item: ItemData) -> ItemData:
	if item.is_active():
		return _set_active_item(item)
	passive_items.append(item)
	_effects.append_array(_instantiate(item.effects, item.id))
	_check_transformations(item)
	items_changed.emit()
	return null


func has_item(id: StringName) -> bool:
	if active_item != null and active_item.id == id:
		return true
	for item: ItemData in passive_items:
		if item.id == id:
			return true
	return false


## Ids of every item carried (to leave them out of the pools).
func get_owned_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for item: ItemData in passive_items:
		ids.append(item.id)
	if active_item != null:
		ids.append(active_item.id)
	return ids


## Observables carried with a tag.
func count_tag(tag: StringName) -> int:
	var count: int = 0
	for item: ItemData in passive_items:
		if tag in item.tags:
			count += 1
	return count


func has_transformation(id: StringName) -> bool:
	return transformations.any(func(t: TransformationData) -> bool: return t.id == id)


func get_max_charge() -> int:
	return active_item.charge_chunks if active_item != null else 0


func is_active_ready() -> bool:
	return active_item != null and active_charge >= get_max_charge()


## Uses the operator if it is charged. Returns whether it was used.
func use_active() -> bool:
	if not is_active_ready():
		return false
	var used: bool = false
	for effect: ItemEffect in _active_effects:
		used = effect.activate(self) or used
	if not used:
		return false
	active_charge = 0
	active_charge_changed.emit(active_charge, get_max_charge())
	active_used.emit(active_item)
	return true


## A chunk was climbed: recharges the operator and tells the effects.
func on_chunk_entered(index: int) -> void:
	if active_item != null and active_charge < get_max_charge():
		active_charge += 1
		active_charge_changed.emit(active_charge, get_max_charge())
	for effect: ItemEffect in _all_effects():
		effect.chunk_entered(self, index)


func on_coins_collected(amount: int) -> void:
	for effect: ItemEffect in _all_effects():
		effect.coins_collected(self, amount)


## Lets the effects transform a shot of the player before it is launched.
func modify_projectile(spec: ProjectileSpec, direction: Vector2, shooter_velocity: Vector2) -> void:
	for effect: ItemEffect in _all_effects():
		effect.modify_projectile(self, spec, direction, shooter_velocity)


func on_projectile_hit(info: DamageInfo, at: Vector2) -> void:
	for effect: ItemEffect in _all_effects():
		effect.projectile_hit(self, info, at)


func physics_step(delta: float) -> void:
	for effect: ItemEffect in _all_effects():
		effect.physics_step(self, delta)


## Puts a pickup (a Chunk object id) in the world, if the level gave a spawner.
func spawn(object_id: StringName, at: Vector2) -> void:
	if spawner.is_valid():
		spawner.call(object_id, at)


## The visible area of the world (for "on screen" effects), or an empty rect.
func get_view_rect() -> Rect2:
	if player == null or not player.is_inside_tree():
		return Rect2()
	var viewport: Viewport = player.get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()


func _set_active_item(item: ItemData) -> ItemData:
	var previous: ItemData = active_item
	for effect: ItemEffect in _active_effects:
		effect.removed(self)
	active_item = item
	# A new operator comes charged (as in Isaac)
	active_charge = item.charge_chunks
	_active_effects = _instantiate(item.effects, item.id)
	active_item_changed.emit(item)
	active_charge_changed.emit(active_charge, get_max_charge())
	items_changed.emit()
	return previous


## Copies of some effect templates for one source, already applied.
func _instantiate(templates: Array[ItemEffect], source: StringName) -> Array[ItemEffect]:
	var instances: Array[ItemEffect] = []
	for template: ItemEffect in templates:
		var effect: ItemEffect = template.duplicate()
		effect.source = source
		effect.added(self)
		instances.append(effect)
	return instances


func _check_transformations(item: ItemData) -> void:
	if catalog == null:
		return
	for transformation: TransformationData in catalog.transformations:
		if (
			transformation.tag in item.tags
			and not has_transformation(transformation.id)
			and count_tag(transformation.tag) >= transformation.required
		):
			transformations.append(transformation)
			_effects.append_array(_instantiate(transformation.effects, transformation.id))
			transformation_gained.emit(transformation)


func _all_effects() -> Array[ItemEffect]:
	return _effects + _active_effects
