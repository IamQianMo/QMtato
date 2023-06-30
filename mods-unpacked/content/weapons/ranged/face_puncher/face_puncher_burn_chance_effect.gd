extends NullEffect


export (String) var weapon_data_path:String = ""
export (float) var chance: = 1.0
export (float) var scale_factor: = 0.8
export (int) var duration: = 3

var weapon_data = null


func get_args()->Array:
	var current_stats = get_weapon_stats()
	var damage = max(1, current_stats.damage * scale_factor) as int
	
	return ["[color=#00ff00]" + str(chance * 100) + "%[/color]", "[color=#00ff00]" + str(scale_factor * 100) + "%[/color]", "[color=#00ff00]" + str(duration) + "[/color]", str(damage)]


func get_weapon_stats()->WeaponStats :
	if not weapon_data:
		weapon_data = load(weapon_data_path)
	
	var current_stats
	
	if weapon_data.type == weapon_data.Type.MELEE:
		current_stats = WeaponService.init_melee_stats(weapon_data.stats, weapon_data.weapon_id, weapon_data.sets, weapon_data.effects)
	else :
		current_stats = WeaponService.init_ranged_stats(weapon_data.stats, weapon_data.weapon_id, weapon_data.sets, weapon_data.effects)

	return current_stats
