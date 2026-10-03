class_name RestChoice
extends Node2D
## One of the two choices of a Ground State (Estado fundamental): an icon over
## a pedestal that the player takes with the interact action. RestShrine
## decides what it does.

signal chosen(choice: RestChoice, player: Player)

@export var icon: Texture2D = null
## Translation key of the prompt.
@export var prompt_key: String = ""
@export var bob_height: float = 4.0
@export var bob_period: float = 1.6
@export var vanish_time: float = 0.35

var used: bool = false
var _time: float = 0.0

@onready var _icon: ItemIcon = %Icon
@onready var _interactable: Interactable = %Interactable


func _ready() -> void:
	_icon.set_icon(icon)
	_interactable.prompt = tr(prompt_key)
	_interactable.interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	_time += delta
	if not used:
		_icon.position.y = -36.0 + sin(TAU * _time / bob_period) * bob_height


func get_interactable() -> Interactable:
	return _interactable


## Taken (`taken`: rises and fades) or collapsed (shrinks and fades).
func finish(taken: bool) -> void:
	if used:
		return
	used = true
	_interactable.enabled = false
	var tween: Tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	if taken:
		tween.tween_property(_icon, ^"position:y", _icon.position.y - 24.0, vanish_time)
	else:
		tween.tween_property(_icon, ^"scale", Vector2.ZERO, vanish_time)
	tween.tween_property(_icon, ^"modulate:a", 0.0, vanish_time)


func _on_interacted(player: Player) -> void:
	if not used:
		chosen.emit(self, player)
