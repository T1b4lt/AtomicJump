class_name Pickup
extends Area2D
## Base of the pickups (docs/06-economy.md): collected when the player touches
## it, if can_collect() allows it (a heal quantum waits while coherence is
## full, and is taken as soon as it is not). Magnetic pickups (photons) fly to
## the player once it is within its pickup radius (Stats.PICKUP_RADIUS), with
## an ease-in. The sprite (%Sprite) bobs and glows.

signal collected

## Brightness multiplier (HDR) of the sprite, so it glows.
const GLOW: float = 1.5

@export var magnetic: bool = false
## Acceleration (px/s²) towards the player once attracted (~200 ms from the radius).
@export var attract_acceleration: float = 2400.0
@export var bob_height: float = 3.0
@export var bob_period: float = 1.4

var is_collected: bool = false
## Whether it is flying towards the player.
var attracted: bool = false
var _target: Player = null
var _speed: float = 0.0
var _time: float = 0.0
## A player touching it while it could not be collected (retried every frame).
var _waiting: Player = null

@onready var _sprite: Node2D = %Sprite


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(PhysicsLayers.PICKUPS, true)
	set_collision_mask_value(PhysicsLayers.PLAYER, true)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_sprite.self_modulate = Color(GLOW, GLOW, GLOW)
	# Desynchronise the bobbing of neighbouring pickups (cosmetic only)
	_time = fposmod(global_position.x * 0.013 + global_position.y * 0.007, bob_period)


func _process(delta: float) -> void:
	_time += delta
	_sprite.position.y = sin(TAU * _time / bob_period) * bob_height


func _physics_process(delta: float) -> void:
	if is_collected:
		return
	if _waiting != null:
		if is_instance_valid(_waiting) and overlaps_body(_waiting):
			try_collect(_waiting)
		else:
			_waiting = null
	if magnetic:
		_attract(delta)


## Whether this player can take it now.
func can_collect(_player: Player) -> bool:
	return true


## Collects it if the player can take it. Returns whether it was collected.
func try_collect(player: Player) -> bool:
	if is_collected or not can_collect(player):
		return false
	is_collected = true
	_waiting = null
	_apply(player)
	collected.emit()
	queue_free()
	return true


## What taking it does (the subclasses).
func _apply(_player: Player) -> void:
	pass


func _attract(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(Player.GROUP) as Player
		if _target == null:
			return
	if not attracted:
		var radius: float = _target.get_pickup_radius()
		if global_position.distance_squared_to(_target.global_position) > radius * radius:
			return
		attracted = true
	_speed += attract_acceleration * delta
	global_position = global_position.move_toward(_target.global_position, _speed * delta)


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player != null and not try_collect(player):
		_waiting = player


func _on_body_exited(body: Node2D) -> void:
	if body == _waiting:
		_waiting = null
