extends Node2D


export (PackedScene) var target_scene
export (float) var max_range: = 300.0

onready var _range_shape:CollisionShape2D = $Range/CollisionShape2D

var enemies_in_range: = []
var enemies_in_range_queue: = []
var _parent = null


func init(parent)->void:
	_parent = parent


func _on_Range_body_entered(body):
	if not _parent.get_control_mode():
		enemies_in_range_queue.push_back(body)
		return
	else:
		enemies_in_range.push_back(body)
		
	var target_instance = target_scene.instance()
	target_instance.name = "PuppeteerTarget"
	body.call_deferred("add_child", target_instance)


func _on_Range_body_exited(body):
	enemies_in_range.erase(body)
	enemies_in_range_queue.erase(body)
	
	var target_instance = body.get_node_or_null("PuppeteerTarget")
	if not target_instance == null:
		target_instance.queue_free()


func set_range()->void:
	_range_shape.shape.set_deferred("radius", max_range + Utils.get_stat("stat_range"))


func apply_targets()->void:
	for e in enemies_in_range_queue:
		var target_instance = e.get_node_or_null("PuppeteerTarget")
		if target_instance == null:
			target_instance = target_scene.instance()
			target_instance.name = "PuppeteerTarget"
			e.call_deferred("add_child", target_instance)
	
	enemies_in_range.append_array(enemies_in_range_queue)
	enemies_in_range_queue.clear()
