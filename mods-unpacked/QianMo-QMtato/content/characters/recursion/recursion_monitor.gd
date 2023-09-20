extends Node


var _parent


func init(parent)->void:
	_parent = parent


func _unhandled_input(event):
	if event.is_pressed():
		if event is InputEventKey:
			if event.scancode == KEY_SPACE:
				_parent.set_focus_mode()
		elif event is InputEventJoypadButton:
			if event.button_index == JOY_XBOX_A:
				_parent.set_focus_mode()
