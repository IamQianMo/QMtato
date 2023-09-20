extends Node


export (Resource) var exploding_effect

var _player:Player = null
var _wave_end: = false


func init(player)->void:
	_player = player


func _input(event):
	if RunData.effects["press_k_lose_health"] > 0 and not _wave_end:
		if event is InputEventKey and event.pressed:
			if event.scancode == KEY_K or event.scancode == KEY_SPACE:
				hurt_self()
		elif event is InputEventJoypadButton and event.is_pressed():
			if event.button_index == JOY_XBOX_A:
				hurt_self()


func hurt_self()->void:
	if not _player == null and is_instance_valid(_player):
		var dmg = max(1, _player.max_stats.health * RunData.effects["press_k_lose_health"] / 100.0) as int
		if _player.current_stats.health > dmg:
			var _error = _player.take_damage(dmg, null, false, false)
			
			dmg = RunData.get_dmg(Utils.get_stat("stat_max_hp")) as int
			var explosion_instance = explode(exploding_effect, _player.global_position, dmg, 1, 0, 0, RunData.effects["burn_chance"])
			_player.add_child(explosion_instance)


func explode(effect:Effect, pos:Vector2, damage:int, accuracy:float, crit_chance:float, crit_dmg:float, burning_data:BurningData, is_healing:bool = false, ignored_objects:Array = [], damage_tracking_key:String = "")->Node:
	var instance = effect.explosion_scene.instance()
	instance.set_deferred("global_position", pos)
	instance.set_deferred("sound_db_mod", effect.sound_db_mod)
	instance.call_deferred("set_damage_tracking_key", damage_tracking_key)
	instance.call_deferred("set_damage", damage, accuracy, crit_chance, crit_dmg, burning_data, is_healing, ignored_objects)
	instance.call_deferred("set_smoke_amount", round(effect.scale * effect.base_smoke_amount))
	instance.call_deferred("set_area", effect.scale)
	return instance
