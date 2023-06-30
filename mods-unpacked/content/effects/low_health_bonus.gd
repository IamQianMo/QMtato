extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"

export (Array, Array) var bonus_key_value

var _wave_timer:WaveTimer = null

var _is_wave_ended: = false


func apply()->void :
	for key_value in bonus_key_value:
		if RunData.effects[key].has(key_value[0]):
			RunData.effects[key][key_value[0]][1] += key_value[1]
		else:
			RunData.effects[key][key_value[0]] = key_value[1]


func unapply()->void :
	.unapply()
	
	for key_value in bonus_key_value:
		if RunData.effects[key].has(key_value[0]):
			RunData.effects[key][key_value[0]][1] -= key_value[1]
	
	disconnect_safely(_wave_timer, "timeout", self, "_on_wave_timer_timeout")


func _on_wave_timer_timeout()->void:
	_is_wave_ended = true
	
	if RunData.effects["low_health_bonus"].size() > 0:
		for stat_key in RunData.effects["low_health_bonus_calculated"].keys():
			RunData.effects[stat_key] -= RunData.effects["low_health_bonus_calculated"][stat_key]
			RunData.effects["low_health_bonus_calculated"][stat_key] = 0


func _on_qmtato_wave_start(player)->void:
	._on_qmtato_wave_start(player)
	
	_is_wave_ended = false
	
	if RunData.effects["low_health_bonus"].size() > 0:
		for stat_key in RunData.effects["low_health_bonus_calculated"].keys():
			RunData.effects["low_health_bonus_calculated"][stat_key] = 0
		player.emit_signal("health_updated", player.current_stats.health, player.max_stats.health)
	
	_wave_timer = RunData.get_tree().current_scene._wave_timer
	
	connect_safely(_wave_timer, "timeout", self, "_on_wave_timer_timeout")
	connect_safely(player, "health_updated", self, "_on_player_health_updated")


func _on_player_health_updated(current_health, max_health)->void:
	if not _is_wave_ended and RunData.effects["low_health_bonus"].size() > 0:
		for stat_key in RunData.effects["low_health_bonus_calculated"].keys():
				RunData.effects[stat_key] -= RunData.effects["low_health_bonus_calculated"][stat_key]
				
		var percent_health_remain = current_health * 100.0 / max_health
		percent_health_remain = 100 - percent_health_remain
		for stat_key in RunData.effects["low_health_bonus"].keys():
			RunData.effects["low_health_bonus_calculated"][stat_key] = (percent_health_remain * max_health / 50.0 * RunData.effects["low_health_bonus"][stat_key]) as int
			RunData.effects[stat_key] += RunData.effects["low_health_bonus_calculated"][stat_key]
		
		if RunData.effects["torture"] <= 0:
			_player._health_regen_timer.wait_time = RunData.get_hp_regeneration_timer(Utils.get_stat("stat_hp_regeneration") as int)


func get_args()->Array:
	
	var small_icon:Texture
	var w = 20 * ProgressData.settings.font_size
	var text:String = ""
	
	if RunData.effects[key].empty():
		for key_value in bonus_key_value:
			small_icon = ItemService.get_stat_small_icon(key_value[0])
			text += "[color=#00ff00]+0[/color]%s[img=%sx%s]%s[/img]|" % [tr(key_value[0].to_upper()), w, w, small_icon.resource_path]
		text = text.trim_suffix("|")
		return [text]
	if RunData.effects["low_health_bonus_calculated"].size() > 0:
		for cal_key in RunData.effects["low_health_bonus_calculated"].keys():
			small_icon = ItemService.get_stat_small_icon(cal_key)
			text += "[color=#00ff00]+%s[/color]%s[img=%sx%s]%s[/img]|" % [str(RunData.effects["low_health_bonus_calculated"][cal_key]), tr(cal_key.to_upper()), w, w, small_icon.resource_path]
	else:
		for stat_key in RunData.effects["low_health_bonus"].keys():
			small_icon = ItemService.get_stat_small_icon(stat_key)
			text += "[color=#00ff00]+0[/color]%s[img=%sx%s]%s[/img]|" % [tr(stat_key.to_upper()), w, w, small_icon.resource_path]
		
	text = text.trim_suffix("|")
		
	return [text]
