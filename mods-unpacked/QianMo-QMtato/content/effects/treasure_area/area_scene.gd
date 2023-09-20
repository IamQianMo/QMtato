extends Area2D


export (PackedScene) var progress_bar_scene

onready var _dig_timer = $DigTimer

var _parent = null
var _current_progress: = 0.0
var _progress_step: = 0.0
var _player:Player = null
var _floating_text_manager = null
var _progress_bar_instance = null
var _is_moving: = true


func init(parent, dig_time, player, floating_text_manager)->void :
	_parent = parent
	
	var dig_speed = Utils.get_stat("dig_speed") / 100.0
	_progress_step = max(0.1, (35.0 / dig_time) * (1 + dig_speed))
	
	_player = player
	_floating_text_manager = floating_text_manager


func _on_DigTimer_timeout():
	if not _is_moving:
		_current_progress += _progress_step
		
		if is_instance_valid(_progress_bar_instance):
			_progress_bar_instance.emit_signal("progress_changed", _current_progress)
			
			if _current_progress >= 100:
				_progress_bar_instance.queue_free()
				_parent.emit_signal("dig_completed", self)


func _on_TreasureArea_body_entered(body):
	if body.collision_layer & 1 << 10:
		return
	
	if not _progress_bar_instance == null and is_instance_valid(_progress_bar_instance):
		_progress_bar_instance.queue_free()
	
	set_physics_process(true)
	
	_progress_bar_instance = progress_bar_scene.instance()
	_progress_bar_instance.call_deferred("init", _current_progress)
	_player.call_deferred("add_child", _progress_bar_instance)
	
	_floating_text_manager.display(tr("TREASURE_FINDED"), global_position, Color.orange)
	
	_dig_timer.start()


func _on_TreasureArea_body_exited(body):
	if body.collision_layer & 1 << 10:
		return
	
	if not _progress_bar_instance == null and is_instance_valid(_progress_bar_instance):
		_progress_bar_instance.queue_free()
	
	set_physics_process(false)
	
	_dig_timer.stop()


func _physics_process(_delta):
	var movement = _player._current_movement
	if movement.x == 0 and movement.y == 0:
		_is_moving = false
	else:
		_is_moving = true
		
		if not _dig_timer.is_stopped():
			_dig_timer.start()
