extends "res://singletons/run_data.gd"


func init_tracked_effects()->Dictionary:
	var new_tracked_effects = {
		"character_average": 0,
		"character_juggernaut": 0,
		"character_neutralization": 0,
		"character_orchard_man": 0,
		"fruit_tree_stats_gained": {},
	}
	var vanilla_tracked_effects = .init_tracked_effects()
	
	vanilla_tracked_effects.merge(new_tracked_effects)
	return vanilla_tracked_effects


func init_effects()->Dictionary:
	var new_effects = {
		"qmtato_empty": 0,
		"deal_bonus_damage_by_stats": [[0, 0], [0, 0], [0, 0]],
		"sorted_damage_key": [],
		"character_average_bonus_attack_speed": 0,
		"press_k_lose_health": 0,
		"low_health_bonus": {},
		"low_health_bonus_calculated": {},
		"character_orchard_man": 0,
		"dig_speed": 0,
	}
	var vanilla_effects = .init_effects()
	
	vanilla_effects.merge(new_effects)
	return vanilla_effects


func init_stats(all_null_values:bool = false)->Dictionary:
	var new_stats = {
		"max_stats_difference": 0,
		"bonus_damage_by_stats_chance": 0,
	}
	var vanilla_stats = .init_stats(all_null_values)
	
	vanilla_stats.merge(new_stats)
	return vanilla_stats
