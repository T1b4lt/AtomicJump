extends GdUnitTestSuite

## Tests de los pinchos: daño continuo mientras hay contacto.

const SPIKE_SCENE: PackedScene = preload("res://world/hazards/spike/spike.tscn")
const PROTAGONIST_SCENE: PackedScene = preload("res://actors/player/player.tscn")

var _saved_hp: float


func before_test() -> void:
	_saved_hp = game.pr_hp
	game.pr_hp = 100.0


func after_test() -> void:
	game.pr_hp = _saved_hp


func test_damages_on_contact() -> void:
	var spike: Spike = auto_free(SPIKE_SCENE.instantiate())
	var protagonist: Player = auto_free(PROTAGONIST_SCENE.instantiate())
	spike._on_body_entered(protagonist)
	assert_float(game.pr_hp).is_equal(100.0 - Spike.SPIKE_DAMAGE * game.pr_defense)


func test_keeps_damaging_while_in_contact() -> void:
	var spike: Spike = auto_free(SPIKE_SCENE.instantiate())
	var protagonist: Player = auto_free(PROTAGONIST_SCENE.instantiate())
	var hit: float = Spike.SPIKE_DAMAGE * game.pr_defense
	spike._on_body_entered(protagonist)

	# Still invulnerable: no extra damage
	spike._physics_process(0.0)
	assert_float(game.pr_hp).is_equal(100.0 - hit)

	# Invulnerability over and still in contact: damaged again
	protagonist._update_invulnerability(Player.INVULNERABILITY_TIME)
	spike._physics_process(0.0)
	assert_float(game.pr_hp).is_equal(100.0 - 2.0 * hit)


func test_stops_damaging_after_leaving() -> void:
	var spike: Spike = auto_free(SPIKE_SCENE.instantiate())
	var protagonist: Player = auto_free(PROTAGONIST_SCENE.instantiate())
	var hit: float = Spike.SPIKE_DAMAGE * game.pr_defense
	spike._on_body_entered(protagonist)
	spike._on_body_exited(protagonist)

	protagonist._update_invulnerability(Player.INVULNERABILITY_TIME)
	spike._physics_process(0.0)
	assert_float(game.pr_hp).is_equal(100.0 - hit)
	assert_bool(spike.is_physics_processing()).is_false()
