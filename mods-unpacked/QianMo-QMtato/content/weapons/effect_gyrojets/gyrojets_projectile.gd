extends "res://projectiles/player_projectile.gd"


export (PackedScene) var stack_node_scene:PackedScene = null

var _gyrojets_effect = null
var _attach_target = null
var _current_stack: = 1
var _related_stack_node = null
var _qmtato_from = null


func _physics_process(_delta):
	if _attach_target:
		global_position = _attach_target.global_position
		spawn_position = global_position


func init(gyrojets_effect)->void :
	_gyrojets_effect = gyrojets_effect
	
	_hitbox.init(_gyrojets_effect.exploding_effect, _gyrojets_effect.explode_instantly)
	if _gyrojets_effect.explode_instantly:
		_hitbox.damage = max(1, _hitbox.damage * 0.5) as int
	
	scale *= 0.8


func _on_Hitbox_hit_something(thing_hit:Node, damage_dealt:int)->void :
	_hitbox.ignored_objects = [thing_hit]
	if _gyrojets_effect.stick:
		attach_projectile(thing_hit)
		
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = _gyrojets_effect.explosion_delay
		timer.connect("timeout", self, "_on_explode_timer_timeout")
		timer.start()
		
		RunData.manage_life_steal(weapon_stats)
	
		emit_signal("hit_something", thing_hit, damage_dealt)
	else:
		._on_Hitbox_hit_something(thing_hit, damage_dealt)


func explode_now()->void :
	if _gyrojets_effect:
		_on_explode_timer_timeout()


func _on_explode_timer_timeout()->void :
	if _related_stack_node and is_instance_valid(_related_stack_node):
		var stack_count:int = _related_stack_node.get_stack_count(_gyrojets_effect.type)
		if not stack_count == -1:
			_hitbox.damage = (_hitbox.damage * (stack_count * _gyrojets_effect.damage_increase_per_stack + 1.0)) as int
		_related_stack_node.remove_stack(_gyrojets_effect.type)
	else:
		_hitbox.damage = (_hitbox.damage * (_current_stack * _gyrojets_effect.damage_increase_per_stack + 1.0)) as int
	
	var _error = WeaponService.explode(_gyrojets_effect.exploding_effect, global_position, _hitbox.damage, 1.0, 0.03, 2.0, null)
	
	set_to_be_destroyed()


func attach_projectile(attach_target:Node = null)->void :
	to_be_destroyed = true
	_hitbox.active = false
	_hitbox.disable()
	velocity = Vector2.ZERO
	
	if attach_target and is_instance_valid(attach_target):
		var _error = attach_target.connect("tree_exiting", self, "_on_unit_died")
		
		var stack_node = attach_target.get_node_or_null("QmtatoGyrojets")
		if not stack_node:
			stack_node = stack_node_scene.instance()
			stack_node.name = "QmtatoGyrojets"
			stack_node.add_stack(_gyrojets_effect.type)
			attach_target.call_deferred("add_child", stack_node)
		else:
			_current_stack = max(1, stack_node.get_stack_count(_gyrojets_effect.type)) as int
			stack_node.add_stack(_gyrojets_effect.type)
		
		_related_stack_node = stack_node
		
		_attach_target = attach_target


func enable_projectile()->void :
	to_be_destroyed = false
	_hitbox.active = true
	_hitbox.enable()


func _on_unit_died()->void :
	find_new_target()


func find_new_target()->void :
	_attach_target = null
	
	if _qmtato_from and is_instance_valid(_qmtato_from):
		var _current_target = _qmtato_from.get("_current_target")
		if _current_target and not _current_target.empty():
			var target = _current_target[0]
			
			if target and is_instance_valid(target):
				var new_rotation = (target.global_position - global_position).angle()
				
				set_deferred("velocity", Vector2.RIGHT.rotated(new_rotation) * weapon_stats.projectile_speed * 0.5)
				set_deferred("rotation", new_rotation)
				
				call_deferred("enable_projectile")
				
				_attach_target = self


func set_from(from:Node)->void :
	.set_from(from)
	
	_qmtato_from = from
