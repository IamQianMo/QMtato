extends "res://main.gd"


func _ready():
	var event_listener = ProgressData.get_node_or_null("QmtatoMainEventListener")
	
	if event_listener:
		event_listener.emit_signal("player_spawned", _player)


func _on_EntitySpawner_enemy_spawned(enemy)->void :
	var _error_died = enemy.connect("died", self, "_on_enemy_died")
	var _error_took_damage = enemy.connect("took_damage", _screenshaker, "_on_unit_took_damage")
	var _error_stats_boost = enemy.connect("stats_boosted", _effects_manager, "on_enemy_stats_boost")
	var _error_heal = enemy.connect("healed", _effects_manager, "on_enemy_healed")
	var _error_speed_removed = enemy.connect("speed_removed", _effects_manager, "on_enemy_speed_removed")
	var _error_state_changed = enemy.connect("state_changed", _floating_text_manager, "on_enemy_state_changed")
	connect_visual_effects(enemy)
	RunData.current_living_enemies += 1

	if _update_stats_on_enemies_changed and _update_stats_on_enemies_changed_timer.is_stopped():
		reload_stats()
		_update_stats_on_enemies_changed_timer.start()


func _on_enemy_died(enemy)->void :
	RunData.current_living_enemies -= 1

	if _update_stats_on_enemies_changed and _update_stats_on_enemies_changed_timer.is_stopped():
		reload_stats()
		_update_stats_on_enemies_changed_timer.start()

	if not _cleaning_up:
		if enemy is Boss:
			if RunData.effects["double_boss"]:
				_nb_bosses_killed_this_wave += 1

			if RunData.current_wave < RunData.nb_of_waves:
				_elite_killed = true

			if (_nb_bosses_killed_this_wave >= 2 or not RunData.effects["double_boss"]) and RunData.current_wave == RunData.nb_of_waves:

				if RunData.is_endless_run:
					var additional_groups = ZoneService.get_additional_groups(int((RunData.current_wave / 10.0) * 3))
					for i in additional_groups.size():
						additional_groups[i].spawn_timing = _wave_timer.wait_time - _wave_timer.time_left + i

					_wave_manager.add_groups(additional_groups)

				else :
					_wave_timer.wait_time = 0.1
					_wave_timer.start()


		if RunData.effects["dmg_when_death"].size() > 0:
			var dmg_taken = handle_stat_damages(RunData.effects["dmg_when_death"])
			RunData.tracked_item_effects["item_cyberball"] += dmg_taken[1]


		if RunData.effects["projectiles_on_death"].size() > 0:
			for proj_on_death_effect in RunData.effects["projectiles_on_death"]:
				for i in proj_on_death_effect[0]:
					var stats = proj_on_death_effect[1]

					if _proj_on_death_stat_cache.has(i):
						stats = _proj_on_death_stat_cache[i]
					else :
						stats = WeaponService.init_ranged_stats(proj_on_death_effect[1])
						_proj_on_death_stat_cache[i] = stats

					var _projectile = WeaponService.manage_special_spawn_projectile(
						enemy, 
						stats, 
						proj_on_death_effect[2], 
						_entity_spawner, 
						rand_range( - PI, PI), 
						"item_baby_with_a_beard"
					)

		RunData.handle_explosion("explode_on_death", enemy.global_position)

		spawn_loot(enemy, EntityType.ENEMY)

		ProgressData.add_data("enemies_killed")
