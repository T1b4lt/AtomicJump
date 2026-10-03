class_name Enemy
extends CharacterBody2D
## Base of every enemy (docs/09-enemies.md): an EnemyData with its stats, a
## HealthComponent, a Hurtbox that receives the player's shots, a contact Hitbox
## that hurts the player, StatusEffects and a behaviour (an EnemyBehavior child
## named Behavior) that moves it. The body collides only with the world (it is
## on no physics layer): the player and the projectiles meet its areas.
## The chunk that spawns it calls setup() with its slot address, which seeds
## its decisions ("ai" domain) and its drops. When it dies it emits `died`,
## plays a bubble chamber trace and frees itself; the chunk drops its loot and
## its decay product. With a `lifetime` (decay products) it vanishes when it ends.

signal died(enemy: Enemy)

## Group of the living enemies (operators look for them on screen).
const GROUP: StringName = &"enemies"

## Gravity of the walking enemies, in px/s².
const GRAVITY: float = 1400.0
const MAX_FALL_SPEED: float = 820.0
## How fast the knockback of a hit fades (per second, exponential).
const KNOCKBACK_DAMPING: float = 10.0
## Hit flash: brightness (HDR) and seconds.
const FLASH_BRIGHTNESS: float = 3.0
const FLASH_TIME: float = 0.1
## Breathing of the body: scale amplitude and seconds per cycle ("nothing alive is still").
const BREATHE_AMPLITUDE: float = 0.04
const BREATHE_PERIOD: float = 1.2
## Brightness multiplier (HDR) of the body, so it glows.
const GLOW: float = 1.35
## Seconds a decay product takes to fade away when its lifetime ends.
const VANISH_TIME: float = 0.3

@export var data: EnemyData = null
## Radius of the death trace, in px.
@export var death_trace_radius: float = 26.0

## Address of the slot it spawned in ([layer, branch, index, slot]).
var address: Array = []
## Layer index, for the stat scaling.
var layer_index: int = 0
## Its own decisions (orbit phase, patrol direction…), seeded by its address.
var ai_rng := RandomNumberGenerator.new()
## Seconds left before vanishing (0: it lives until killed).
var lifetime: float = 0.0
## Velocity added by the knockback of the hits; it fades out.
var knockback_velocity: Vector2 = Vector2.ZERO
## The player, if any (found by its group).
var target: Node2D = null
var _time: float = 0.0
var _dying: bool = false
var _flash_tween: Tween = null

@onready var health: HealthComponent = %Health
@onready var hurtbox: Hurtbox = %Hurtbox
@onready var contact_hitbox: Hitbox = %ContactHitbox
@onready var statuses: StatusEffects = %StatusEffects
## Flashes when hit; its child Body breathes and takes the status tint.
@onready var visual: Node2D = %Visual
@onready var body: Node2D = %Body
@onready var behavior: EnemyBehavior = get_node_or_null(^"Behavior") as EnemyBehavior


## Gives the enemy its slot address before it enters the tree.
func setup(p_address: Array, rng: WorldRng, p_layer_index: int = 0) -> void:
	address = p_address
	layer_index = p_layer_index
	if rng != null:
		ai_rng = rng.local_rng(&"ai", address)


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(PhysicsLayers.WORLD, true)
	set_collision_mask_value(PhysicsLayers.ONE_WAY_PLATFORMS, true)
	health.setup(data.get_max_hp(layer_index))
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	contact_hitbox.damage = data.get_contact_damage(layer_index)
	contact_hitbox.source_id = data.id
	contact_hitbox.kind = DamageInfo.Kind.CONTACT
	visual.modulate = Color(GLOW, GLOW, GLOW)
	if behavior != null:
		behavior.setup(self)


func _physics_process(delta: float) -> void:
	if _dying:
		return
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(Player.GROUP) as Node2D
	if behavior != null:
		behavior.physics_step(self, delta)
	knockback_velocity = knockback_velocity * exp(-KNOCKBACK_DAMPING * delta)
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			vanish()


func _process(delta: float) -> void:
	_time += delta * get_time_scale()
	var breathe: float = 1.0 + BREATHE_AMPLITUDE * sin(TAU * _time / BREATHE_PERIOD)
	body.scale = Vector2(breathe, 1.0 / breathe)
	body.modulate = statuses.get_tint()


## Multiplier of its speed and timers (status effects slow or root it).
func get_time_scale() -> float:
	return statuses.get_speed_multiplier()


func is_dying() -> bool:
	return _dying


## Px from the origin to the target (Vector2.INF without one).
func to_target() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.INF
	return target.global_position - global_position


## Falls with gravity (walking enemies call it from their behaviour).
func apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)


## Whether there is floor ahead in `direction` (-1 or 1), `ahead` px in front.
func has_floor_ahead(direction: float, ahead: float, depth: float = 12.0) -> bool:
	var from: Vector2 = global_position + Vector2(direction * ahead, -4.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, depth + 4.0))
	query.collision_mask = collision_mask
	query.hit_from_inside = true
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Whether nothing solid is between the enemy (raised by `eye_height`) and a point.
func can_see(point: Vector2, eye_height: float = 0.0) -> bool:
	var from: Vector2 = global_position + Vector2(0.0, -eye_height)
	var query := PhysicsRayQueryParameters2D.create(from, point, 1 << (PhysicsLayers.WORLD - 1))
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Warning before an attack: the body flickers for `duration` seconds.
func play_warning(duration: float) -> void:
	var tween: Tween = create_tween().set_loops(maxi(1, roundi(duration / 0.1)))
	tween.tween_property(visual, ^"modulate", Color(GLOW * 2.0, GLOW * 2.0, GLOW * 2.0), 0.05)
	tween.tween_property(visual, ^"modulate", Color(GLOW, GLOW, GLOW), 0.05)


## Fades away without dying (decay products at the end of their lifetime).
func vanish() -> void:
	if _dying:
		return
	_dying = true
	_disable_combat()
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, VANISH_TIME)
	tween.finished.connect(queue_free)


func _disable_combat() -> void:
	if behavior != null:
		behavior.stop(self)
	hurtbox.set_enabled(false)
	contact_hitbox.set_enabled(false)
	statuses.clear()
	velocity = Vector2.ZERO


func _on_hit_received(info: DamageInfo) -> void:
	if _dying:
		return
	if info.kind != DamageInfo.Kind.STATUS:
		var push: Vector2 = info.direction_from_source(global_position)
		knockback_velocity += push * info.knockback * (1.0 - data.knockback_resistance)
		_flash()
		Events.enemy_damaged.emit(data.id)
	for status: StatusEffectData in info.statuses:
		statuses.apply(status)


func _flash() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	var bright: float = GLOW * FLASH_BRIGHTNESS
	visual.modulate = Color(bright, bright, bright)
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, ^"modulate", Color(GLOW, GLOW, GLOW), FLASH_TIME)


func _on_died(_info: DamageInfo) -> void:
	_dying = true
	_disable_combat()
	visual.visible = false
	Events.enemy_killed.emit(data.id, global_position)
	died.emit(self)
	var trace := ImpactEffect.new()
	trace.radius = death_trace_radius
	trace.duration = 0.5
	trace.color_a = Palette.NEGATIVE
	trace.color_b = Palette.POSITIVE
	trace.position = visual.position + body.position
	add_child(trace)
	trace.finished.connect(queue_free)
