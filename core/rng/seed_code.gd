class_name SeedCode
extends RefCounted
## Run seeds (docs/08-seeds.md). A random seed is an 8-character Crockford
## base32 code shown as "K7QX-2MPA"; the player can also type any text
## ("hola mundo"). Every seed is normalized to a canonical text and hashed to a
## 64-bit integer with SeedHash, so both kinds work the same way.

## Crockford base32 alphabet: no I, L, O or U, so codes are hard to misread.
const ALPHABET: String = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
## Letters typed by mistake for the digits they look like (Crockford decoding).
const ALIASES: Dictionary[String, String] = {"I": "1", "L": "1", "O": "0"}
const CODE_LENGTH: int = 8
## Characters on each side of the hyphen.
const GROUP_LENGTH: int = 4
## Bits of entropy of a random code: 5 per character.
const CODE_BITS: int = 40
const BITS_PER_CHAR: int = 5
const GROUP_SEPARATOR: String = "-"
## Longest text kept from a typed seed, after removing spaces and hyphens.
const MAX_TEXT_LENGTH: int = 32


## Generates a random code with 40 bits of entropy, formatted as "XXXX-XXXX".
static func generate() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# randi() gives 32 random bits: combine two calls to fill the 40 bits
	var value: int = (rng.randi() << 32 | rng.randi()) & ((1 << CODE_BITS) - 1)
	return format(encode(value))


## Encodes the lowest 40 bits of the value as 8 characters, most significant first.
static func encode(value: int) -> String:
	var chars := PackedStringArray()
	for i: int in range(CODE_LENGTH - 1, -1, -1):
		chars.append(ALPHABET[(value >> (i * BITS_PER_CHAR)) & (ALPHABET.length() - 1)])
	return "".join(chars)


## Canonical form of a typed seed: upper case, without whitespace or hyphens and
## cut to MAX_TEXT_LENGTH. If it is a code, the Crockford aliases (I, L, O)
## become the digits they stand for. Returns "" if nothing is left.
static func normalize(text: String) -> String:
	var cleaned := PackedStringArray()
	for character: String in text.to_upper():
		if character != GROUP_SEPARATOR and not character.strip_edges().is_empty():
			cleaned.append(character)
	var result: String = "".join(cleaned).left(MAX_TEXT_LENGTH)
	if _is_code_with_aliases(result):
		for alias: String in ALIASES:
			result = result.replace(alias, ALIASES[alias])
	return result


## Whether the text (already normalized) is an 8-character code.
static func is_code(normalized: String) -> bool:
	if normalized.length() != CODE_LENGTH:
		return false
	for character: String in normalized:
		if not ALPHABET.contains(character):
			return false
	return true


## Text shown to the player: codes as "XXXX-XXXX", any other text as it is.
static func format(normalized: String) -> String:
	if not is_code(normalized):
		return normalized
	return normalized.left(GROUP_LENGTH) + GROUP_SEPARATOR + normalized.right(GROUP_LENGTH)


## Whether the player typed something usable as a seed.
static func is_valid_text(text: String) -> bool:
	return not normalize(text).is_empty()


## Seed shown to the player for a typed text (normalized and formatted).
static func from_text(text: String) -> String:
	return format(normalize(text))


## 64-bit seed of a typed text. The same text, however it was typed (spaces,
## case, hyphens, Crockford aliases), always gives the same value.
static func to_int(text: String) -> int:
	return SeedHash.hash_string(normalize(text))


static func _is_code_with_aliases(text: String) -> bool:
	if text.length() != CODE_LENGTH:
		return false
	for character: String in text:
		if not ALPHABET.contains(character) and not ALIASES.has(character):
			return false
	return true
