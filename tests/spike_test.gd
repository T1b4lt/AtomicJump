extends GdUnitTestSuite

## Tests de los pinchos: un Hitbox continuo que daña mientras hay contacto.

const SPIKE_SCENE: PackedScene = preload("res://world/hazards/spike/spike.tscn")
const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")
const WILAS: CharacterData = preload("res://data/characters/wilas.tres")


func test_damages_on_contact() -> void:
	var spike: Spike = _spike()
	var player: Player = _player()
	spike._on_area_entered(player.get_hurtbox())
	assert_float(player.run.hp).is_equal(100.0 - spike.damage)


func test_keeps_damaging_while_in_contact() -> void:
	var spike: Spike = _spike()
	var player: Player = _player()
	spike._on_area_entered(player.get_hurtbox())

	# Still invulnerable: no extra damage
	spike._physics_process(0.0)
	assert_float(player.run.hp).is_equal(100.0 - spike.damage)

	# Invulnerability over and still in contact: damaged again
	player._update_invulnerability(player.invulnerability_time)
	spike._physics_process(0.0)
	assert_float(player.run.hp).is_equal(100.0 - 2.0 * spike.damage)


func test_stops_damaging_after_leaving() -> void:
	var spike: Spike = _spike()
	var player: Player = _player()
	spike._on_area_entered(player.get_hurtbox())
	spike._on_area_exited(player.get_hurtbox())

	player._update_invulnerability(player.invulnerability_time)
	spike._physics_process(0.0)
	assert_float(player.run.hp).is_equal(100.0 - spike.damage)
	assert_bool(spike.is_physics_processing()).is_false()


func test_is_the_cause_of_death() -> void:
	var spike: Spike = _spike()
	var player: Player = _player()
	player.run.take_damage(player.run.hp - 1.0)
	spike._on_area_entered(player.get_hurtbox())
	assert_bool(player.run.is_dead()).is_true()
	assert_str(player.run.counters.death_cause).is_equal(Spike.SOURCE_ID)


func test_is_a_hazard_that_detects_the_player() -> void:
	var spike: Spike = _spike()
	assert_bool(spike.get_collision_layer_value(PhysicsLayers.HAZARDS)).is_true()
	assert_bool(spike.get_collision_mask_value(PhysicsLayers.PLAYER)).is_true()
	assert_int(spike.kind).is_equal(DamageInfo.Kind.HAZARD)


func _spike() -> Spike:
	var spike: Spike = auto_free(SPIKE_SCENE.instantiate())
	add_child(spike)
	return spike


func _player() -> Player:
	var player: Player = auto_free(PLAYER_SCENE.instantiate())
	add_child(player)
	player.set_physics_process(false)
	player.bind_run(RunState.new("A", WILAS))
	return player
