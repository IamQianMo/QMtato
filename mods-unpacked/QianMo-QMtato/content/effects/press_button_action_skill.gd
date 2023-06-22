extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"

export (PackedScene) var scene
export (Resource) var projectile_stat

var _is_in_skill = false
var _killed = 0
var _hint_instance = null
var _entity_spawner
var _wave_timer

const trigger_key = ["J", "K", "L", "I"]
const gamepad_trigger_key = ["A", "B", "X", "Y"]


func apply()->void:
	_is_in_skill = false
	_killed = 0
	

func unapply()->void:
	.unapply()
	
	if not _hint_instance == null and is_instance_valid(_hint_instance):
		if not _hint_instance._mobile_button_instance == null and is_instance_valid(_hint_instance._mobile_button_instance):
			_hint_instance._mobile_button_instance.queue_free()
		_hint_instance.queue_free()
		_hint_instance = null
	
	disconnect_safely(_entity_spawner, "enemy_spawned", self, "_on_enemy_spawned")
	disconnect_safely(_wave_timer, "timeout", self, "_on_wave_timer_timeout")


func get_args()->Array:
	var scaling_text = ""
	var dmg = projectile_stat.damage
	var icon_list = []
	
	for stat_key_value in projectile_stat.scaling_stats:
		dmg += (RunData.get_dmg((stat_key_value[1]) * Utils.get_stat(stat_key_value[0]))) as int
		icon_list.append(Utils.get_scaling_stat_text(stat_key_value[0], stat_key_value[1]))
		
	scaling_text += "[color=#00ff00]%d[/color][color=#555555] | %d[/color] (" % [dmg, projectile_stat.damage]
	
	for i in icon_list:
		scaling_text += i
		
	scaling_text += ")"
	
	return [str(value + (RunData.current_wave * 2)), scaling_text]


func _on_qmtato_wave_start(player)->void:
	if RunData.get_tree().current_scene.name == "Shop":
		return
	
	._on_qmtato_wave_start(player)
	
	if _hint_instance == null or not is_instance_valid(_hint_instance):
		_hint_instance = scene.instance()
		_hint_instance.init(player, projectile_stat)
		player.add_child(_hint_instance)
	
	_entity_spawner = RunData.get_tree().current_scene._entity_spawner
	_wave_timer = RunData.get_tree().current_scene._wave_timer
	
	connect_safely(_entity_spawner, "enemy_spawned", self, "_on_enemy_spawned")
	connect_safely(_wave_timer, "timeout", self, "_on_wave_timer_timeout")
		
	_is_in_skill = false
	_killed = 0


func _on_wave_timer_timeout()->void:
	_hint_instance.stop_timer()
	_is_in_skill = false


func _on_enemy_spawned(enemy)->void:
	enemy.connect("died", self, "_on_enemy_died")


func _on_enemy_died(_enemy)->void:
	_killed += 1
	if _killed >= (value + (RunData.current_wave * 2)) and not _is_in_skill:
		_is_in_skill = true
		_killed = 0
		
		_hint_instance.emit_signal("button_changed", Utils.get_rand_element(trigger_key if not InputService.using_gamepad else gamepad_trigger_key), 3, self)
