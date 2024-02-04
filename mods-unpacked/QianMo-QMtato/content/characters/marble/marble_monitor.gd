extends Node2D


export (float) var slide_time: = 1.5 # Slide time
export (float) var rotate_speed: = 1200.0 # Rotation speed of arrow
export (float) var arrow_distance: = 100.0
export (float) var max_speed_factor: = 2.5 # Max speed when charge time is max
export (Resource) var exploding_effect

onready var _cast_timer = $CastTimer
onready var _dash_timer = $DashTimer
onready var _arrow_sprite = $Animation/Sprite
onready var _bonus_arrow_sprite = $Animation/BonusTargetSprite

var _player = null
var _movement_behavior = null
var _entity_spawner = null
var _current_movement:Vector2 = Vector2.ZERO
var _original_movement:Vector2 = Vector2.ZERO
var _wave_timer = null

var _can_dash: = false
var _is_casting: = false
var _is_dashing: = false

var _rotation: = 0.0
var _bonus_armor_while_dashing: = 15
var _max_projectile: = 10
var _temp_explosion_scale: = 1.5
var _projectile_stats:Resource
var _exploding_stats:Resource
var _calculated_explosion_stats:Resource
var _original_speed_step: = 0.0
var _casted_time: = 0.0
var _owned_projectiles: = []


func init(bonus_armor_while_dashing, max_projectile, projectile_stats, exploding_stats)->void:
	_bonus_armor_while_dashing = bonus_armor_while_dashing
	_max_projectile = max_projectile
	_projectile_stats = projectile_stats
	_exploding_stats = exploding_stats


func _ready():
	_player = get_parent()
	_player._move_locked = true
	_player._current_movement = Vector2.ZERO

	_movement_behavior = _player._movement_behavior
	_cast_timer.wait_time = slide_time
	_dash_timer.wait_time = slide_time
	
	var main = RunData.get_tree().current_scene
	_entity_spawner = main._entity_spawner
		
	show_bonus_arrow()


func _physics_process(delta):
	var temp_movement = _movement_behavior.get_movement()
	
	if temp_movement.length() > 0:
		if not _is_dashing:
			_current_movement += temp_movement * rotate_speed * delta
			
			_rotation = _current_movement.angle()
			_arrow_sprite.rotation = _rotation
			_arrow_sprite.scale.x = _current_movement.length() / 1500
			_arrow_sprite.global_position = Vector2(_player.global_position.x + cos(_rotation) * arrow_distance, _player.global_position.y + sin(_rotation) * arrow_distance)
			
			if not _arrow_sprite.visible:
				_arrow_sprite.show()
			
			if not _is_casting:
				_is_casting = true
				
				if _cast_timer.is_stopped():
					_cast_timer.start()
					
				for projectile in _owned_projectiles:
					if is_instance_valid(projectile):
						projectile.start_return_behavior(_player.global_position, slide_time * 0.75)
				_owned_projectiles.clear()
	elif not _is_dashing and not _current_movement == Vector2.ZERO:
		_can_dash = true
	
	if _can_dash and not _current_movement == Vector2.ZERO:
		if _original_movement == Vector2.ZERO:
			_original_movement = _current_movement / slide_time
			
			_player.current_stats.speed = _player.max_stats.speed * max_speed_factor
			_original_speed_step = _player.current_stats.speed / slide_time
			
		_player._current_movement = _current_movement
		_player.current_stats.speed -= _original_speed_step * delta
		_current_movement -= _original_movement * delta
		
		if not _is_dashing:
			start_dash()
	else:
		_player._current_movement = Vector2.ZERO


func start_dash()->void:
	_is_dashing = true
	
	_arrow_sprite.hide()
	_bonus_arrow_sprite.hide()
	
	var direction_one = _bonus_arrow_sprite.global_position - _player.global_position
	var direction_two = _arrow_sprite.global_position - _player.global_position
	var angle = abs(direction_one.angle_to(direction_two))
	
	var length_diff = _arrow_sprite.scale.x / _bonus_arrow_sprite.scale.x
	
	if length_diff < 1:
		if length_diff == 0:
			length_diff = 0.01
		length_diff = 1 / length_diff
		
	var projectiles_number = (_max_projectile / length_diff) as int
	var rotate_factor:float = 2 - (angle / PI)
	
	_calculated_explosion_stats = WeaponService.init_base_stats(_exploding_stats, "", [], [ExplodingEffect.new()])
	
	var stats = WeaponService.init_ranged_stats(_projectile_stats)
	stats.bounce = 0
	for i in projectiles_number:
		var projectile = WeaponService.manage_special_spawn_projectile(_player, stats, true, _entity_spawner)
		
		projectile.apply_scale(Vector2(rotate_factor, rotate_factor))
		
		var target_position:Vector2 = _player.global_position
		target_position += _player.max_stats.speed * slide_time * Vector2.RIGHT.rotated(rand_range(-PI, PI))
		projectile.call_deferred("init", target_position, slide_time)
		_owned_projectiles.append(projectile)
	
	if _dash_timer.is_stopped():
		_dash_timer.start()


func show_bonus_arrow()->void:
	_rotation = rand_range(0, 2 * PI)
	_bonus_arrow_sprite.rotation = _rotation
	_bonus_arrow_sprite.scale.x = rand_range(0.2, 1.2)
	_bonus_arrow_sprite.global_position = Vector2(_player.global_position.x + cos(_rotation) * arrow_distance, _player.global_position.y + sin(_rotation) * arrow_distance)
	_bonus_arrow_sprite.show()


func _on_CastTimer_timeout():
	_is_casting = false
	_can_dash = true


func _on_DashTimer_timeout():
	clear_movement()
	show_bonus_arrow()
	
	_temp_explosion_scale = 1.5


func clear_movement()->void:
	_is_casting = false
	_is_dashing = false
	_can_dash = false
	_current_movement = Vector2.ZERO
	_original_movement = Vector2.ZERO


func _on_Hurtbox_area_entered(area):
	if not _is_dashing:
		return
	
	_temp_explosion_scale *= 1.15
	var explosion_instance = WeaponService.explode(exploding_effect, _player.global_position, _calculated_explosion_stats.damage, _calculated_explosion_stats.accuracy, _calculated_explosion_stats.crit_chance, _calculated_explosion_stats.crit_damage, _calculated_explosion_stats.burning_data)
	explosion_instance.call_deferred("set_area", _temp_explosion_scale)
