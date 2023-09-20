extends NullEffect


export (float) var max_duration: = 5.0
export (int) var max_projectiles_num: = 2


func get_args()->Array :
	var atk_spd = Utils.get_stat("stat_attack_speed") / 100.0
	var current_cooldown:float = value
	var color_prefix = "[color="
	if atk_spd > 0:
		current_cooldown = max(2, value * (1 / (1 + atk_spd))) as int
	else :
		current_cooldown = max(2, value * (1 + abs(atk_spd))) as int
	
	if current_cooldown > value:
		color_prefix += "red]"
	else:
		color_prefix += "#00ff00]"
	
	var atk_delay = current_cooldown / 60.0
	
	return ["%s%.2fs[/color]" % [color_prefix, atk_delay], str(max_duration), str(max_projectiles_num)]
