extends Node2D


onready var _hit_timer = $HitCooldownTimer

var fake_player_script = preload("res://mods-unpacked/QianMo-QMtato/content/characters/puppeteer/puppeteer_fake_player.gd")

var _player:Player = null
var _parent = null
var _targets: = []
var _target = null

var _is_in_control: = false
var _movement_behavior:PlayerMovementBehavior = null
var _entity_spawner:EntitySpawner = null
var _controlling_effect_parent = null
var _control_line:Line2D = null
var _gradient:Gradient = null
var _hurtbox = null
var _fake_player = null


func _ready():
	_gradient = Gradient.new()
	_gradient.add_point(0, Color.black)
	_gradient.add_point(1, Color.darkviolet)
	
	_fake_player = fake_player_script.new()
	call_deferred("add_child", _fake_player)
	
	var _main = RunData.get_tree().current_scene
	_entity_spawner = _main._entity_spawner
	_main._wave_timer.connect("timeout", self, "_on_wave_timer_timeout")


func _on_wave_timer_timeout()->void :
	if is_instance_valid(_parent):
		_parent.die()


func change_control_mode(is_in_control)->void:
	_is_in_control = is_in_control
	
	if _is_in_control:
		_target = null


func _on_parent_died(_deadbody)->void:
	if not _control_line == null:
		_control_line.queue_free()
	queue_free()


func init(player, controlling_effect_parent)->void:
	_player = player
	_movement_behavior = _player._movement_behavior
	_controlling_effect_parent = controlling_effect_parent
	_parent = get_parent()
	_parent.connect("died", self, "_on_parent_died")
	_parent.connect("took_damage", self, "_on_parent_took_damage")
	_parent._hitbox.connect("hit_something", self, "_on_hit_something")
	_hurtbox = _parent._hurtbox


func _on_parent_took_damage(_unit, _value, _knockback_direction, _knockback_amount, _is_crit, _is_miss, _is_dodge, _is_protected, _effect_scale, _hit_type):
	_hit_timer.start()
	_hurtbox.disable()


func _on_hit_something(thing_hit, damage_dealt)->void:
	_target = null
	
	if thing_hit is Boss:
		thing_hit.take_damage(damage_dealt * 2)
	
	_targets.erase(thing_hit)


func _on_PuppetHurtbox_body_entered(body):
	_targets.push_back(body)


func _on_PuppetHurtbox_body_exited(body):
	_targets.erase(body)


var _target_position = Vector2.ZERO
var _control_mode_target = null

func _physics_process(_delta):
	if not _is_in_control:
		if not _control_line == null:
			_control_line.queue_free()
			_control_line = null
		
		if _target == null or not is_instance_valid(_target) or _target.dead:
			if _targets.size() > 0:
				_target = Utils.get_nearest(_targets, _parent.global_position)[0]
				_target_position = _target.global_position
			else:
				var temp_targets = _entity_spawner.get_all_enemies()
				for e in _controlling_effect_parent._controlling_enemies:
					temp_targets.erase(e[0])
				
				if temp_targets.size() > 0:
					_target = Utils.get_rand_element(temp_targets)
					if is_instance_valid(_target):
						if _target.collision_layer == 1 << 1 | 1 << 10:
							_target = null
						else:
							_target_position = _target.global_position
		else:
			_target_position = _target.global_position
		
		_fake_player.set_position(_target_position)
		_parent.player_ref = _fake_player
		_parent._movement_behavior.set("player_ref", _fake_player)
	else:
		if _control_line == null:
			_control_line = Line2D.new()
			_control_line.add_point(_player.global_position, 0)
			_control_line.add_point(_parent.global_position, 1)
			_control_line.gradient = _gradient
			_parent.call_deferred("add_child", _control_line)
	
		_control_line.set_deferred("global_position", Vector2.ZERO)
		_control_line.set_deferred("global_rotation", 0)
		_control_line.set_point_position(0, _player.global_position)
		_control_line.set_point_position(1, _parent.global_position)
		
		if _control_mode_target == null or not is_instance_valid(_control_mode_target) or _control_mode_target.dead:
			var enemies_in_range = _controlling_effect_parent.get_enemies_in_range()
			
			if enemies_in_range.size() > 0:
				for e in enemies_in_range:
					if e is Boss:
						_control_mode_target = e
						break
						
				if _control_mode_target == null or not is_instance_valid(_control_mode_target) or _control_mode_target.dead:
					_control_mode_target = Utils.get_nearest(enemies_in_range, _parent.global_position)[0]
				
				if is_instance_valid(_control_mode_target) and not _control_mode_target.dead:
					_fake_player.set_position(_control_mode_target.global_position)
				else:
					_fake_player.set_position(_player.global_position)
				_parent.player_ref = _fake_player
				_parent._movement_behavior.set("player_ref", _fake_player)
			else:
				_parent.player_ref = _player
				_parent._movement_behavior.set("player_ref", _player)
		else:
			_fake_player.set_position(_control_mode_target.global_position)
			_parent.player_ref = _fake_player
			_parent._movement_behavior.set("player_ref", _fake_player)


func _on_HitCooldownTimer_timeout():
	_hurtbox.enable()
