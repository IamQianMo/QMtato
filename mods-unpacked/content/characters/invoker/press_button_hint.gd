class_name PressButtonHint
extends Node


signal button_changed(key, time, from)

export (Resource) var press_sound
export (Resource) var burst_sound
export (Resource) var mobile_button

onready var _timer:Timer = $Timer
onready var _hint:Label = $Hint
onready var _time_remain:Label = $TimeRemain

const trigger_key = {"J": KEY_J, "K": KEY_K, "L": KEY_L, "I": KEY_I, "A": JOY_XBOX_A, "B": JOY_XBOX_B, "X": JOY_XBOX_X, "Y": JOY_XBOX_Y}
const gamepad_key_list = ["A", "B", "X", "Y"]
const keyboard_key_list = ["J", "K", "L", "I"]
const KEY_MAP = {"up": "↑", "down": "↓", "left": "←", "right": "→"}

var _time_counted:float = 0
var _time_step:float = 0.1
var _max_time:float = 0
var _can_shot_skill = false
var _key:int = -1
var _player:Player = null
var _projectile_stats:RangedWeaponStats = null
var _converted_stats:RangedWeaponStats = null
var _projectile_count = 0
var _from = null
var _stat_damage = 0
var _last_key: = "right"

var _system_name: = "Windows"
var _mobile_button_instance:Button = null
var _is_mobile_device: = false


func _ready():
	var _error = connect("button_changed", self, "_on_button_changed")
	_error = _timer.connect("timeout", self, "_on_timer_timeout")
	_time_step = _timer.wait_time
	_hint.hide()
	_time_remain.hide()


func init(player:Player, projectile_stats:RangedWeaponStats)->void:
	_player = player
	_projectile_stats = projectile_stats
	_system_name = OS.get_name()
	if _system_name  == "Android" or _system_name == "iOS":
		_is_mobile_device = true
		if _mobile_button_instance == null or not is_instance_valid(_mobile_button_instance):
			_mobile_button_instance = mobile_button.instance()
			_mobile_button_instance.hide()
		
			var _main_ui = RunData.get_tree().current_scene.get_node("UI/DimScreen")
			_main_ui.add_child(_mobile_button_instance)


func _on_button_changed(key:String, time:float, from)->void:
	if time <= 0:
		_hint.hide()
		_time_remain.hide()
		if _is_mobile_device:
			_mobile_button_instance.hide()
		if not _timer.is_stopped():
			_timer.stop()
			return
			
	if key in trigger_key.keys():
		_key = trigger_key[key]
	else:
		return
	
	_last_key = key
	_from = from
	_hint.text = get_key(key)
	_max_time = time
	_can_shot_skill = true
	_converted_stats = _projectile_stats.duplicate()
	for stat_key_value in _projectile_stats.scaling_stats:
		_converted_stats.damage += (RunData.get_dmg((stat_key_value[1]) * Utils.get_stat(stat_key_value[0]))) as int
		
	_hint.show()
	_time_remain.show()
	if _is_mobile_device:
		_mobile_button_instance.show()
		
	_timer.start(0)


func _on_timer_timeout()->void:
	_time_counted += _time_step
	if _time_counted > _max_time:
		stop_timer()
	else:
		_time_remain.text = ("%.1f" % (_max_time - _time_counted)) + "s"


func _unhandled_input(event):
	if _can_shot_skill:
		if event.is_pressed():
			if event is InputEventKey:
				if event.scancode == _key:
					stop_timer(true)
					SoundManager2D.play(press_sound, _player.global_position, 5, 0.5)
				elif event.scancode in trigger_key.values():
					stop_timer()
			elif event is InputEventJoypadButton:
				if event.button_index == _key:
					stop_timer(true)
					SoundManager2D.play(press_sound, _player.global_position, 5, 0.5)
				elif event.button_index in trigger_key.values():
					stop_timer()


func stop_timer(can_shot_skill:float = false)->void:
	_timer.stop()
	_time_counted = 0
	_can_shot_skill = can_shot_skill
	
	if can_shot_skill:
		var rand_key = ""
		if not InputService.using_gamepad:
			rand_key = Utils.get_rand_element(keyboard_key_list)
		else:
			rand_key = Utils.get_rand_element(gamepad_key_list)
		_max_time *= 0.8
		_key = trigger_key[rand_key]
		
		_hint.text = get_key(rand_key)
		
		_projectile_count += 1
		
		if _last_key == "L" or _last_key == "B":
			fire_projectile(0, _converted_stats.damage / 2)
		elif _last_key == "K" or _last_key == "A":
			fire_projectile(PI * 0.5, _converted_stats.damage / 2)
		elif _last_key == "J" or _last_key == "X":
			fire_projectile(PI, _converted_stats.damage / 2)
		elif _last_key == "I" or _last_key == "Y":
			fire_projectile(PI * 1.5, _converted_stats.damage / 2)
		
		_last_key = rand_key
		
		_timer.start(0)
	else:
		_hint.hide()
		_time_remain.hide()
		if _is_mobile_device:
			_mobile_button_instance.hide()
		_from._is_in_skill = false
		_from._killed = 0
		burst_projectiles(_projectile_count)
		_projectile_count = 0


func burst_projectiles(count:int)->void:
	_from._killed = 0
	if count > 0:
		var rotation = rand_range(- PI, PI)
		for _i in count:
			var _error = WeaponService.spawn_projectile(rotation, _converted_stats, _player.global_position, Vector2.ONE.rotated(rotation), true)
			rotation = rand_range(- PI, PI)
		SoundManager2D.play(burst_sound, _player.global_position, 5, 0.5)


func fire_projectile(rotation:float, damage:int)->void:
	var stat = _converted_stats.duplicate()
	stat.damage = damage
	var _error = WeaponService.spawn_projectile(rotation, stat, _player.global_position, Vector2.RIGHT.rotated(rotation), true)


func get_key(key:String)->String :
	if key in KEY_MAP.keys():
		return KEY_MAP[key]
	else:
		return key
