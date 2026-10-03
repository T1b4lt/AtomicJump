class_name StatEffect
extends ItemEffect
## Changes statistics while the item is carried: its modifiers are added with
## the item as their source (shown in the build breakdown).

@export var modifiers: Array[StatModifier] = []

var _applied: Array[StatModifier] = []


func added(build: Build) -> void:
	var stats: Stats = build.get_stats()
	if stats == null:
		return
	for template: StatModifier in modifiers:
		var modifier := StatModifier.create(template.stat, template.type, template.value, source)
		stats.add_modifier(modifier)
		_applied.append(modifier)


func removed(build: Build) -> void:
	var stats: Stats = build.get_stats()
	if stats == null:
		return
	for modifier: StatModifier in _applied:
		stats.remove_modifier(modifier)
	_applied.clear()
