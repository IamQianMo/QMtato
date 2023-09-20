extends "res://mods-unpacked/QianMo-QMtato/content/effects/fruit_trees/fruit.gd"


export (Array, Resource) var weapon_datas

var _currrent_stats
var _effects


func _ready():
	var weapon_data = Utils.get_rand_element(weapon_datas)
	_currrent_stats = weapon_data.stats
	_effects = weapon_data.effects
	
	call_deferred("set_texture", weapon_data.icon)


func pickup()->void:
	if RunData.effects["character_orchard_man"] > 0:
		RunData.tracked_item_effects["character_orchard_man"] += 1
		
		for i in RunData.effects["character_orchard_man"]:
			if randf() > 0.25:
				continue
				
			for stat in _bonus_stats:
				var stat_value = stat[1]
				
				if _wave_ended:
					stat_value = max(1, stat_value / 2.0) as int
				
				if stat[0] == "bullet_fruit_bullet":
					spawn_projectiles(stat_value)
				else:
					if stat_value >= 0:
						RunData.add_stat(stat[0], stat_value)
					else:
						RunData.remove_stat(stat[0], -stat_value)
	
	for stat in _bonus_stats:
		var stat_value = stat[1]
		
		if _wave_ended:
			stat_value = max(1, stat_value / 2.0) as int
		
		if stat[0] == "bullet_fruit_bullet":
			spawn_projectiles(stat_value)
		else:
			if stat_value >= 0:
				RunData.add_stat(stat[0], stat_value)
			else:
				RunData.remove_stat(stat[0], -stat_value)
	
	SoundManager.play(Utils.get_rand_element(consumable_data.pickup_sounds))
	emit_signal("picked_up", self)
	queue_free()


func spawn_projectiles(num)->void:
	var stats = WeaponService.init_ranged_stats(_currrent_stats, "", [], _effects)
	var degree_step = 2 * PI / num
	var projectile_rotation = 0
	for i in num:
		projectile_rotation += degree_step

		var knock_back_direction = Vector2.RIGHT.rotated(projectile_rotation)
		var _error_instance = WeaponService.spawn_projectile(projectile_rotation, stats, global_position, knock_back_direction, true, _effects)
