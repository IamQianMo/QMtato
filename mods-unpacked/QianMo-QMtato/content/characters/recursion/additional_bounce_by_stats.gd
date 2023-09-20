extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (Array, Array) var scaling_stats
export (int) var base_bounce: = 0


func unapply()->void :
	.unapply()
	
	var p_player = RunData.get_tree().current_scene._entity_spawner._player
	if not p_player == null and is_instance_valid(p_player):
		for weapon_instance in p_player.current_weapons:
			if not weapon_instance == null and is_instance_valid(weapon_instance) and weapon_instance is RangedWeapon:
				disconnect_safely(weapon_instance._shooting_behavior, "projectile_shot", self, "_on_player_projectile_shot")


func _on_qmtato_wave_start(player)->void:
	if RunData.get_tree().current_scene.name == "Shop":
		return
	
	._on_qmtato_wave_start(player)
	
	for weapon_instance in player.current_weapons:
		if not weapon_instance == null and is_instance_valid(weapon_instance) and weapon_instance is RangedWeapon:
			connect_safely(weapon_instance._shooting_behavior, "projectile_shot", self, "_on_player_projectile_shot")


func _on_player_projectile_shot(projectile)->void :
	if is_instance_valid(projectile):
		projectile.weapon_stats.bounce += get_bounce()


func get_args()->Array:
	var scaling_text = ""

	for scaling_stat in scaling_stats:
		scaling_text += Utils.get_scaling_stat_text(scaling_stat[0], scaling_stat[1])
	
	var bounce = get_bounce()
	var bounce_text = "[color=#00ff00]+" + str(bounce) if bounce >= 0 else "[color=red]" + str(bounce)
	bounce_text += "[color=#555555] | " + str(base_bounce) + "[/color][/color] "
	bounce_text += tr("BOUNCE")
		
	return [bounce_text, scaling_text]


func get_bounce()->int:
	var bounce = base_bounce
	
	for scaling_stat in scaling_stats:
		bounce += (RunData.effects[scaling_stat[0]] * scaling_stat[1]) as int
	
	return bounce
