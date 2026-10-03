@tool
class_name DebugBlock
extends StaticBody2D
## Rectangular platform for debug scenes: its collision and its drawing follow
## `size`, also in the editor. Solid (world) or one-way (one_way_platforms).
## The position is the top-left corner.

## Height drawn for the top line of one-way platforms.
const ONE_WAY_LINE: float = 2.5
const ONE_WAY_DASH: float = 10.0

@export var size: Vector2 = Vector2(128, 16):
	set(value):
		size = value
		_update()
@export var one_way: bool = false:
	set(value):
		one_way = value
		_update()
@export var color: Color = Palette.LAYER_K_ACCENT:
	set(value):
		color = value
		queue_redraw()

var _shape: CollisionShape2D = null


func _ready() -> void:
	_update()


func _draw() -> void:
	if one_way:
		draw_dashed_line(
			Vector2(0.0, 1.0),
			Vector2(size.x, 1.0),
			color * Color(2.0, 2.0, 2.0),
			ONE_WAY_LINE,
			ONE_WAY_DASH
		)
		return
	draw_rect(Rect2(Vector2.ZERO, size), Palette.VOID_3)
	draw_rect(Rect2(Vector2.ZERO, size), color, false, 1.0)
	draw_line(Vector2(2.0, 0.5), Vector2(size.x - 2.0, 0.5), color * Color(2.0, 2.0, 2.0), 2.5)


func _update() -> void:
	if not is_node_ready():
		return
	if _shape == null:
		_shape = CollisionShape2D.new()
		_shape.shape = RectangleShape2D.new()
		add_child(_shape, false, Node.INTERNAL_MODE_FRONT)
	var rectangle: RectangleShape2D = _shape.shape
	rectangle.size = size
	_shape.position = size / 2.0
	_shape.one_way_collision = one_way
	collision_mask = 0
	collision_layer = 0
	set_collision_layer_value(
		PhysicsLayers.ONE_WAY_PLATFORMS if one_way else PhysicsLayers.WORLD, true
	)
	queue_redraw()
