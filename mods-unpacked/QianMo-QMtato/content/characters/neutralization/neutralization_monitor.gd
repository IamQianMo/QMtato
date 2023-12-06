extends Node2D


onready var _change_toggle_timer = $ChangeToggleTimer

var _change_toggle_wait_time: = 1.0
var _parent = null
var _wave_timer = null


func init(parent, change_toggle_wait_time:float)->void:
	_parent = parent
	_change_toggle_wait_time = change_toggle_wait_time
	
	_wave_timer = RunData.get_tree().current_scene._wave_timer
	var _error = _wave_timer.connect("timeout", self, "_on_wave_timer_timeout")


func _ready():
	_change_toggle_timer.wait_time = _change_toggle_wait_time


func _on_ChangeToggleTimer_timeout():
	_parent.emit_signal("toggle_changed")


func _on_wave_timer_timeout()->void:
	_change_toggle_timer.stop()
