extends PlayerProjectile


onready var _piranha_duration_timer = $PiranhaDurationTimer

var _piranha_from:Node2D = null
var _piranha_target = null
var _piranha_current_cooldown:float = 0
var _piranha_cooldown:float = 8
var _piranha_max_duration: = 5.0
var _piranha_max_range_squared: = 0


func _ready():
	call_deferred("init_deferred")


func init_deferred()->void :
	_piranha_max_range_squared = weapon_stats.max_range * weapon_stats.max_range


func set_piranha_cooldown(cooldown)->void :
	_piranha_cooldown = cooldown


func set_piranha_max_duration(duration)->void :
	_piranha_max_duration = duration


func _physics_process(delta):
	if _piranha_target and is_instance_valid(_piranha_target):
		_piranha_current_cooldown = max(_piranha_current_cooldown - Utils.physics_one(delta), 0)
		
		if should_shoot():
			call_deferred("enable_hitbox")
		
		if (global_position - _piranha_target.global_position).length_squared() < 10000:
			global_position = _piranha_target.global_position
			spawn_position = global_position
	else:
		find_new_target()
	
	if is_instance_valid(_piranha_from):
		if (global_position - _piranha_from.global_position).length_squared() > _piranha_max_range_squared:
			set_to_be_destroyed()


func set_from(from:Node)->void :
	.set_from(from)
	
	_piranha_from = from


func _on_Hitbox_hit_something(thing_hit:Node, damage_dealt:int)->void :
	RunData.manage_life_steal(weapon_stats)
	emit_signal("hit_something", thing_hit, damage_dealt)
	
	_piranha_current_cooldown = rand_range(_piranha_cooldown * 0.8, _piranha_cooldown * 1.2)
	call_deferred("disable_hitbox")


func _on_Hitbox_critically_hit_something(_thing_hit:Node, _damage_dealt:int)->void :
	pass


func set_attach_target(target)->void :
	_piranha_target = target
	
	if target and is_instance_valid(target):
		if not target.is_connected("died", self, "_on_enemy_died"):
			var _error = target.connect("died", self, "_on_enemy_died")
		_piranha_duration_timer.start(_piranha_max_duration)


func _on_enemy_died(_enemy)->void :
	find_new_target()


func should_shoot()->bool :
	return _piranha_current_cooldown == 0


func find_new_target()->void :
	if _piranha_from and is_instance_valid(_piranha_from):
		var _current_target = _piranha_from._current_target
		if not _current_target.empty():
			var target = _current_target[0]
			
			if target and is_instance_valid(target):
				var new_rotation = (target.global_position - global_position).angle()
				
				set_deferred("velocity", Vector2.RIGHT.rotated(new_rotation) * weapon_stats.projectile_speed)
				set_deferred("rotation", new_rotation)
				
				set_attach_target(target)
				
				return
	
	set_attach_target(null)


func _on_PiranhaDurationTimer_timeout():
	find_new_target()
