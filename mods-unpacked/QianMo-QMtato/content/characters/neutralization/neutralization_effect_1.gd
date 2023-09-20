extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


signal toggle_changed


export (PackedScene) var monitor_scene
export (PackedScene) var enemy_monitor_scene
export (PackedScene) var ui_scene
export (float) var change_toggle_time: = 1.0
export (Array, Array) var scaling_stats
export (int) var base_damage: = 10
export (float) var enemy_bonus_speed: = 50.0
export (float) var cooldown_scaling: = 0.5
export (int) var skill_count_needed: = 50

var _monitor_instance = null
var _ui_instance = null
var _targeted_objects: = {}
var _floating_text_manager:FloatingTextManager = null
var _entity_spawner:EntitySpawner = null

var _black_and_white_toggle: = false

var _current_cooldown: = 6.0
var _kill_count: = 0


func _on_qmtato_wave_start(player)->void:
	._on_qmtato_wave_start(player)
	
	_black_and_white_toggle = false
	
	_kill_count = 0
	
	_main = RunData.get_tree().current_scene
	_floating_text_manager = _main._floating_text_manager
	_entity_spawner = _main._entity_spawner
	
	_targeted_objects.clear()
	
	for weapon_instance in player.current_weapons:
		if weapon_instance is MeleeWeapon:
			connect_safely(weapon_instance._hitbox, "hit_something", self, "_on_player_hit_something")
		elif weapon_instance is RangedWeapon:
			connect_safely(weapon_instance._shooting_behavior, "projectile_shot", self, "_on_player_projectile_shot")
	
	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance.queue_free()
	_monitor_instance = monitor_scene.instance()
	
	var atk_speed: = Utils.get_stat("stat_attack_speed") * cooldown_scaling / 100.0
	if atk_speed >= 0:
		atk_speed = 1 / (1 + atk_speed)
	else:
		atk_speed = 1 + abs(atk_speed)

	_current_cooldown = change_toggle_time * atk_speed
	_monitor_instance.call_deferred("init", self, _current_cooldown)
	player.call_deferred("add_child", _monitor_instance)
	
	if not _ui_instance == null and is_instance_valid(_ui_instance):
		_ui_instance.queue_free()
	_ui_instance = ui_scene.instance()
	var _main_ui = RunData.get_tree().current_scene.get_node("UI/DimScreen")
	_main_ui.call_deferred("add_child", _ui_instance)
	
	connect_safely(self, "toggle_changed", self, "_on_toggle_changed")


func unapply()->void:
	.unapply()
	
	var p_player = RunData.get_tree().current_scene._entity_spawner._player
	if not p_player == null and is_instance_valid(p_player):
		for weapon_instance in p_player.current_weapons:
			if weapon_instance is MeleeWeapon:
				disconnect_safely(weapon_instance._hitbox, "hit_something", self, "_on_player_hit_something")
			elif weapon_instance is RangedWeapon:
				disconnect_safely(weapon_instance._shooting_behavior, "projectile_shot", self, "_on_player_projectile_shot")


func _on_player_projectile_shot(projectile)->void :
	if is_instance_valid(projectile):
		projectile.connect("hit_something", self, "_on_player_hit_something")


func _on_player_hit_something(thing_hit, _damage_dealt)->void:
	if thing_hit.dead:
		return
	
	add_mark(thing_hit, _black_and_white_toggle)


func _on_bagua_exiting(thing_hit)->void:
	if _targeted_objects.has(thing_hit):
		var _error = _targeted_objects.erase(thing_hit)


func _on_monitor_hit_something(thing_hit)->void:
	add_mark(thing_hit, true if randf() < 0.5 else false)


func add_mark(thing_hit, mark:bool)->void:
	if not is_instance_valid(thing_hit):
		return
	
	if thing_hit.dead and _targeted_objects.has(thing_hit):
		var instance = _targeted_objects[thing_hit]
		if is_instance_valid(instance):
			instance.queue_free()
	
	if not _targeted_objects.has(thing_hit):
		var instance = enemy_monitor_scene.instance()
		instance.call_deferred("init", mark, scaling_stats, base_damage, enemy_bonus_speed)
		thing_hit.call_deferred("add_child", instance)
		instance.name = "QMtatoBaguaMonitor"
		instance.connect("killed_by_mark", self, "_on_killed_by_mark")
		instance.connect("tree_exiting", self, "_on_bagua_exiting", [thing_hit])
		instance.connect("hit_something", self, "_on_monitor_hit_something")
		
		_targeted_objects[thing_hit] = instance
	else:
		var instance = _targeted_objects[thing_hit]
		
		if is_instance_valid(instance):
			instance.emit_signal("toggle_changed", mark)


func _on_killed_by_mark()->void:
	_kill_count += 1
	
	if _kill_count >= skill_count_needed:
		_kill_count = 0
		
		_player.on_healing_effect(_player.max_stats.health * 0.5)
		var enemies = _entity_spawner.get_all_enemies()
		if not enemies.empty():
			for e in enemies:
				e.take_damage(max(1, e.current_stats.health * 0.5) as int)
				
	_ui_instance.emit_signal("kill_count_changed", _kill_count)


func _on_toggle_changed()->void:
	_black_and_white_toggle = not _black_and_white_toggle
	
	_ui_instance.emit_signal("toggle_changed", _black_and_white_toggle)
	
	if _black_and_white_toggle:
		_floating_text_manager.display("阳", _player.global_position, Color.white)
	else:
		_floating_text_manager.display("阴", _player.global_position, Color.gray)


func get_args()->Array:
	var dmg:float = base_damage
	var scaling_text = ""
	var cooldown_scaling_text = Utils.get_scaling_stat_text("stat_attack_speed", cooldown_scaling)
	
	for stat in scaling_stats:
		dmg += Utils.get_stat(stat[0]) * stat[1]
		scaling_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	dmg = RunData.get_dmg(dmg) as int
	
	var dmg_text = "[color=red]%d[/color]" % [dmg] if dmg < base_damage else "[color=#00ff00]%d[/color]" % [dmg]
	var cooldown_text = "[color=red]%.1fs[/color]" % [_current_cooldown] if _current_cooldown > change_toggle_time else "[color=#00ff00]%.1fs[/color]" % [_current_cooldown]
	
	return [cooldown_text, dmg_text, str(base_damage), scaling_text, str(enemy_bonus_speed), cooldown_scaling_text, str(skill_count_needed)]
