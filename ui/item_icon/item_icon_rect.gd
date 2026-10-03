class_name ItemIconRect
extends TextureRect
## An item's icon in the UI: the generated frame and glyph with the rarity gem
## under it (docs/13-art-style.md#iconografía). The world version is ItemIcon.

## Size of the icon in px (64: full size; the texture is 64 × 72 with the gem).
@export var icon_size: float = 40.0:
	set(value):
		icon_size = value
		_layout()

var _gem := TextureRect.new()


func _init() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gem.texture = ItemIcon.GEM_TEXTURE
	_gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gem)
	_layout()


## Shows an icon; `rarity` < 0 hides the gem.
func set_icon(icon: Texture2D, rarity: int = -1) -> void:
	texture = icon
	_gem.visible = rarity >= 0
	if rarity >= 0:
		_gem.self_modulate = ItemRarity.get_color(rarity as ItemData.Rarity)


func set_item(item: ItemData) -> void:
	if item == null:
		set_icon(null)
	else:
		set_icon(item.icon, item.rarity)


func _layout() -> void:
	# The texture is 64 × 72 icon units: the gem is 10 units, 31 below the center
	var unit: float = icon_size / 64.0
	custom_minimum_size = Vector2(64.0, 72.0) * unit
	size = custom_minimum_size
	_gem.size = Vector2(10.0, 10.0) * unit
	_gem.position = Vector2(32.0 - 5.0, 36.0 + ItemIcon.GEM_OFFSET - 5.0) * unit
