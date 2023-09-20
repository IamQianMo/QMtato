extends Control


func generate_virtual_button_event(scancode:int)->void:
	var vb = InputEventKey.new()
	vb.scancode = scancode
	vb.pressed = true
	Input.parse_input_event(vb)


func _on_TouchScreenButtonJ_pressed():
	generate_virtual_button_event(KEY_J)


func _on_TouchScreenButtonK_pressed():
	generate_virtual_button_event(KEY_K)


func _on_TouchScreenButtonL_pressed():
	generate_virtual_button_event(KEY_L)


func _on_TouchScreenButtonI_pressed():
	generate_virtual_button_event(KEY_I)
