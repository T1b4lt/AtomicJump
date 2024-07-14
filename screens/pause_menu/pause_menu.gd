class_name PauseMenu
extends CanvasLayer


signal resume_button_pressed()
signal menu_button_pressed()
signal exit_button_pressed()


func _on_resume_button_pressed():
	resume_button_pressed.emit()


func _on_menu_button_pressed():
	menu_button_pressed.emit()


func _on_exit_button_pressed():
	exit_button_pressed.emit()
