class_name Platform
extends Node2D

# Signals
signal platform_enter_screen()
signal platform_leave_screen()


func _on_visible_on_screen_notifier_2d_screen_entered():
	platform_enter_screen.emit()


func _on_visible_on_screen_notifier_2d_screen_exited():
	platform_leave_screen.emit()
