extends GdUnitTestSuite

## Tests de la pantalla de build: desglose de estadísticas, lista de objetos,
## formato de los valores y cuándo se muestra.

const BUILD_SCREEN: PackedScene = preload("res://ui/build_screen/build_screen.tscn")
const WILAS: CharacterData = preload("res://data/characters/wilas.tres")
const CATALOG: ItemCatalog = preload("res://data/items/item_catalog.tres")


func after_test() -> void:
	TranslationServer.set_locale(Settings.language)


func test_stat_formats() -> void:
	assert_str(BuildScreen.format_stat(Stats.DEFENSE, 0.25)).is_equal("25 %")
	assert_str(BuildScreen.format_stat(Stats.LUCK, 3.0)).is_equal("3")
	assert_str(BuildScreen.format_stat(Stats.MAX_JUMPS, 3.0)).is_equal("3")
	assert_str(BuildScreen.format_stat(Stats.SPEED, 340.0)).is_equal("340")
	assert_str(BuildScreen.format_stat(Stats.ATTACK_RATE, 2.5)).is_equal("2.50")


func test_breakdown_names_every_source() -> void:
	TranslationServer.set_locale("es")
	var run := RunState.new("A", WILAS, CATALOG)
	run.add_item(CATALOG.get_item(&"linear_momentum"))
	run.add_item(CATALOG.get_item(&"planck_constant"))
	var text: String = BuildScreen.breakdown_text(run.stats, Stats.SPEED)
	assert_str(text).is_equal("base 300 · +40 Momento lineal · ×1.05 Constante de Planck")
	assert_str(BuildScreen.breakdown_text(run.stats, Stats.LUCK)).is_equal("base 0")


func test_shows_the_stats_and_the_items_of_the_run() -> void:
	var screen: BuildScreen = auto_free(BUILD_SCREEN.instantiate())
	add_child(screen)
	var run := RunState.new("A", WILAS, CATALOG)
	run.add_item(CATALOG.get_item(&"linear_momentum"))
	run.add_item(CATALOG.get_item(&"zeno_effect"))
	screen.bind_run(run)
	screen.set_pinned(true)
	assert_bool(screen.visible).is_true()
	var row: PackedStringArray = screen.get_stat_row(Stats.SPEED)
	assert_str(row[1]).is_equal("340")
	assert_str(row[2]).contains("+40")
	assert_int(screen.get_item_count()).is_equal(2)
	# It follows the run while it is shown
	run.add_item(CATALOG.get_item(&"effective_mass"))
	assert_int(screen.get_item_count()).is_equal(3)
	assert_str(screen.get_stat_row(Stats.MAX_HP)[1]).is_equal("125")


func test_hidden_unless_pinned_or_held() -> void:
	var screen: BuildScreen = auto_free(BUILD_SCREEN.instantiate())
	add_child(screen)
	screen.bind_run(RunState.new("A", WILAS))
	screen._process(0.0)
	assert_bool(screen.visible).is_false()
	screen.set_pinned(true)
	screen._process(0.0)
	assert_bool(screen.visible).is_true()
	screen.set_pinned(false)
	screen._process(0.0)
	assert_bool(screen.visible).is_false()
