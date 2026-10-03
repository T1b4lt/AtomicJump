class_name Projectile
extends Hitbox
## A shot (docs/04-player.md#disparo): flies straight from a ProjectileSpec,
## hits the Hurtboxes of the other team once each, and stops at the first one
## (plus `pierce` more), on a wall or solid platform (it goes through one-way
## platforms) or when it has flown its range. Walls are checked with a ray
## along each step, so fast shots never go through thin platforms. On impact
## it plays an ImpactEffect and frees itself when it ends.

## The projectile stopped: `position` is where (on a wall or on a target).
signal impacted(position: Vector2)

## Group of the enemies' projectiles (the Colapso operator destroys them).
const ENEMY_GROUP: StringName = &"enemy_projectiles"

## Seconds it takes to fade out at the end of its range.
const FADE_TIME: float = 0.08
## Brightness multiplier (HDR) of the sprite, so it glows.
const GLOW: float = 1.6

var spec: ProjectileSpec = null
var velocity: Vector2 = Vector2.ZERO
## Distance flown so far, in px.
var travelled: float = 0.0
var _done: bool = false
## Sideways offset of the wave from the straight path.
var _wave_offset: Vector2 = Vector2.ZERO

@onready var _sprite: Sprite2D = %Sprite


func _ready() -> void:
	super()
	continuous = false
	set_physics_process(true)
	if spec != null and spec.team == ProjectileSpec.Team.ENEMY:
		add_to_group(ENEMY_GROUP)
	hit_landed.connect(_on_hit_landed)
	_sprite.self_modulate = Color(GLOW, GLOW, GLOW)


## Sets the projectile up before it enters the tree: its spec, where it starts,
## its direction and the velocity of the shooter that it inherits.
func launch(
	p_spec: ProjectileSpec,
	origin: Vector2,
	direction: Vector2,
	inherited_velocity: Vector2 = Vector2.ZERO
) -> void:
	spec = p_spec
	position = origin
	velocity = direction.normalized() * spec.speed + inherited_velocity
	rotation = velocity.angle()
	scale = Vector2(spec.size, spec.size)
	damage = spec.damage
	knockback = spec.knockback
	source_id = spec.source_id
	statuses = spec.statuses.duplicate()
	kind = DamageInfo.Kind.PROJECTILE
	max_hits = spec.pierce + 1
	collision_layer = 0
	collision_mask = 0
	if spec.team == ProjectileSpec.Team.PLAYER:
		set_collision_layer_value(PhysicsLayers.PLAYER_PROJECTILES, true)
		set_collision_mask_value(PhysicsLayers.ENEMIES, true)
	else:
		set_collision_layer_value(PhysicsLayers.ENEMY_PROJECTILES, true)
		set_collision_mask_value(PhysicsLayers.PLAYER, true)


func _physics_process(delta: float) -> void:
	if _done or spec == null:
		return
	var step: Vector2 = velocity * delta
	var previous_offset: Vector2 = _wave_offset
	_wave_offset = wave_offset_at(travelled + step.length())
	var motion: Vector2 = step + _wave_offset - previous_offset
	var wall: Dictionary = _cast_to_wall(motion)
	if not wall.is_empty():
		var hit_point: Vector2 = wall[&"position"]
		global_position = hit_point
		_impact(-velocity.normalized())
		return
	global_position += motion
	travelled += step.length()
	if travelled >= spec.attack_range:
		_fade_out()


## Whether it already stopped (impact or end of range).
func is_done() -> bool:
	return _done


## Sideways offset of a wavy path after flying `distance` px (ZERO if straight).
func wave_offset_at(distance: float) -> Vector2:
	if spec == null or spec.wave_amplitude <= 0.0 or velocity == Vector2.ZERO:
		return Vector2.ZERO
	var seconds: float = distance / velocity.length()
	var side: Vector2 = velocity.normalized().orthogonal()
	return side * spec.wave_amplitude * sin(TAU * spec.wave_frequency * seconds)


## Stops it at once with its impact (the Colapso operator).
func destroy() -> void:
	if not _done:
		_impact(-velocity.normalized())


## Result of a ray from the projectile along `motion` against walls and solid
## platforms (empty if nothing is in the way).
func _cast_to_wall(motion: Vector2) -> Dictionary:
	if motion == Vector2.ZERO:
		return {}
	var query := PhysicsRayQueryParameters2D.create(
		global_position, global_position + motion, 1 << (PhysicsLayers.WORLD - 1)
	)
	query.hit_from_inside = false
	return get_world_2d().direct_space_state.intersect_ray(query)


func _impact(facing: Vector2) -> void:
	_stop()
	_sprite.visible = false
	var effect := ImpactEffect.new()
	effect.direction = facing
	effect.color_a = Palette.PLAYER if spec.team == ProjectileSpec.Team.PLAYER else Palette.DANGER
	effect.color_b = Palette.INK
	effect.top_level = true
	add_child(effect)
	effect.global_position = global_position
	effect.finished.connect(queue_free)
	impacted.emit(global_position)


func _fade_out() -> void:
	_stop()
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, ^"modulate:a", 0.0, FADE_TIME)
	tween.finished.connect(queue_free)


func _stop() -> void:
	_done = true
	velocity = Vector2.ZERO
	set_enabled(false)


func _on_hit_landed(_hurtbox: Hurtbox, _info: DamageInfo) -> void:
	if is_spent() and not _done:
		_impact(-velocity.normalized())
