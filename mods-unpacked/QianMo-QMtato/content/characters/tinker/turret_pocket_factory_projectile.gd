extends PlayerProjectile


var _target = null
var _target_direction: = Vector2.ZERO
var _rotation_rate: = 0.3
var _entity_spawner:EntitySpawner = null
var _speed: = -1

var from = null


func _ready():
	_entity_spawner = RunData.get_tree().current_scene._entity_spawner


func _physics_process(_delta):
	if _speed == -1:
		_speed = velocity.length()
	if _target == null or not is_instance_valid(_target) or _target.dead:
		if not _entity_spawner == null and _entity_spawner.enemies.size() > 0:
			_target = Utils.get_rand_element(_entity_spawner.enemies)
	else:
		if _hitbox.ignored_objects.has(_target):
			_target = null 
		else:
			_target_direction = global_position.direction_to(_target.global_position)
	
	_speed = velocity.length()
	var target_velocity = _target_direction * _speed
	velocity += (target_velocity - velocity) * _rotation_rate
	velocity = velocity.normalized() * _speed


func _on_DestroyTimer_timeout():
	if not from == null and is_instance_valid(from):
		from.explode(_hitbox.global_position, _hitbox.damage)
	
	queue_free()
