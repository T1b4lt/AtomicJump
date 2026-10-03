class_name CharacterData
extends Resource
## A playable character: id, translated name and base statistics.
## One .tres per character in data/characters/.

@export var id: StringName
## Translation key of the visible name.
@export var name_key: String
@export var base_stats: StatBlock
