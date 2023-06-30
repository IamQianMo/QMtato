extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (PackedScene) var monitor_scene
export (Resource) var projectile_stats:Resource
export (int) var enemy_needed: = 15
export (int) var enemy_needed_increase_per_wave: = 5

var _monitor_instance = null


func _on_qmtato_wave_start(player)->void:
	._on_qmtato_wave_start(player)
	
	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance.queue_free()
	_monitor_instance = monitor_scene.instance()
	_player.call_deferred("add_child", _monitor_instance)
	_monitor_instance.call_deferred("init", projectile_stats, enemy_needed, enemy_needed_increase_per_wave)


func get_args()->Array:
	var stats = WeaponService.init_ranged_stats(projectile_stats)
	var scaling_text = ""
	for stat in stats.scaling_stats:
		scaling_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	var actual_enemy_needed = RunData.current_wave * enemy_needed_increase_per_wave + enemy_needed
	return [str(actual_enemy_needed), str(stats.damage), scaling_text]
