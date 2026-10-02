class_name Platform
extends Node2D

# Signals
signal platform_enter_screen
signal platform_leave_screen

# Scenes
const SPIKE_SCENE = "res://platforms/blocks/spike/spike.tscn"
const COIN_SCENE = "res://objects/currencies/coin/coin.tscn"
const KEY_SCENE = "res://objects/currencies/key/key.tscn"

# Children
@onready var object_placeholders: Node2D = $object_placeholders


func place_objects() -> void:
	# Place 0 or 1 spikes
	# Place 1 to 5 coins
	# Place 0 or 1 keys
	# aux_placeholders is an array of Node2D objects,
	# so elements can be placed in any of them (same position)
	var aux_placeholders: Array[Node] = object_placeholders.get_children()
	var occupied_idxs: Array[int] = []
	var num_spikes: int = randi() % 2
	var num_coins: int = randi() % 5 + 1
	var num_keys: int = randi() % 2

	# Place spikes
	var i: int = 0
	while i < num_spikes:
		var idx: int = randi() % aux_placeholders.size()
		if idx not in occupied_idxs:
			occupied_idxs.append(idx)
			var spike: Spike = (load(SPIKE_SCENE) as PackedScene).instantiate() as Spike
			spike.position = (aux_placeholders[idx] as Node2D).position
			add_child(spike)
			i += 1

	# Place coins
	i = 0
	while i < num_coins:
		var idx: int = randi() % aux_placeholders.size()
		if idx not in occupied_idxs:
			occupied_idxs.append(idx)
			var coin: Coin = (load(COIN_SCENE) as PackedScene).instantiate() as Coin
			coin.position = (aux_placeholders[idx] as Node2D).position
			add_child(coin)
			i += 1

	# Place keys
	i = 0
	while i < num_keys:
		var idx: int = randi() % aux_placeholders.size()
		if idx not in occupied_idxs:
			occupied_idxs.append(idx)
			var key: KeyPickup = (load(KEY_SCENE) as PackedScene).instantiate() as KeyPickup
			key.position = (aux_placeholders[idx] as Node2D).position
			add_child(key)
			i += 1


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	platform_enter_screen.emit()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	platform_leave_screen.emit()
