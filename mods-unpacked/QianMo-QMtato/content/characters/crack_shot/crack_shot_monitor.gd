extends Node2D


export (float) var aim_time: = 1.5
export (float) var arrow_distance: = 100.0
export (Resource) var exploding_effect

onready var _cast_timer = $CastTimer
onready var _arrow_sprite = $Animation/Sprite
onready var _charge_bar = $ChargeBar
onready var _charge_hint = $ChargeBar/Hint

var _player = null
var _movement_behavior:PlayerMovementBehavior = null
var _entity_spawner:EntitySpawner = null
var _floating_text_manager:FloatingTextManager = null
var _wave_timer:WaveTimer = null
var _current_movement:Vector2 = Vector2.ZERO
var _projectile_stats:Resource

var _is_casting: = false
var _is_skill_ready: = false
var _can_fire: = false
var _wave_ended: = false

var _rotation: = 0.0
var _enemy_killed: = 0
var _enemy_needed: = 15
var _enemy_needed_increase_per_wave: = 5
var _actual_enemy_needed: = 15
var _damage_charge: = 0
var _width: = 6


func init(projectile_stats, enemy_needed, enemy_needed_increase_per_wave)->void:
	_projectile_stats = projectile_stats
	_enemy_needed = enemy_needed
	_enemy_needed_increase_per_wave = enemy_needed_increase_per_wave
	
	_actual_enemy_needed = RunData.current_wave * _enemy_needed_increase_per_wave + _enemy_needed
	_charge_bar.max_value = _actual_enemy_needed
	_charge_bar.value = 0
	_charge_hint.text = str(_enemy_killed) + "/" + str(_actual_enemy_needed)


func _ready():
	_player = get_parent()

	_movement_behavior = _player._movement_behavior
	_cast_timer.wait_time = aim_time
	
	var main = RunData.get_tree().current_scene
	_entity_spawner = main._entity_spawner
	_floating_text_manager = main._floating_text_manager
	_wave_timer = main._wave_timer
	
	var _error = _entity_spawner.connect("enemy_spawned", self, "_on_enemy_spawned")
	_error = _wave_timer.connect("timeout", self, "_on_wave_timer_timeout")
	_error = _player.connect("died", self, "_on_player_died")
	
	_wave_ended = false
	_enemy_killed = 0


func _on_player_died(_p_player)->void :
	queue_free()


func _on_wave_timer_timeout()->void:
	_wave_ended = true


func _on_enemy_spawned(enemy)->void:
	enemy.connect("died", self, "_on_enemy_died")


func _on_enemy_died(_enemy)->void:
	if not _is_skill_ready and not _wave_ended:
		_enemy_killed += 1
		
		_charge_bar.value = _enemy_killed
		_charge_hint.text = str(_enemy_killed) + "/" + str(_actual_enemy_needed)
		
		if _enemy_killed >= _actual_enemy_needed:
			_enemy_killed = 0
			_is_skill_ready = true
			
			lock_player(true)


var _charge_time:float = 0
var _total_time:float = 0

func _physics_process(delta):
	if _is_skill_ready and _movement_behavior:
		var temp_movement = _movement_behavior.get_movement()
		
		if temp_movement.length() > 0:
			_current_movement += temp_movement * delta
			
			_rotation = _current_movement.angle()
			_arrow_sprite.rotation = _rotation
			_arrow_sprite.scale.x = _total_time / 3
			_arrow_sprite.global_position = Vector2(_player.global_position.x + cos(_rotation) * arrow_distance, _player.global_position.y + sin(_rotation) * arrow_distance)
			
			if not _arrow_sprite.visible:
				_arrow_sprite.show()
			
			_charge_time += delta
			_total_time += delta
			if _charge_time > 0.1:
				_charge_time -= 0.1
				
				_damage_charge += 20
				
				if _damage_charge % 200 == 0:
					var instance = WeaponService.explode(exploding_effect, _player.global_position, 1, 1, 0, 0, BurningData.new())
					instance.call_deferred("init", _player)
					
					_width -= 1
					_arrow_sprite.scale.y = _width
					_floating_text_manager.display("+200%", _player.global_position, Color.mediumblue)
			
			_charge_bar.value = _damage_charge
			_charge_hint.text = str(_damage_charge) + "/1000"
			
			if not _is_casting:
				_is_casting = true
				
				_charge_bar.max_value = 1000
				_arrow_sprite.scale.y = _width
				
				var instance = WeaponService.explode(exploding_effect, _player.global_position, 1, 1, 0, 0, BurningData.new())
				instance.call_deferred("init", _player)
				
				if _cast_timer.is_stopped():
					_cast_timer.start()
		
		if _can_fire or (temp_movement == Vector2.ZERO and _total_time > 0.3):
			fire_projectile()


func _on_CastTimer_timeout():
	_is_casting = false
	_can_fire = true


func fire_projectile()->void:
	_can_fire = false
	_is_skill_ready = false
	_is_casting = false
	
	_arrow_sprite.hide()
	
	_charge_bar.value = 0
	_charge_bar.max_value = _actual_enemy_needed
	_charge_hint.text = "0/" + str(_actual_enemy_needed)
	
	if not _cast_timer.is_stopped():
		_cast_timer.stop()
	
	clear_movement()
	lock_player(false)
	
	var stats = WeaponService.init_ranged_stats(_projectile_stats)
	var direction = (_arrow_sprite.global_position - _player.global_position).angle()
	var instance = WeaponService.manage_special_spawn_projectile(_player, stats, false, null, direction)
	instance.set_deferred("scale", Vector2(4, _width + 1))
	instance.call_deferred("set_damage", stats.damage * (_damage_charge / 100.0), stats.accuracy, stats.crit_chance, stats.crit_damage, stats.burning_data, stats.is_healing)

	_damage_charge = 0
	_total_time = 0
	_width = 6
	_arrow_sprite.scale.y = _width


func lock_player(enable:bool)->void:
	_player._move_locked = enable
	
	if enable:
		_player._current_movement = Vector2.ZERO


func clear_movement()->void:
	_current_movement = Vector2.ZERO
