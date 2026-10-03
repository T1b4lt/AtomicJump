class_name CommonChest
extends Chest
## Quantum well (pozo cuántico, `chest`): opens with the interact action by
## paying photons, its "excitation energy". It costs `base_cost` in Layer K and
## `cost_per_layer` more per layer. Its energy levels light up when paid.

@export var base_cost: int = 5
@export var cost_per_layer: int = 5
@export var light_time: float = 0.25

@onready var _sprite: Sprite2D = %Sprite
@onready var _lit: Sprite2D = %Lit
@onready var _price_label: Label = %PriceLabel
@onready var _interactable: Interactable = %Interactable


func _ready() -> void:
	_lit.modulate.a = 0.0
	_price_label.text = "%d γ" % get_cost()
	_interactable.prompt = tr("INTERACT_OPEN")
	_interactable.interacted.connect(_on_interacted)


func get_cost() -> int:
	return base_cost + cost_per_layer * layer_index


## Pays its cost from the player's run and opens. Returns whether it opened.
func try_open(player: Player) -> bool:
	if is_open or player.run == null or not player.run.spend_coins(get_cost()):
		_flash_price()
		return false
	open()
	return true


func get_interactable() -> Interactable:
	return _interactable


func _play_open() -> void:
	_interactable.enabled = false
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_lit, ^"modulate:a", 1.0, light_time)
	tween.tween_property(_price_label, ^"modulate:a", 0.0, light_time)
	tween.chain().tween_property(_sprite, ^"modulate:a", 0.45, light_time)
	tween.parallel().tween_property(_lit, ^"modulate:a", 0.0, light_time * 2.0)


## Not enough photons: the price flashes.
func _flash_price() -> void:
	if is_open:
		return
	var tween: Tween = create_tween()
	_price_label.modulate = Palette.DANGER
	tween.tween_property(_price_label, ^"modulate", Color.WHITE, light_time * 2.0)


func _on_interacted(player: Player) -> void:
	try_open(player)
