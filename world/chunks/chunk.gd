class_name Chunk
extends Node2D
## Prototype chunk: a screen-high block of platforms with object placeholders.
## Phase 5 turns it into the real chunk format (docs/05-world.md).

signal screen_entered
signal screen_exited

## Height of every prototype chunk in px (the old 1160×670 viewport height).
const HEIGHT: float = 670.0
## Width of the playable area in px, walls included.
const WIDTH: float = 1160.0
const SPIKE_SCENE: PackedScene = preload("res://world/hazards/spike/spike.tscn")
const COIN_SCENE: PackedScene = preload("res://items/pickups/coin/coin.tscn")
const KEY_SCENE: PackedScene = preload("res://items/pickups/key/key.tscn")
## How many of each object a chunk gets: rolled in [min, max].
const SPIKES_RANGE: Vector2i = Vector2i(0, 1)
const COINS_RANGE: Vector2i = Vector2i(1, 5)
const KEYS_RANGE: Vector2i = Vector2i(0, 1)

@onready var _object_placeholders: Node2D = %ObjectPlaceholders


## Fills the placeholders with spikes, coins and keys, one object per placeholder.
## Uses the global RNG seeded by the level (seeded generation arrives in Phase 3).
func place_objects() -> void:
	var placeholders: Array[Node] = _object_placeholders.get_children()
	var occupied: Array[int] = []
	_place(SPIKE_SCENE, _roll_count(SPIKES_RANGE), placeholders, occupied)
	_place(COIN_SCENE, _roll_count(COINS_RANGE), placeholders, occupied)
	_place(KEY_SCENE, _roll_count(KEYS_RANGE), placeholders, occupied)


## Same formula as the prototype (randi() % n), so a seed keeps its layout.
func _roll_count(count_range: Vector2i) -> int:
	return randi() % (count_range.y - count_range.x + 1) + count_range.x


func _place(
	scene: PackedScene, count: int, placeholders: Array[Node], occupied: Array[int]
) -> void:
	var placed: int = 0
	while placed < count:
		var index: int = randi() % placeholders.size()
		if index in occupied:
			continue
		occupied.append(index)
		var object: Node2D = scene.instantiate() as Node2D
		object.position = (placeholders[index] as Node2D).position
		add_child(object)
		placed += 1


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	screen_entered.emit()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	screen_exited.emit()
