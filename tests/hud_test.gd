extends GdUnitTestSuite

## Tests del HUD: se actualiza con las señales de la partida, sin _process.

const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")
const WILAS: CharacterData = preload("res://data/characters/wilas.tres")
const MASS: ItemData = preload("res://data/items/effective_mass.tres")
const ZENO: ItemData = preload("res://data/items/zeno_effect.tres")


func test_does_not_refresh_every_frame() -> void:
	var hud: Hud = _add_hud()
	assert_bool(hud.is_processing()).is_false()


func test_shows_the_run_on_bind() -> void:
	var hud: Hud = _add_hud()
	var run := RunState.new("K7QX-2MPA", WILAS)
	hud.bind_run(run)
	assert_str(_text(hud, "%SeedValue")).is_equal("K7QX-2MPA · g%d" % WorldRng.GENERATION_VERSION)
	assert_str(_text(hud, "%CoinsValue")).is_equal("0")
	assert_bool(hud.is_active_shown()).is_false()


func test_updates_on_run_signals() -> void:
	var hud: Hud = _add_hud()
	var run := RunState.new("A", WILAS)
	hud.bind_run(run)
	run.add_coins(3)
	run.add_keys(1)
	run.set_altitude(4.5)
	assert_str(_text(hud, "%CoinsValue")).is_equal("3")
	assert_str(_text(hud, "%KeysValue")).is_equal("1")
	assert_str(_text(hud, "%AltitudeValue")).is_equal("4.50")


func test_shows_a_banner_for_every_item_gained() -> void:
	var hud: Hud = _add_hud()
	var run := RunState.new("A", WILAS)
	hud.bind_run(run)
	run.add_item(MASS)
	assert_str(hud.get_banner_title()).is_equal(tr(MASS.get_name_key()))


func test_shows_the_operator_and_its_charge() -> void:
	var hud: Hud = _add_hud()
	var run := RunState.new("A", WILAS)
	hud.bind_run(run)
	run.add_item(ZENO)
	assert_bool(hud.is_active_shown()).is_true()
	var charge: ProgressBar = hud.get_node("%ActiveCharge")
	assert_float(charge.value).is_equal(float(ZENO.charge_chunks))
	run.build.active_charge = 0
	run.build.on_chunk_entered(1)
	assert_float(charge.value).is_equal(1.0)


func test_rebinding_ignores_the_old_run() -> void:
	var hud: Hud = _add_hud()
	var old_run := RunState.new("A", WILAS)
	hud.bind_run(old_run)
	hud.bind_run(RunState.new("B", WILAS))
	old_run.add_coins(7)
	assert_str(_text(hud, "%CoinsValue")).is_equal("0")


func test_shows_the_distance_to_the_decoherence() -> void:
	var hud: Hud = _add_hud()
	var run := RunState.new("A", WILAS)
	hud.bind_run(run)
	var glow: TextureRect = hud.get_node("%ThreatGlow")
	assert_str(_text(hud, "%ThreatValue")).is_equal("-")
	assert_float(glow.modulate.a).is_equal(0.0)
	run.set_threat_distance(hud.threat_warning_distance * 2.0)
	assert_float(glow.modulate.a).is_equal(0.0)
	run.set_threat_distance(hud.threat_warning_distance / 4.0)
	assert_str(_text(hud, "%ThreatValue")).is_equal("%.1f" % (hud.threat_warning_distance / 4.0))
	assert_float(glow.modulate.a).is_equal_approx(0.75, 0.001)


func test_threat_danger_grows_as_it_gets_closer() -> void:
	assert_float(Hud.threat_danger(20.0, 10.0)).is_equal(0.0)
	assert_float(Hud.threat_danger(5.0, 10.0)).is_equal(0.5)
	assert_float(Hud.threat_danger(0.0, 10.0)).is_equal(1.0)
	assert_float(Hud.threat_danger(INF, 10.0)).is_equal(0.0)


func _add_hud() -> Hud:
	var hud: Hud = auto_free(HUD_SCENE.instantiate())
	add_child(hud)
	return hud


func _text(hud: Hud, path: String) -> String:
	return (hud.get_node(path) as Label).text
