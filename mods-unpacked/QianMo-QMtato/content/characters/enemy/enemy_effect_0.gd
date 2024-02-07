extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (bool) var remove_current_weapons: = true
export (Array, Resource) var ranged_weapons: Array = []
export (Array, Resource) var melee_weapons: Array = []
export (Dictionary) var enemy_types: Dictionary = {} # should be {$type$: $texture$}
export (float) var weapon_need_melee_damage: float = 10.0
export (float) var weapon_need_ranged_damage: float = 5.0
export (int) var additional_weapons_count: int = 1


func _on_qmtato_wave_start(player)->void :
	._on_qmtato_wave_start(player)
	
	var current_weapons: Array = player.current_weapons
	if remove_current_weapons:
		for weapon in current_weapons:
			if is_instance_valid(weapon):
				weapon.queue_free()
		current_weapons.clear()
	
	var animation: Node2D = player.get_node("Animation")
	var sprite: Sprite = animation.get_node("Sprite")
	
	var type: String
	var melee_damage: = Utils.get_stat("stat_melee_damage")
	var ranged_damage: = Utils.get_stat("stat_ranged_damage")
	
	if ranged_damage > melee_damage:
		type = "ranged"
	else:
		type = "melee"
	sprite.texture = enemy_types[type]
	
	if type == "ranged":
		add_ranged_weapon()
	else:
		add_melee_weapon()
	
	player._legs.hide()
	
	var melee_weapons_count: int = max(1, ceil(melee_damage / weapon_need_melee_damage))
	var ranged_weapons_count: int = max(1, ceil(ranged_damage / weapon_need_ranged_damage))
	
	var weapons: Array = []
	for i in melee_weapons_count:
		weapons.append(Utils.get_rand_element(melee_weapons))
	for i in ranged_weapons_count:
		weapons.append(Utils.get_rand_element(ranged_weapons))
	
	weapons.shuffle()
	
	add_random_weapon(weapons)


func add_melee_weapon()->void :
	var current_weapons: Array = _player.current_weapons
	
	_player.add_weapon(Utils.get_rand_element(melee_weapons), current_weapons.size())


func add_ranged_weapon()->void :
	var current_weapons: Array = _player.current_weapons
	
	_player.add_weapon(Utils.get_rand_element(ranged_weapons), current_weapons.size())


func add_random_weapon(weapons: Array)->void :
	var current_weapons: Array = _player.current_weapons
	
	for weapon in weapons:
		_player.add_weapon(weapon, current_weapons.size())


func get_args()->Array :
	var melee_data = melee_weapons[0]
	var ranged_data = ranged_weapons[0]
	
	var ranged_damage_text: = tr("STAT_RANGED_DAMAGE")
	var melee_damage_text: = tr("STAT_MELEE_DAMAGE")
	
	var melee_damage: = Utils.get_stat("stat_melee_damage")
	var ranged_damage: = Utils.get_stat("stat_ranged_damage")
	var melee_weapons_count: int = max(1, ceil(melee_damage / weapon_need_melee_damage))
	var ranged_weapons_count: int = max(1, ceil(ranged_damage / weapon_need_ranged_damage))
	
	return [
		melee_data.get_weapon_stats_text(), 
		ranged_data.get_weapon_stats_text(), 
		ranged_damage_text, 
		melee_damage_text, 
		str(weapon_need_melee_damage),
		str(weapon_need_ranged_damage), 
		str(additional_weapons_count), 
		str(ranged_weapons_count),
		str(melee_weapons_count)]
