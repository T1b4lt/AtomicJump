extends GdUnitTestSuite

## Tests de la UI de semillas: campo del menú principal y pantalla final.

const MAIN_MENU_SCENE: PackedScene = preload("res://ui/main_menu/main_menu.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://ui/game_over/game_over.tscn")
const WILAS: CharacterData = preload("res://data/characters/wilas.tres")


func test_seed_field_accepts_free_text() -> void:
	var menu: MainMenu = _add(MAIN_MENU_SCENE)
	var input: LineEdit = menu.get_node(^"%SeedInput")
	assert_int(input.max_length).is_equal(SeedCode.MAX_TEXT_LENGTH)
	menu.set_seed_text("hola mundo")
	assert_str(menu.get_seed_text()).is_equal("HOLAMUNDO")
	menu.set_seed_text("k7qx2mpa")
	assert_str(menu.get_seed_text()).is_equal("K7QX-2MPA")


func test_random_button_fills_a_new_code() -> void:
	var menu: MainMenu = _add(MAIN_MENU_SCENE)
	(menu.get_node(^"%RandomSeedButton") as Button).pressed.emit()
	var code: String = menu.get_seed_text()
	assert_bool(SeedCode.is_code(SeedCode.normalize(code))).is_true()
	assert_str(SeedCode.from_text(code)).is_equal(code)


func test_game_over_shows_and_copies_the_seed() -> void:
	var screen: GameOver = _add(GAME_OVER_SCENE)
	var copy_button: Button = screen.get_node(^"%CopySeedButton")
	assert_bool(copy_button.disabled).is_true()
	screen.show_run(RunState.new("hola mundo", WILAS))
	var label: Label = screen.get_node(^"%SeedLabel")
	assert_str(label.text).contains("HOLAMUNDO · g%d" % WorldRng.GENERATION_VERSION)
	assert_bool(copy_button.disabled).is_false()
	assert_str(screen.get_seed_code()).is_equal("HOLAMUNDO")


func _add(scene: PackedScene) -> Node:
	var node: Node = auto_free(scene.instantiate())
	add_child(node)
	return node
