extends Node2D


onready var _animation_player = $AnimationPlayer

var _parent
var _control_mode: = false


func init(parent)->void:
	_parent = parent


func _unhandled_input(event):
	if event.is_pressed():
		if event is InputEventKey:
			if event.scancode == KEY_SPACE:
				apply_control_mode()
		elif event is InputEventJoypadButton:
			if event.button_index == JOY_XBOX_A:
				apply_control_mode()


func apply_control_mode()->void:
	_control_mode = not _control_mode
	for e in _parent._controlling_enemies:
		if not e[1] == null and is_instance_valid(e[1]):
			e[1].call_deferred("change_control_mode", _control_mode)
	
	if _control_mode:
		_animation_player.play("control")
	else:
		_animation_player.play("reset")
	
	if _control_mode:
		_parent.apply_targets()
