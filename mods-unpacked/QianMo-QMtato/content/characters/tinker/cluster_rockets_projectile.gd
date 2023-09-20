extends Node2D


export (Resource) var target_crosshair

onready var _destroy_timer = $DestroyTimer as Timer

var from = null
var velocity: = Vector2.ONE
var _crosshair = null


func _physics_process(delta):
	position += velocity * delta


func set_destroy_time(time:float)->void:
	_destroy_timer.wait_time = time
	_destroy_timer.start()


func set_target_position(pos:Vector2)->void:
	var main = get_tree().current_scene
	_crosshair = target_crosshair.instance()
	main.call_deferred("add_child", _crosshair)
	_crosshair.set_deferred("global_position", pos)
	_crosshair.set_deferred("spawn_position", pos)


func _on_DestroyTimer_timeout():
	if not from == null and is_instance_valid(from):
		var instance = from.explode(global_position, from.stats.damage * 2)
		instance.call_deferred("set_area", 2 + randf())
	
	if not _crosshair == null and is_instance_valid(_crosshair):
		_crosshair.queue_free()
	
	queue_free()
