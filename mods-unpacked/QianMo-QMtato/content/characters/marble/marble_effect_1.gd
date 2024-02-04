extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (PackedScene) var monitor_scene
export (int) var bonus_armor_while_dashing: = 15
export (int) var max_projectile: = 10
export (Resource) var projectile_stats:Resource
export (Resource) var exploding_stats:Resource

var _monitor_instance = null


func _on_qmtato_wave_start(player)->void:
	._on_qmtato_wave_start(player)
	
	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance.queue_free()
	_monitor_instance = monitor_scene.instance()
	_player.call_deferred("add_child", _monitor_instance)
	_monitor_instance.call_deferred("init", bonus_armor_while_dashing, max_projectile, projectile_stats, exploding_stats)


func get_args()->Array:
	var calculated_projectile_stats = WeaponService.init_ranged_stats(projectile_stats)
	var projectile_scaling_text = ""
	for stat in calculated_projectile_stats.scaling_stats:
		projectile_scaling_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	
	var explosion_stats = WeaponService.init_base_stats(exploding_stats, "", [], [ExplodingEffect.new()])
	var explosion_scaling_text = ""
	for stat in explosion_stats.scaling_stats:
		explosion_scaling_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	
	return [str(explosion_stats.damage), explosion_scaling_text, str(calculated_projectile_stats.damage), projectile_scaling_text, str(max_projectile)]
