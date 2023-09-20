extends Effect

export (int) var chance: = 3


static func get_id()->String:
	return "chance_stat_damage"


func apply()->void :
	RunData.effects[custom_key].push_back([key, value, chance])


func unapply()->void :
	RunData.effects[custom_key].erase([key, value, chance])


func get_args()->Array:
	
	var dmg = value
	var scaling_text = ""
	
	if key != "":
		dmg = RunData.get_dmg((value / 100.0) * Utils.get_stat(key)) as int
		scaling_text = Utils.get_scaling_stat_text(key, value / 100.0)
	
	return [str(chance), str(dmg), scaling_text]


func serialize()->Dictionary:
	var serialized = .serialize()
	
	serialized.chance = chance
	
	return serialized


func deserialize_and_merge(serialized:Dictionary)->void :
	.deserialize_and_merge(serialized)
	
	chance = serialized.chance as int

