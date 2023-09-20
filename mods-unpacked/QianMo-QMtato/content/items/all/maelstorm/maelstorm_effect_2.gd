extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (float) var chance = 0.24
export (Resource) var projectile_stats

var _entity_spawner:EntitySpawner = null


func unapply()->void :
	.unapply()
	
	var p_player = RunData.get_tree().current_scene._entity_spawner._player
	if not p_player == null and is_instance_valid(p_player):
		for weapon_instance in p_player.current_weapons:
			if weapon_instance is MeleeWeapon:
				disconnect_safely(weapon_instance._hitbox, "hit_something", self, "_on_player_hit_something")
			elif weapon_instance is RangedWeapon:
				disconnect_safely(weapon_instance._shooting_behavior, "projectile_shot", self, "_on_player_projectile_shot")


func _on_qmtato_wave_start(player):
	._on_qmtato_wave_start(player)
	
	_entity_spawner = RunData.get_tree().current_scene._entity_spawner
	
	for weapon_instance in player.current_weapons:
		if weapon_instance is MeleeWeapon:
			connect_safely(weapon_instance._hitbox, "hit_something", self, "_on_player_hit_something")
		elif weapon_instance is RangedWeapon:
			connect_safely(weapon_instance._shooting_behavior, "projectile_shot", self, "_on_player_projectile_shot")


func _on_player_projectile_shot(projectile)->void :
	if is_instance_valid(projectile):
		var _error = projectile.connect("hit_something", self, "_on_player_hit_something")


func _on_player_hit_something(thing_hit, _damage_dealt)->void:
	if randf() < chance:
		var stats = WeaponService.init_ranged_stats(projectile_stats)
		var enemies = _entity_spawner.get_all_enemies()
		
		if enemies.size() > 0:
			var target = Utils.get_rand_element(enemies)
			var rotation = (target.global_position - thing_hit.global_position).angle()
			var _error = WeaponService.spawn_projectile(rotation, stats, thing_hit.global_position, Vector2.ZERO, true)


func get_args()->Array:
	var stats = WeaponService.init_ranged_stats(projectile_stats)
	var scaling_icon = ""
	
	var dmg = 0
	for scaling_stat in stats.scaling_stats:
		dmg += RunData.get_dmg(Utils.get_stat(scaling_stat[0]) * scaling_stat[1])
		scaling_icon += Utils.get_scaling_stat_text(scaling_stat[0], scaling_stat[1])
	
	return [str(chance * 100), str(dmg), scaling_icon, str(stats.bounce)]
