extends Control


func _on_TouchScreenButton_pressed():
	var vb = InputEventKey.new()
	vb.scancode = KEY_SPACE
	vb.pressed = true
	Input.parse_input_event(vb)
