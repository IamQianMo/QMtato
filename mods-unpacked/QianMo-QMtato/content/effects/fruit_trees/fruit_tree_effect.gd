extends "res://effects/items/turret_effect.gd"


export (bool) var is_random: = true
export (Array, Array) var bonus_stats: = [["stat_luck", 5, 1], ["stat_range", 5, 1]]


static func get_id()->String:
	return "fruit_tree"


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.is_random = is_random
	serialized.bonus_stats = bonus_stats
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	is_random = serialized.is_random
	bonus_stats = serialized.bonus_stats


func get_args()->Array :
	var spawn_cd = stats.cooldown
		
	if RunData.effects["structures_cooldown_reduction"].size() > 0:
		spawn_cd = Utils.apply_cooldown_reduction(spawn_cd, RunData.effects["structures_cooldown_reduction"])
	
	var bonus_text: = ""
	var split_text = ""
	
	if is_random:
		bonus_text += "[color=yellow]" + tr("RANDOM_TEXT") + "[/color] "
		split_text = "[color=white] | [/color]"
	else:
		split_text = "[color=white] & [/color]"
	
	var total_weight:float = 0
	
	var actual_stats = bonus_stats.duplicate(true)
	if is_random:
		var luck = Utils.get_stat("stat_luck") / 100.0
		if luck < 0:
			luck = 1 / (abs(luck) + 1)
		else:
			luck += 1.0
		for i in actual_stats.size():
			var stat_name = actual_stats[i][0]
			if actual_stats[i][1] > 0:
				if stat_name == "number_of_enemies" or stat_name == "enemy_speed":
					total_weight += actual_stats[i][2]
					continue
				actual_stats[i][2] *= luck
			total_weight += actual_stats[i][2]
	
	var chance:float = 0
	for stat in actual_stats:
		if not is_random:
			chance = 100
		else:
			chance = stat[2] / total_weight * 100
		
		if stat[1] >= 0:
			if stat[0] == "number_of_enemies" or stat[0] == "enemy_speed":
				bonus_text += "[color=red]+%d %s[/color](%.1f%%)%s" % [stat[1], tr(stat[0].to_upper()), chance, split_text] 
			else:
				bonus_text += "[color=#00ff00]+%d %s[/color](%.1f%%)%s" % [stat[1], tr(stat[0].to_upper()), chance, split_text] 
		else:
			if stat[0] == "number_of_enemies" or stat[0] == "enemy_speed":
				bonus_text += "[color=#00ff00]%d %s[/color](%.1f%%)%s" % [stat[1], tr(stat[0].to_upper()), chance, split_text] 
			else:
				bonus_text += "[color=red]%d %s[/color](%.1f%%)%s" % [stat[1], tr(stat[0].to_upper()), chance, split_text] 
	bonus_text = bonus_text.trim_suffix(split_text)
	
	if is_random:
		bonus_text += tr("FRUIT_LUCK_CHANCE")
		
	bonus_text += "\n" + tr("FRUIT_TREE_REDUCE_EFFECT_WHEN_GAME_ENDED")
		
	if RunData.tracked_item_effects["fruit_tree_stats_gained"].has(key):
		var tracked_stats = RunData.tracked_item_effects["fruit_tree_stats_gained"][key]
		var stats_list = ""
		for stat in tracked_stats:
			var stat_value = stat[1]
			var stat_name = tr(stat[0].to_upper())
			stats_list += "+%d %s & " % [stat_value, stat_name] if stat_value >= 0 else "%d %s & " % [stat_value, stat_name]
		bonus_text += "\n[color=#%s]%s" % [Utils.SECONDARY_FONT_COLOR.to_html(), tr("STATS_GAINED").replace("{0}", stats_list)]
		bonus_text = bonus_text.trim_suffix(" & ")
		bonus_text += "[/color]"
	
	return ["%.1f" % (spawn_cd / 60.0), bonus_text]
