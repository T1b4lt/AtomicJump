class_name ItemPedestal
extends Node2D
## Pedestal (docs/06-economy.md#contenedores): an item floating over a short
## energy level, free to take with the interact action. Taking an operator
## while carrying one leaves the old one on the pedestal. In a superposition,
## taking one pedestal collapses the other.

signal taken(item: ItemData)

@export var bob_height: float = 4.0
@export var bob_period: float = 1.6
## Seconds the icon takes to rise and fade when taken, or to collapse.
@export var vanish_time: float = 0.35

var item: ItemData = null
var collapsed: bool = false
var _time: float = 0.0

@onready var _icon: ItemIcon = %Icon
@onready var _interactable: Interactable = %Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	if not collapsed:
		_icon.position.y = icon_rest_y() + sin(TAU * _time / bob_period) * bob_height


func set_item(new_item: ItemData) -> void:
	item = new_item
	if is_node_ready():
		_refresh()


func is_empty() -> bool:
	return item == null


## Takes the item for the player (also what the interact action does).
func take(player: Player) -> void:
	if item == null or collapsed or player.run == null:
		return
	var taken_item: ItemData = item
	var replaced: ItemData = player.run.add_item(taken_item)
	set_item(replaced)
	taken.emit(taken_item)
	if replaced == null:
		_vanish(true)


## The other choice was taken: this one dissolves (superposition).
func collapse() -> void:
	if collapsed:
		return
	collapsed = true
	_interactable.enabled = false
	_vanish(false)


func get_interactable() -> Interactable:
	return _interactable


## Height of the icon over the pedestal's origin (on its base).
func icon_rest_y() -> float:
	return -36.0


func _refresh() -> void:
	_icon.set_item(item)
	_icon.visible = item != null
	_icon.modulate = Color.WHITE
	_icon.scale = Vector2.ONE
	_interactable.enabled = item != null and not collapsed
	_interactable.prompt = tr(item.get_name_key()) if item != null else ""


## Rises and fades (taken) or shrinks and fades (collapsed).
func _vanish(rise: bool) -> void:
	_interactable.enabled = false
	var tween: Tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	if rise:
		tween.tween_property(_icon, ^"position:y", _icon.position.y - 24.0, vanish_time)
	else:
		tween.tween_property(_icon, ^"scale", Vector2.ZERO, vanish_time)
	tween.tween_property(_icon, ^"modulate:a", 0.0, vanish_time)


func _on_interacted(player: Player) -> void:
	take(player)
