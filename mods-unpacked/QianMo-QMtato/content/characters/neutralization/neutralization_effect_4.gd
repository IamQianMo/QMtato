extends Effect


func apply()->void:
	RunData.effects["stat_melee_damage"] += value
	RunData.effects["stat_ranged_damage"] += value
	RunData.effects["stat_elemental_damage"] += value
	RunData.effects["stat_engineering"] += value


func unapply()->void:
	RunData.effects["stat_melee_damage"] -= value
	RunData.effects["stat_ranged_damage"] -= value
	RunData.effects["stat_elemental_damage"] -= value
	RunData.effects["stat_engineering"] -= value


func get_args()->Array:
	return [str(value)]
