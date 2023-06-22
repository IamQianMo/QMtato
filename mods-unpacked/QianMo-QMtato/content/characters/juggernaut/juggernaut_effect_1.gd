extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (PackedScene) var monitor_scene
export (PackedScene) var mobile_scene

var _monitor_instance = null
var _mobile_button_instance = null


func _on_qmtato_wave_start(player)->void:
	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance.queue_free()
	_monitor_instance = monitor_scene.instance()
	player.add_child(_monitor_instance)
	_monitor_instance.init(player)
	
	if not _mobile_button_instance == null and is_instance_valid(_mobile_button_instance):
		_mobile_button_instance.queue_free()
	if is_mobile_device():
		_mobile_button_instance = mobile_scene.instance()
		var _main_ui = RunData.get_tree().current_scene.get_node("UI/DimScreen")
		_main_ui.add_child(_mobile_button_instance)


func get_args()->Array:
	
	var shorcut_key = "SPACE or F" if not InputService.using_gamepad else "A"
	
	var dmg = RunData.get_dmg(Utils.get_stat("stat_melee_damage")) as int
	var dmg_scaling_text = Utils.get_scaling_stat_text("stat_melee_damage", 1)
	
	var atk_speed = Utils.get_stat("stat_attack_speed") / 100.0
	
	var cooldown = 18 * (1 / (1 + atk_speed))
	if atk_speed < 0:
		cooldown = 18 * (1 + abs(atk_speed))
	var cooldown_text = "[color=#00ff00]%.1fs[/color]" % cooldown if cooldown <= 18 else "[color=red]%.1fs[/color]" % cooldown
	var cooldown_scaling_text = Utils.get_scaling_stat_text("stat_attack_speed", 1)
	
	return [shorcut_key, get_colored_text_by_value(dmg, 0), dmg_scaling_text, cooldown_text, cooldown_scaling_text]
