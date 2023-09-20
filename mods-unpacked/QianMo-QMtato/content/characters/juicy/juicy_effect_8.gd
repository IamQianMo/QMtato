extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (Resource) var target_item
export (float) var extra_gold_lose: = 0.5
export (float) var level_factor: = 0.5
export (Array, Array) var lack_punishment_stats: = [["stat_percent_damage", 5]]
export (PackedScene) var hud_scene:PackedScene

var _floating_text_manager = null
var _no_item: = false
var _hud_instance = null


func _on_qmtato_wave_start(player)->void :
	_no_item = false
	
	_main = RunData.get_tree().current_scene
	connect_safely(player, "took_damage", self, "_on_player_took_damage")
	var wave_timer = _main._wave_timer
	connect_safely(wave_timer, "timeout", self, "_on_wave_timer_timeout")
	connect_safely(RunData, "levelled_up", self, "_on_leveled_up")
	
	_floating_text_manager = _main._floating_text_manager
	
	var life_bar_container = _main._life_bar.get_parent()
	_hud_instance = hud_scene.instance()
	life_bar_container.add_child(_hud_instance)
	life_bar_container.move_child(_hud_instance, 2)
	
	_hud_instance.set_max_value(get_level_required())
	_hud_instance.set_value(RunData.get_nb_item("item_lemonade"))


func unapply()->void :
	.unapply()
	
	disconnect_safely(RunData, "levelled_up", self, "_on_leveled_up")


func _on_leveled_up()->void :
	if _hud_instance and is_instance_valid(_hud_instance):
		_hud_instance.set_max_value(get_level_required())


func _on_wave_timer_timeout()->void :
	var item_num = RunData.get_nb_item(target_item.my_id, false)
	if item_num < get_level_required():
		for stat in lack_punishment_stats:
			RunData.remove_stat(stat[0], stat[1])


func _on_player_took_damage(_unit, _value, _knockback_direction, _knockback_amount, _is_crit, is_miss, is_dodge, is_protected, _effect_scale, _hit_type)->void :
	if is_miss or is_dodge or is_protected:
		return
	
	var count_left = value
	
	if not _no_item:
		var items_to_be_removed: = []
		var items = RunData.items
		
		for item in items:
			if item.my_id == target_item.my_id:
				items_to_be_removed.push_back(item)
				count_left -= 1
				if count_left <= 0:
					break
		for item in items_to_be_removed:
			RunData.remove_item(item)
			_floating_text_manager.display_icon(-1, target_item.icon, _floating_text_manager.stat_pos_sounds, _floating_text_manager.stat_neg_sounds, _player.global_position - Vector2(0, 50), _floating_text_manager.direction, -15.0)
		
		if not items_to_be_removed.empty():
			_hud_instance.set_value(RunData.get_nb_item("item_lemonade", false))
		
		_main.reload_stats()
	
	for _i in count_left:
		var item_value = (ItemService.get_value(RunData.current_wave, target_item.value, false, target_item is WeaponData, target_item.my_id) * (1.0 + extra_gold_lose)) as int
		RunData.emit_signal("stat_removed", "stat_materials", item_value, - 15.0)
		RunData.gold -= item_value
		RunData.emit_signal("gold_changed", RunData.gold)
	
	if count_left < value:
		if LinkedStats.update_on_gold_chance:
			LinkedStats.reset()
	
	if count_left == value:
		_no_item = true


func get_args()->Array :
	var punishment_level_text:String = get_colored_text_by_sign(str(get_level_required()), 1) + get_colored_text_by_sign(" (" + Utils.get_scaling_stat_text("stat_levels", level_factor) + ")", 0)
	var punishment_stats_text:String = ""
	for stat in lack_punishment_stats:
		punishment_stats_text += "[color=red]%s %s[/color] & " % [stat[1], tr(stat[0].to_upper())]
	punishment_stats_text = punishment_stats_text.trim_suffix(" & ")
	
	var item_value = (ItemService.get_value(RunData.current_wave, target_item.value, false, target_item is WeaponData, target_item.my_id) * (1.0 + extra_gold_lose)) as int
	
	return [tr(target_item.name), str(value), "%.0f%% (%d)" % [(1.0 + extra_gold_lose) * 100.0, item_value], punishment_level_text, punishment_stats_text]


func get_level_required()->int :
	return (RunData.current_level * level_factor) as int
