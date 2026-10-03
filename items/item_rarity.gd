class_name ItemRarity
extends RefCounted
## Rarity rolls (docs/07-items.md#rareza and docs/08-seeds.md#calidad-qué-rareza).
## A "rarity" roll r in [0, 1) is compared, from the highest rarity down, with
## the chance of getting at least that rarity. Amplitude (luck) raises every
## one of those chances, so the same r gives the same rarity or a better one:
## quality only improves.
##
## chance(≥ rarity) = 1 − (1 − base(≥ rarity)) ^ (1 + luck / LUCK_PER_EXPONENT)

## Base chance of each rarity (ItemData.Rarity order): 65 %, 27 %, 7 % and 1 %.
const BASE_CHANCES: Array[float] = [0.65, 0.27, 0.07, 0.01]
## Luck points that add 1 to the exponent (100 points: ×3).
const LUCK_PER_EXPONENT: float = 50.0
const NAME_KEYS: Array[String] = ["RARITY_COMMON", "RARITY_RARE", "RARITY_EPIC", "RARITY_LEGENDARY"]
const COLORS: Array[Color] = [
	Palette.RARITY_COMMON, Palette.RARITY_RARE, Palette.RARITY_EPIC, Palette.RARITY_LEGENDARY
]


## Chance of a rarity or a better one with `luck` points of Amplitude.
static func chance_at_least(rarity: ItemData.Rarity, luck: float = 0.0) -> float:
	var base: float = 0.0
	for index: int in range(rarity, BASE_CHANCES.size()):
		base += BASE_CHANCES[index]
	if base >= 1.0:
		return 1.0
	return 1.0 - pow(1.0 - base, 1.0 + maxf(luck, 0.0) / LUCK_PER_EXPONENT)


## Rarity of a roll r in [0, 1) with `luck` points of Amplitude.
static func from_roll(roll: float, luck: float = 0.0) -> ItemData.Rarity:
	for rarity: int in range(ItemData.Rarity.LEGENDARY, ItemData.Rarity.COMMON, -1):
		if roll < chance_at_least(rarity as ItemData.Rarity, luck):
			return rarity as ItemData.Rarity
	return ItemData.Rarity.COMMON


static func get_color(rarity: ItemData.Rarity) -> Color:
	return COLORS[rarity]


static func get_name_key(rarity: ItemData.Rarity) -> String:
	return NAME_KEYS[rarity]
