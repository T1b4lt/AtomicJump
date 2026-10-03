class_name ShopStand
extends Node2D
## One stand of an Exchange: the goods (an item's icon or a pickup), its price
## and the interact prompt. The Shop decides what buying it does.

signal buy_requested(stand: ShopStand, player: Player)

const PICKUP_ICONS: Dictionary[ShopInventory.Goods, Texture2D] = {
	ShopInventory.Goods.HEAL: preload("res://assets/generated/pickups/heal.svg"),
	ShopInventory.Goods.KEY: preload("res://assets/generated/pickups/positron.svg"),
	ShopInventory.Goods.REROLL: preload("res://assets/generated/icons/shop_reroll.svg"),
}
const NAME_KEYS: Dictionary[ShopInventory.Goods, String] = {
	ShopInventory.Goods.HEAL: "SHOP_HEAL",
	ShopInventory.Goods.KEY: "SHOP_KEY",
	ShopInventory.Goods.REROLL: "SHOP_REROLL",
}
## Scale of the pickup sprites on a stand (their textures are imported at double size).
const PICKUP_SCALE: float = 0.75
const REROLL_SIZE: float = 40.0
## Texture px of an icon (64 px imported at double size).
const ICON_TEXTURE_SIZE: float = 128.0

@export var bob_height: float = 3.0
@export var bob_period: float = 1.8

var offer: ShopInventory.Offer = null
var _time: float = 0.0

@onready var _icon: ItemIcon = %Icon
@onready var _sprite: Sprite2D = %Sprite
@onready var _goods: Node2D = %Goods
@onready var _price_label: Label = %PriceLabel
@onready var _interactable: Interactable = %Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	_goods.position.y = -36.0 + sin(TAU * _time / bob_period) * bob_height


func set_offer(new_offer: ShopInventory.Offer) -> void:
	offer = new_offer
	if is_node_ready():
		_refresh()


func get_interactable() -> Interactable:
	return _interactable


## The goods were bought: the stand empties.
func mark_sold() -> void:
	offer.sold = true
	_refresh()


## Not enough photons: the price flashes.
func flash_price() -> void:
	_price_label.modulate = Palette.DANGER
	create_tween().tween_property(_price_label, ^"modulate", Color.WHITE, 0.5)


func _refresh() -> void:
	var has_goods: bool = offer != null and not offer.sold
	_goods.visible = has_goods
	_price_label.visible = has_goods
	_interactable.enabled = has_goods
	if not has_goods:
		return
	_price_label.text = "%d γ" % offer.price
	var is_item: bool = offer.goods == ShopInventory.Goods.ITEM
	_icon.visible = is_item
	_sprite.visible = not is_item
	if is_item:
		_icon.set_item(offer.item)
		_interactable.prompt = tr(offer.item.get_name_key())
	else:
		_sprite.texture = PICKUP_ICONS[offer.goods]
		var is_reroll: bool = offer.goods == ShopInventory.Goods.REROLL
		_sprite.scale = (
			Vector2.ONE * (REROLL_SIZE / ICON_TEXTURE_SIZE if is_reroll else PICKUP_SCALE)
		)
		_interactable.prompt = tr(NAME_KEYS[offer.goods])


func _on_interacted(player: Player) -> void:
	buy_requested.emit(self, player)
