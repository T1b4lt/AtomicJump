class_name Platform
extends Node2D

# Scenes
const SPIKE_SCENE = "res://platforms/blocks/spike/spike.tscn"
const COIN_SCENE = "res://objects/currencies/coin/coin.tscn"
const KEY_SCENE = "res://objects/currencies/key/key.tscn"

# Childs
@onready var object_placeholders = $object_placeholders

# Signals
signal platform_enter_screen()
signal platform_leave_screen()

func place_objects():
	# Place 0 or 1 spikes
	# Place 1 to 5 coins
	# Place 0 or 1 keys
	# aux_placeholders is an array of Node2D objects, so elements can be placed in any of them (same position)
	var aux_placeholders = object_placeholders.get_children()
	var occupied_idxs = []
	var num_spikes = randi() % 2
	var num_coins = randi() % 5 + 1
	var num_keys = randi() % 2
	
	# Place spikes
	var i = 0
	while i < num_spikes:
		var idx = randi() % aux_placeholders.size()
		if idx not in occupied_idxs:
			occupied_idxs.append(idx)
			var spike = load(SPIKE_SCENE).instantiate() as Spike
			spike.position = aux_placeholders[idx].position
			add_child(spike)
			i += 1

	# Place coins
	i = 0
	while i < num_coins:
		var idx = randi() % aux_placeholders.size()
		if idx not in occupied_idxs:
			occupied_idxs.append(idx)
			var coin = load(COIN_SCENE).instantiate() as Coin
			coin.position = aux_placeholders[idx].position
			add_child(coin)
			i += 1

	# Place keys
	i = 0
	while i < num_keys:
		var idx = randi() % aux_placeholders.size()
		if idx not in occupied_idxs:
			occupied_idxs.append(idx)
			var key = load(KEY_SCENE).instantiate() as Key
			key.position = aux_placeholders[idx].position
			add_child(key)
			i += 1


func _on_visible_on_screen_notifier_2d_screen_entered():
	platform_enter_screen.emit()


func _on_visible_on_screen_notifier_2d_screen_exited():
	platform_leave_screen.emit()
