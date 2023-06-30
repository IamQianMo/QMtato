extends "res://main.gd"


func _ready():
	var event_listener = ProgressData.get_node_or_null("QmtatoMainEventListener")
	
	if event_listener:
		event_listener.emit_signal("player_spawned", _player)
