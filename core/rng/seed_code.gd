class_name SeedCode
extends RefCounted
## Run seeds. Provisional format until Phase 3 (docs/08-seeds.md): always a
## positive 9-digit number, so any seed shown can be typed back in.

const MIN: int = 100_000_000
const MAX: int = 999_999_999
const DIGITS: int = 9


## Generates a random seed that can be typed back in the main menu.
static func generate() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(MIN, MAX)


## Returns whether the text is a seed the player can type in the main menu.
static func is_valid_text(text: String) -> bool:
	var trimmed: String = text.strip_edges()
	if trimmed.length() != DIGITS or not trimmed.is_valid_int():
		return false
	var value: int = trimmed.to_int()
	return value >= MIN and value <= MAX


## Seed typed by the player. Call is_valid_text() first.
static func from_text(text: String) -> int:
	return text.strip_edges().to_int()
