extends Control


signal toggle_changed(status)
signal kill_count_changed(value)


onready var _black = $Animation/Black
onready var _white = $Animation/White
onready var _animation_player = $AnimationPlayer
onready var _kill_count_hint = $KillCountHint

var _current_status: = false


func init(current_status:bool)->void:
	_current_status = current_status


func _ready():
	change_sprite(_current_status)
	_on_kill_count_changed(0)
	var _error = connect("toggle_changed", self, "_on_toggle_changed")
	_error = connect("kill_count_changed", self, "_on_kill_count_changed")


func change_sprite(status:bool)->void:
	if status:
		_white.show()
		_black.hide()
	else:
		_white.hide()
		_black.show()
	
	_animation_player.play("start")


func _on_kill_count_changed(value:int)->void:
	_kill_count_hint.text = str(value)


func _on_toggle_changed(status)->void:
	change_sprite(status)
