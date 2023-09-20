extends "res://items/global/effect.gd"


const DEFAULT_STAT_LIST = ["stat_melee_damage", "stat_ranged_damage", "stat_elemental_damage", "stat_engineering"]


func apply()->void :
	pass


func unapply()->void :
	pass


func get_args()->Array:
	
	var small_icon:Texture
	var w = 20 * ProgressData.settings.font_size
	var text:String = "("
	var sorted_damage_keys = RunData.effects["sorted_damage_key"]
	
	if sorted_damage_keys.size() == 0:
		sorted_damage_keys = DEFAULT_STAT_LIST
	for stat_name in sorted_damage_keys:
		small_icon = ItemService.get_stat_small_icon(stat_name)
		text += "[img=%sx%s]%s[/img] " % [w, w, small_icon.resource_path]
		
	text = text.trim_suffix(" ") + ")"
	
	return [str(RunData.effects["character_average_bonus_attack_speed"]), text]
	
