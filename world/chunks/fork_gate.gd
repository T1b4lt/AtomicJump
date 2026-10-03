class_name ForkGate
extends Node2D
## Exit of a fork chunk (docs/03-run.md#bifurcaciones-estilo-hades): a dashed
## line of the layer's accent across the opening, with the icon of its branch's
## reward floating in it. Crossing it upwards emits `entered`; the chunk then
## collapses the other exit: its wall closes from the sides, its icon shrinks
## and dissolves into fragments and a blocker shuts the way. The origin is the
## exit marker, on the top edge of the chunk.

signal entered

const REWARD_ICONS: Dictionary[StringName, Texture2D] = {
	LayerData.REWARD_COINS: preload("res://assets/generated/rewards/reward_coins.svg"),
	LayerData.REWARD_KEY: preload("res://assets/generated/rewards/reward_key.svg"),
}
## Thickness of a fork's ceiling: the gate fills it when it collapses.
const CEILING_THICKNESS: float = Chunk.TILE * 2.0
## Height of the trigger, just above the top edge (it is crossed going up).
const TRIGGER_HEIGHT: float = 24.0
const LINE_WIDTH: float = 2.5
const LINE_DASH: float = 10.0
const WALL_BORDER: float = 1.5
## Color multiplier over 1 that makes the line glow (docs/13-art-style.md).
const GLOW: float = 2.0
## The icon textures are imported at double size.
const ICON_SCALE: float = 0.5

@export var width: float = Chunk.OPENING_TILES * Chunk.TILE
@export var color: Color = Palette.LAYER_K_ACCENT
## Seconds the collapse takes (docs/13-art-style.md#tiempos-de-referencia).
@export var collapse_time: float = 0.25
@export var choose_time: float = 0.4
@export var icon_bob_height: float = 4.0
@export var icon_bob_period: float = 1.6

## Reward of the branch behind this exit (LayerData.REWARD_*).
var reward: StringName = &""
var collapsed: bool = false
var chosen: bool = false
## How far the walls have closed: 0 open, 1 closed.
var closing: float = 0.0:
	set(value):
		closing = value
		queue_redraw()
var _time: float = 0.0

@onready var _trigger: Area2D = %Trigger
@onready var _trigger_shape: CollisionShape2D = %TriggerShape
@onready var _blocker: StaticBody2D = %Blocker
@onready var _blocker_shape: CollisionShape2D = %BlockerShape
@onready var _icon: Sprite2D = %Icon
@onready var _fragments: CPUParticles2D = %Fragments


func _ready() -> void:
	_trigger.collision_layer = 0
	_trigger.collision_mask = 0
	_trigger.set_collision_mask_value(PhysicsLayers.PLAYER, true)
	_trigger_shape.shape = _rectangle(Vector2(width, TRIGGER_HEIGHT))
	_trigger_shape.position = Vector2(0.0, -TRIGGER_HEIGHT / 2.0)
	_blocker.collision_layer = 0
	_blocker.collision_mask = 0
	_blocker.set_collision_layer_value(PhysicsLayers.WORLD, true)
	_blocker_shape.shape = _rectangle(Vector2(width, CEILING_THICKNESS))
	_blocker_shape.position = Vector2(0.0, CEILING_THICKNESS / 2.0)
	_blocker_shape.disabled = true
	_icon.texture = REWARD_ICONS.get(reward)
	_icon.scale = Vector2.ONE * ICON_SCALE
	_icon.position = Vector2(0.0, CEILING_THICKNESS / 2.0)
	_fragments.position = _icon.position
	_fragments.color = color * GLOW


func _process(delta: float) -> void:
	_time += delta
	if not collapsed and not chosen:
		var bob: float = sin(TAU * _time / icon_bob_period) * icon_bob_height
		_icon.position.y = CEILING_THICKNESS / 2.0 + bob


func _draw() -> void:
	var half: float = width / 2.0
	if closing < 1.0:
		var line_y: float = CEILING_THICKNESS
		draw_dashed_line(
			Vector2(-half, line_y), Vector2(half, line_y), color * GLOW, LINE_WIDTH, LINE_DASH
		)
	if closing <= 0.0:
		return
	var wall_width: float = half * closing
	for rect: Rect2 in [
		Rect2(-half, 0.0, wall_width, CEILING_THICKNESS),
		Rect2(half - wall_width, 0.0, wall_width, CEILING_THICKNESS),
	]:
		draw_rect(rect, Palette.VOID_2)
		draw_rect(rect, Palette.INK_DIM, false, WALL_BORDER)


## Shuts this exit: the walls close from the sides and the icon dissolves.
func collapse() -> void:
	if collapsed:
		return
	collapsed = true
	_trigger.set_deferred(&"monitoring", false)
	_blocker_shape.set_deferred(&"disabled", false)
	_fragments.emitting = true
	var tween: Tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, ^"closing", 1.0, collapse_time)
	tween.tween_property(_icon, ^"scale", Vector2.ZERO, collapse_time)
	tween.tween_property(_icon, ^"modulate:a", 0.0, collapse_time)


## This exit was taken: its icon rises and fades out.
func choose() -> void:
	if chosen:
		return
	chosen = true
	_trigger.set_deferred(&"monitoring", false)
	var tween: Tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	tween.tween_property(_icon, ^"position:y", _icon.position.y - Chunk.TILE, choose_time)
	tween.tween_property(_icon, ^"modulate:a", 0.0, choose_time)


func is_blocking() -> bool:
	return not _blocker_shape.disabled


static func _rectangle(size: Vector2) -> RectangleShape2D:
	var shape := RectangleShape2D.new()
	shape.size = size
	return shape


func _on_trigger_body_entered(body: Node2D) -> void:
	if body is Player and not collapsed and not chosen:
		entered.emit()
