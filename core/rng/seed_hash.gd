class_name SeedHash
extends RefCounted
## Stable 64-bit hash for seeds and world rolls (docs/08-seeds.md): FNV-1a over
## the UTF-8 bytes, finished with SplitMix64. Never use the engine's hash() for
## this: it is not guaranteed across engine versions or platforms.
##
## GDScript ints are signed 64-bit and wrap on overflow, so the hashes may be
## negative. The unsigned constants are written as their signed equivalents.

## FNV-1a 64 offset basis (0xcbf29ce484222325).
const FNV_OFFSET: int = -3750763034362895579
## FNV-1a 64 prime (0x100000001b3).
const FNV_PRIME: int = 0x100000001b3
## SplitMix64 increment (0x9e3779b97f4a7c15).
const SPLITMIX_GAMMA: int = -7046029254386353131
## SplitMix64 multipliers (0xbf58476d1ce4e5b9 and 0x94d049bb133111eb).
const SPLITMIX_MUL_1: int = -4658895280553007687
const SPLITMIX_MUL_2: int = -7723592293110705685
## Separator between the parts of an address, so ["a", "b"] differs from ["ab"].
const PART_SEPARATOR: String = "|"
## Bits of a float mantissa: roll results use the top 53 bits of a hash.
const FLOAT_BITS: int = 53


## FNV-1a 64 of the bytes.
static func fnv1a(bytes: PackedByteArray) -> int:
	var hash_value: int = FNV_OFFSET
	for byte: int in bytes:
		hash_value = (hash_value ^ byte) * FNV_PRIME
	return hash_value


## SplitMix64 finalizer: spreads every input bit over the whole result.
static func mix(value: int) -> int:
	var z: int = value + SPLITMIX_GAMMA
	z = (z ^ shift_right(z, 30)) * SPLITMIX_MUL_1
	z = (z ^ shift_right(z, 27)) * SPLITMIX_MUL_2
	return z ^ shift_right(z, 31)


## Stable hash of a text.
static func hash_string(text: String) -> int:
	return mix(fnv1a(text.to_utf8_buffer()))


## Stable hash of an address: its parts (strings, string names or ints) joined
## with PART_SEPARATOR. Floats are not allowed: their text form is not stable.
static func hash_parts(parts: Array) -> int:
	var texts := PackedStringArray()
	for part: Variant in parts:
		assert(typeof(part) != TYPE_FLOAT, "Address parts must not be floats")
		texts.append(str(part))
	return hash_string(PART_SEPARATOR.join(texts))


## Logical (unsigned) right shift: GDScript's >> keeps the sign.
static func shift_right(value: int, bits: int) -> int:
	return (value >> bits) & ((1 << (64 - bits)) - 1)


## Maps a hash to a float in [0, 1) using its top 53 bits.
static func to_unit_float(hash_value: int) -> float:
	return float(shift_right(hash_value, 64 - FLOAT_BITS)) / float(1 << FLOAT_BITS)
