class_name OrbitalBackground
extends CanvasLayer
## Screen-filling background of a layer: the shader of its orbital
## (orbital_background.gdshader) with the layer's colors from Palette. It stays
## fixed on the screen, behind the world, like the atom the player climbs.

const LAYER_COLORS: Dictionary[String, Array] = {
	"K": [Palette.LAYER_K_TINT, Palette.LAYER_K_ACCENT],
}

@export var layer_code: String = "K":
	set(value):
		layer_code = value
		if is_node_ready():
			_apply_colors()

@onready var _rect: ColorRect = %Rect


func _ready() -> void:
	_apply_colors()


func _apply_colors() -> void:
	var material: ShaderMaterial = _rect.material
	var colors: Array = LAYER_COLORS.get(layer_code, LAYER_COLORS["K"])
	material.set_shader_parameter(&"void_color", Palette.VOID)
	material.set_shader_parameter(&"tint", colors[0])
	material.set_shader_parameter(&"accent", colors[1])
