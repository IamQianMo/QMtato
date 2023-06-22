extends Node2D


signal progress_changed(current_progress) 


onready var _progress_bar = $ProgressBar
onready var _hint = $ProgressBar/Hint

var _current_progress: = 0.0


func init(current_progress)->void :
	_current_progress = current_progress


func _ready():
	var _error = connect("progress_changed", self, "_on_progress_changed")
	_on_progress_changed(_current_progress)


func _on_progress_changed(current_progress)->void :
	_progress_bar.value = current_progress
	_hint.text = "%.1f%%" % _progress_bar.value
