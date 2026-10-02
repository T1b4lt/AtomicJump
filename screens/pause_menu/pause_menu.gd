class_name PauseMenu
extends CanvasLayer
## Pauses and resumes the level. Its process_mode is Always (set in the scene),
## so it keeps receiving the pause action while the tree is paused.

# Signals
signal menu_button_pressed
signal exit_button_pressed


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if get_tree().paused:
			resume()
		else:
			pause()


func pause() -> void:
	# Pause everything in the scene and show the menu
	get_tree().paused = true
	show()


func resume() -> void:
	# Hide the menu and resume activity in the scene
	hide()
	get_tree().paused = false


func _on_resume_button_pressed() -> void:
	resume()


func _on_menu_button_pressed() -> void:
	resume()
	menu_button_pressed.emit()


func _on_exit_button_pressed() -> void:
	exit_button_pressed.emit()
