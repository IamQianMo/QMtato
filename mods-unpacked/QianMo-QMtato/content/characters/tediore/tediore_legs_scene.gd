extends Node2D


onready var _movement_behavior = $TargetRandPosMovementBehavior

var _parent = null
var _speed: = 450.0
var _current_target = null
var _player = null
var _min_pos: = Vector2( - 9999, - 9999)
var _max_pos: = Vector2(9999, 9999)
var _main = null
var _entity_spawner = null
var _show_legs: = true


func init(parent, player, speed:float = 450.0, show_legs:bool = true)->void :
	_parent = parent
	_speed = speed
	_player = player
	_show_legs = show_legs
	
	_min_pos = ZoneService.current_zone_min_position
	_max_pos = ZoneService.current_zone_max_position


func _ready():
	_parent.get_parent().remove_child(_parent)
	
	if not _show_legs:
		hide()
	
	_main = RunData.get_tree().current_scene
	_main.add_child(_parent)
	
	_movement_behavior.init(self)


func _physics_process(delta):
	if _parent:
		var movement = _movement_behavior.get_movement().normalized()
		_parent.global_position += movement * _speed * delta
		
		update_animation(movement)
		
		var pos = _parent.global_position
		if (pos.x < _min_pos.x 
			or pos.y < _min_pos.y
			or pos.x > _max_pos.x
			or pos.y > _max_pos.y):
			_movement_behavior._current_target = Vector2.ZERO
		
		rotation = -_parent.rotation


func update_animation(movement:Vector2)->void :
	if movement.x > 0:
		scale.x = abs(scale.x)
	elif movement.x < 0:
		scale.x = - abs(scale.x)
