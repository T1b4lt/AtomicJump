class_name ItemIcon
extends Node2D
## An item's icon in the world (docs/13-art-style.md#iconografía): the
## generated frame and glyph, and the rarity gem tinted with its color under
## it. The icon textures are 64 px icons imported at double size.

const GEM_TEXTURE: Texture2D = preload("res://assets/generated/icons/icon_gem.svg")
## Px of the gem's center below the icon's center, in icon units (64 px icon).
const GEM_OFFSET: float = 31.0
## Brightness multiplier (HDR) of the gem, so it glows a little.
const GEM_GLOW: float = 1.6

## Size of the icon in the world, in px (64: full size).
@export var size: float = 44.0:
	set(value):
		size = value
		_layout()

var _icon := Sprite2D.new()
var _gem := Sprite2D.new()


func _init() -> void:
	add_child(_icon)
	add_child(_gem)
	_gem.texture = GEM_TEXTURE
	_layout()


## Shows an icon; `rarity` < 0 hides the gem.
func set_icon(texture: Texture2D, rarity: int = -1) -> void:
	_icon.texture = texture
	_gem.visible = rarity >= 0
	if rarity >= 0:
		var color: Color = ItemRarity.get_color(rarity as ItemData.Rarity)
		_gem.self_modulate = Color(color.r * GEM_GLOW, color.g * GEM_GLOW, color.b * GEM_GLOW)


func set_item(item: ItemData) -> void:
	if item == null:
		set_icon(null)
	else:
		set_icon(item.icon, item.rarity)


func get_texture() -> Texture2D:
	return _icon.texture


func _layout() -> void:
	# Textures are imported at double size: 128 texture px are `size` world px
	var texture_scale: float = size / 128.0
	_icon.scale = Vector2.ONE * texture_scale
	_gem.scale = Vector2.ONE * texture_scale
	_gem.position = Vector2(0.0, GEM_OFFSET * size / 64.0)
