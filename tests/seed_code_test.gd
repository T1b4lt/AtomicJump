extends GdUnitTestSuite

## Tests de los códigos de semilla: formato, normalización y conversión a entero.


func test_generated_codes_have_the_code_format() -> void:
	var regex := RegEx.create_from_string("^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$")
	for i: int in 200:
		var code: String = SeedCode.generate()
		assert_object(regex.search(code)).override_failure_message(code).is_not_null()
		# Lo que se muestra se puede volver a escribir y da la misma semilla
		assert_str(SeedCode.from_text(code)).is_equal(code)


func test_encode_uses_40_bits() -> void:
	assert_str(SeedCode.encode(0)).is_equal("00000000")
	assert_str(SeedCode.encode((1 << 40) - 1)).is_equal("ZZZZZZZZ")
	assert_str(SeedCode.encode(1 << 40)).is_equal("00000000")
	assert_str(SeedCode.encode(32)).is_equal("00000010")


func test_codes_are_normalized() -> void:
	assert_str(SeedCode.from_text("k7qx-2mpa")).is_equal("K7QX-2MPA")
	assert_str(SeedCode.from_text(" K7QX 2MPA\t")).is_equal("K7QX-2MPA")
	assert_str(SeedCode.from_text("K7QX2MPA")).is_equal("K7QX-2MPA")
	# Alias de Crockford: I y L son 1, O es 0
	assert_str(SeedCode.from_text("IL0O-ABCD")).is_equal("1100-ABCD")


func test_free_text_is_normalized() -> void:
	assert_str(SeedCode.from_text("hola mundo")).is_equal("HOLAMUNDO")
	assert_str(SeedCode.from_text("MiPerro")).is_equal("MIPERRO")
	assert_str(SeedCode.from_text("ñandú")).is_equal("ÑANDÚ")
	# 8 caracteres con U no son un código (U no está en el alfabeto)
	assert_str(SeedCode.from_text("UUUUUUUU")).is_equal("UUUUUUUU")
	assert_int(SeedCode.normalize("x".repeat(100)).length()).is_equal(SeedCode.MAX_TEXT_LENGTH)


func test_valid_text() -> void:
	assert_bool(SeedCode.is_valid_text("a")).is_true()
	assert_bool(SeedCode.is_valid_text("")).is_false()
	assert_bool(SeedCode.is_valid_text(" - \t")).is_false()


func test_same_seed_however_it_is_typed() -> void:
	var expected: int = SeedCode.to_int("K7QX-2MPA")
	assert_int(SeedCode.to_int("k7qx2mpa")).is_equal(expected)
	assert_int(SeedCode.to_int("K7QX 2MPA")).is_equal(expected)
	assert_int(SeedCode.to_int("hola mundo")).is_equal(SeedCode.to_int("HOLA-MUNDO"))
	assert_int(SeedCode.to_int("hola mundo")).is_not_equal(SeedCode.to_int("hola mundos"))


func test_known_seed_values() -> void:
	# El entero es el hash estable del texto normalizado (valores en seed_hash_test)
	assert_int(SeedCode.to_int("K7QX-2MPA")).is_equal(2384594225281386139)
	assert_int(SeedCode.to_int("hola mundo")).is_equal(-3331380914032591404)
