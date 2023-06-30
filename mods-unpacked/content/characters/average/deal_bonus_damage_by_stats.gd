extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"

enum PickValueSign {LOW, MID, HIGH}

export (PickValueSign) var pick_value_sign = PickValueSign.LOW
export (int) var chance: = 0
export (String) var unique_key: = ""

var explosion_scene = preload("res://projectiles/explosion.tscn")
var exploding_effect = ExplodingEffect.new()
var index = 0
var stats_added_queue: = []


func apply()->void :
	if pick_value_sign == PickValueSign.MID:
		index = 1
	elif pick_value_sign == PickValueSign.HIGH:
		index = 2
	else:
		index = 0
	
	RunData.effects[unique_key][index][0] = value
	RunData.effects[unique_key][index][1] += chance


func unapply()->void :
	.unapply()
	
	if pick_value_sign == PickValueSign.MID:
		index = 1
	elif pick_value_sign == PickValueSign.HIGH:
		index = 2
	else:
		index = 0
	
	RunData.effects[unique_key][index][0] -= value
	RunData.effects[unique_key][index][1] -= chance
	
	disconnect_safely(RunData, "stat_added", self, "_on_stat_changed")
	disconnect_safely(RunData, "stat_removed", self, "_on_stat_changed")
	disconnect_safely(TempStats, "temp_stat_updated", self, "_on_stat_changed")
	disconnect_safely(LinkedStats, "linked_stat_updated", self, "_on_stat_changed")
	
	disconnect_safely(RunData, "levelled_up", self, "_on_levelled_up")
	
	var p_player = RunData.get_tree().current_scene._entity_spawner._player
	if not p_player == null and is_instance_valid(p_player):
		for weapon_instance in p_player.current_weapons:
			if weapon_instance is MeleeWeapon:
				disconnect_safely(weapon_instance._hitbox, "hit_something", self, "_on_player_hit_something")
			elif weapon_instance is RangedWeapon:
				disconnect_safely(weapon_instance._shooting_behavior, "projectile_shot", self, "_on_player_projectile_shot")


func _on_qmtato_wave_start(player)->void:
	._on_qmtato_wave_start(player)
	
	var _error = get_max_difference()
	
	for weapon_instance in player.current_weapons:
		if weapon_instance is MeleeWeapon:
			connect_safely(weapon_instance._hitbox, "hit_something", self, "_on_player_hit_something")
		elif weapon_instance is RangedWeapon:
			connect_safely(weapon_instance._shooting_behavior, "projectile_shot", self, "_on_player_projectile_shot")
	
	connect_safely(RunData, "stat_added", self, "_on_stat_changed")
	connect_safely(RunData, "stat_removed", self, "_on_stat_changed")
	connect_safely(TempStats, "temp_stat_updated", self, "_on_stat_changed")
	connect_safely(LinkedStats, "linked_stat_updated", self, "_on_stat_changed")
	
	connect_safely(RunData, "levelled_up", self, "_on_levelled_up")
		
	stats_added_queue.clear()
	
	var wave_timer = RunData.get_tree().current_scene._wave_timer
	if not wave_timer.is_connected("timeout", self, "_on_wave_timer_timeout"):
		wave_timer.connect("timeout", self, "_on_wave_timer_timeout")


func _on_levelled_up()->void:
	var random_key = Utils.get_rand_element(RunData.effects["sorted_damage_key"])
	if random_key == "stat_melee_damage":
		stats_added_queue.push_back([random_key, 2])
	else:
		stats_added_queue.push_back([random_key, 1])


func _on_wave_timer_timeout()->void:
	for stat in stats_added_queue:
		RunData.add_stat(stat[0], stat[1])
		

func _on_stat_changed(_stat_name:String, _value:int, _db_mod:float = 0.0):
	var difference = get_max_difference()
	
	RunData.effects["max_stats_difference"] = difference
	RunData.effects["bonus_damage_by_stats_chance"] = -(difference * 3)
	
	if difference % 3 == 0:
		var bonus_atk_speed = 0
		
		if difference == 0:
			bonus_atk_speed = 120
		else:
			bonus_atk_speed = 10 * RunData.effects["max_stats_difference"]
		
		if RunData.effects["character_average_bonus_attack_speed"] <= 0:
			RunData.effects["character_average_bonus_attack_speed"] = bonus_atk_speed
			RunData.effects["explosion_damage"] += RunData.effects["character_average_bonus_attack_speed"]
		elif bonus_atk_speed > RunData.effects["character_average_bonus_attack_speed"]:
			RunData.effects["explosion_damage"] -= RunData.effects["character_average_bonus_attack_speed"]
			RunData.effects["character_average_bonus_attack_speed"] = bonus_atk_speed
			RunData.effects["explosion_damage"] += RunData.effects["character_average_bonus_attack_speed"]
	else:
		RunData.effects["explosion_damage"] -= RunData.effects["character_average_bonus_attack_speed"]
		RunData.effects["character_average_bonus_attack_speed"] = 0


func _on_player_projectile_shot(projectile)->void :
	if is_instance_valid(projectile):
		var _error = projectile.connect("hit_something", self, "_on_player_hit_something")


func _on_player_hit_something(thing_hit, _damage_dealt)->void :
	var dmg_key = RunData.effects["sorted_damage_key"][index]
	var total_dmg_to_deal = 0
	var _chance = chance + RunData.effects["bonus_damage_by_stats_chance"]
	
	if randf() <= _chance / 100.0:
		var dmg = (RunData.get_dmg((value / 100.0) * Utils.get_stat(dmg_key))) as int
		total_dmg_to_deal += dmg

	if total_dmg_to_deal <= 0 or thing_hit == null or not is_instance_valid(thing_hit):
		return
	
	total_dmg_to_deal = (total_dmg_to_deal * (1 + (RunData.effects["explosion_damage"] / 100.0))) as int
	exploding_effect.explosion_scene = explosion_scene
	exploding_effect.sound_db_mod = -5
	exploding_effect.scale = 0.7 * (1 + (RunData.effects["explosion_size"] / 100.0))
	exploding_effect.base_smoke_amount = 15
	
	RunData.tracked_item_effects["character_average"] += total_dmg_to_deal
	
	var _error_explosion = WeaponService.explode(exploding_effect, thing_hit.global_position, total_dmg_to_deal, 1, Utils.get_stat("stat_crit_chance") / 100.0, 2, RunData.effects["burn_chance"])


func get_args()->Array:
	
	var dmg = value
	var scaling_text = ""
	var temp_chance = chance
	
	key = get_damage_type_key()
	if key == null:
		key = "stat_melee_damage"
	dmg = (RunData.get_dmg((value / 100.0) * Utils.get_stat(key)) * (1 + (RunData.effects["explosion_damage"] / 100.0))) as int
	scaling_text = Utils.get_scaling_stat_text(key, value / 100.0)
	
	temp_chance += RunData.effects["bonus_damage_by_stats_chance"]
	
	return [str(temp_chance), str(dmg), scaling_text]


func get_damage_type_key()->String:
	if pick_value_sign == PickValueSign.MID:
		index = 1
	elif pick_value_sign == PickValueSign.HIGH:
		index = 3
	else:
		index = 0
	
	if not RunData.effects["sorted_damage_key"].empty():
		return RunData.effects["sorted_damage_key"][index]
	else:
		return "stat_melee_damage"


func get_max_difference()->int:
	var _stats_list = [
		["stat_melee_damage", Utils.get_stat("stat_melee_damage")],
		["stat_ranged_damage", Utils.get_stat("stat_ranged_damage")],
		["stat_elemental_damage", Utils.get_stat("stat_elemental_damage")],
		["stat_engineering", Utils.get_stat("stat_engineering")]
	]
	
	_stats_list.sort_custom(MyCustomSorter, "sort_ascending")
	
	RunData.effects["sorted_damage_key"].clear()
	for i in _stats_list:
		RunData.effects["sorted_damage_key"].push_back(i[0])
	
	RunData.current_character.wanted_tags.clear()
	RunData.current_character.wanted_tags = [_stats_list[0][0]]
	
	return (_stats_list[3][1] - _stats_list[0][1]) as int
	
	
class MyCustomSorter:
	static func sort_ascending(a, b):
		if a[1] < b[1]:
			return true
		return false
