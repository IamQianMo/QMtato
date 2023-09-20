extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"

export (Resource) var mobile_button
export (Resource) var berserker_monitor

var _wave_timer = null

var _monitor_instance = null

var _mobile_button_instance = null
var _system_name: = "Windows"


func get_args()->Array:
	var dmg = (RunData.get_dmg(Utils.get_stat("stat_max_hp"))) as int
	var scaling_text = Utils.get_scaling_stat_text("stat_max_hp", 1)
	return [str(value), "[color=#00ff00]K or SPACE[/color]" if not InputService.using_gamepad else "[color=#00ff00]A[/color]", str(dmg), scaling_text] 


func _on_qmtato_wave_start(player)->void:
	._on_qmtato_wave_start(player)
	
	_wave_timer = RunData.get_tree().current_scene._wave_timer
	connect_safely(_wave_timer, "timeout", self, "_on_wave_timer_timeout")

	_system_name = OS.get_name()
	if _system_name  == "Android" or _system_name == "iOS":
		if _mobile_button_instance == null or not is_instance_valid(_mobile_button_instance):
			_mobile_button_instance = mobile_button.instance()
			
			var _main_ui = RunData.get_tree().current_scene.get_node("UI/DimScreen")
			_main_ui.add_child(_mobile_button_instance)
	
	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance.queue_free()
	_monitor_instance = berserker_monitor.instance()
	_monitor_instance.init(_player)
	
	_player.add_child(_monitor_instance)

	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance._wave_end = false


func apply()->void :
	RunData.effects[key] += value


func unapply()->void :
	.unapply()
	
	RunData.effects[key] -= value
	
	if not _mobile_button_instance == null and is_instance_valid(_mobile_button_instance):
		_mobile_button_instance.queue_free()
		_mobile_button_instance = null

	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance.queue_free()
		_monitor_instance = null

	disconnect_safely(_wave_timer, "timeout", self, "_on_wave_timer_timeout")


func _on_wave_timer_timeout()->void:
	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance._wave_end = true
