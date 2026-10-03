extends GdUnitTestSuite

## Tests del hash estable: valores conocidos calculados fuera de Godot
## (FNV-1a 64 y SplitMix64 de referencia), así que no dependen del motor.


func test_fnv1a_known_values() -> void:
	# 0xcbf29ce484222325 (base) y 0xaf63dc4c8601ec8c ("a"), de la especificación
	assert_int(SeedHash.fnv1a(PackedByteArray())).is_equal(-3750763034362895579)
	assert_int(SeedHash.fnv1a("a".to_utf8_buffer())).is_equal(-5808556873153909620)
	assert_int(SeedHash.fnv1a("foobar".to_utf8_buffer())).is_equal(-8821353812377114648)


func test_splitmix_known_values() -> void:
	# 0xe220a8397b1dcdaf: primera salida de SplitMix64 con semilla 0
	assert_int(SeedHash.mix(0)).is_equal(-2152535657050944081)
	assert_int(SeedHash.mix(1)).is_equal(-7995527694508729151)
	assert_int(SeedHash.mix(-1)).is_equal(-1956407806741107680)


func test_hash_string_known_values() -> void:
	assert_int(SeedHash.hash_string("")).is_equal(-4359066618775142608)
	assert_int(SeedHash.hash_string("K7QX2MPA")).is_equal(2384594225281386139)
	assert_int(SeedHash.hash_string("HOLAMUNDO")).is_equal(-3331380914032591404)
	# UTF-8: la ñ son dos bytes
	assert_int(SeedHash.hash_string("ñ")).is_equal(2657375003112558396)


func test_hash_parts_separates_the_parts() -> void:
	assert_int(SeedHash.hash_parts(["a", "b"])).is_equal(SeedHash.hash_string("a|b"))
	assert_int(SeedHash.hash_parts(["ab"])).is_not_equal(SeedHash.hash_parts(["a", "b"]))
	# Un int y su texto son la misma parte; StringName y String también
	assert_int(SeedHash.hash_parts([&"layout", 2])).is_equal(SeedHash.hash_parts(["layout", "2"]))


func test_shift_right_is_unsigned() -> void:
	assert_int(SeedHash.shift_right(-1, 1)).is_equal(0x7fffffffffffffff)
	assert_int(SeedHash.shift_right(-1, 63)).is_equal(1)
	assert_int(SeedHash.shift_right(8, 3)).is_equal(1)


func test_unit_float_bounds() -> void:
	assert_float(SeedHash.to_unit_float(0)).is_equal(0.0)
	assert_float(SeedHash.to_unit_float(-1)).is_less(1.0)
	assert_float(SeedHash.to_unit_float(-1)).is_greater(0.999)
