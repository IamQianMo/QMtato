extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (Array, Array) var scaling_stats
export (float) var base_bonus: = 0.7
export (PackedScene) var target_crosshair
export (PackedScene) var mobile_scene

var monitor_scene = preload("res://mods-unpacked/QianMo-QMtato/content/characters/recursion/recursion_monitor.gd")
var _monitor_instance = null
var _mobile_button_instance = null

var _is_elite_wave: = false
var _is_focus_mode: = true
var _bosses_in_range = []


func unapply()->void :
	.unapply()
	
	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance.queue_free()
		_monitor_instance = null
		
	if not _mobile_button_instance == null and is_instance_valid(_mobile_button_instance):
		_mobile_button_instance.queue_free()
		_mobile_button_instance = null
	
	var p_player = RunData.get_tree().current_scene._entity_spawner._player
	if not p_player == null and is_instance_valid(p_player):
		for weapon_instance in p_player.current_weapons:
			if not weapon_instance == null and is_instance_valid(weapon_instance) and weapon_instance is RangedWeapon:
				disconnect_safely(weapon_instance._shooting_behavior, "projectile_shot", self, "_on_player_projectile_shot")
				disconnect_safely(weapon_instance._range, "body_entered", self, "_on_enemy_entered_range")
				disconnect_safely(weapon_instance._range, "body_exited", self, "_on_enemy_exited_range")


func _on_qmtato_wave_start(player:Player)->void:
	if RunData.get_tree().current_scene.name == "Shop":
		return
	
	._on_qmtato_wave_start(player)
	
	_bosses_in_range.clear()
	_is_elite_wave = false
	_is_focus_mode = true
	
	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance.queue_free()
	_monitor_instance = monitor_scene.new()
	player.add_child(_monitor_instance)
	_monitor_instance.init(self)
	
	if not _mobile_button_instance == null and is_instance_valid(_mobile_button_instance):
		_mobile_button_instance.queue_free()
	if is_mobile_device():
		_mobile_button_instance = mobile_scene.instance()
		var _main_ui = RunData.get_tree().current_scene.get_node("UI/DimScreen")
		_main_ui.add_child(_mobile_button_instance)
	
	_main = RunData.get_tree().current_scene
	var _entity_spawner = _main._entity_spawner
	if _main._is_elite_wave or _main.is_last_wave() or _entity_spawner.queue_to_spawn_bosses.size() > 0 or _entity_spawner.bosses.size() > 0 and _is_focus_mode:
		_is_elite_wave = true
	else:
		_is_elite_wave = false
	
	for boss in _entity_spawner.bosses:
		_on_enemy_entered_range(boss)
	
	for weapon_instance in player.current_weapons:
		if not weapon_instance == null and is_instance_valid(weapon_instance) and weapon_instance is RangedWeapon:
			connect_safely(weapon_instance._shooting_behavior, "projectile_shot", self, "_on_player_projectile_shot", [weapon_instance])
			
			if _is_elite_wave:
				connect_safely(weapon_instance._range, "body_entered", self, "_on_enemy_entered_range")
				connect_safely(weapon_instance._range, "body_exited", self, "_on_enemy_exited_range")


func set_focus_mode()->bool:
	_is_focus_mode = not _is_focus_mode
	
	if not _is_focus_mode and _bosses_in_range.size() > 0:
		for boss in _bosses_in_range:
			_on_enemy_exited_range(boss)
	
	return _is_focus_mode


func _on_enemy_entered_range(body:Node)->void :
	if body is Boss and not _bosses_in_range.has(body):
		_bosses_in_range.push_back(body)
		
		_is_elite_wave = true
		var target_crosshair_instance = target_crosshair.instance()
		target_crosshair.name = "QMtatoTargetCrosshair"
		body.add_child(target_crosshair_instance)


func _on_enemy_exited_range(body:Node)->void :
	if body is Boss:
		_bosses_in_range.erase(body)
		
		if _bosses_in_range.size() == 0:
			_is_elite_wave = false
		
		var crosshair = body.get_node_or_null("QMtatoTargetCrosshair")
		if not crosshair == null and is_instance_valid(crosshair):
			crosshair.queue_free()


func _on_player_projectile_shot(projectile, weapon_instance)->void :
	if not projectile == null and is_instance_valid(projectile):
		var bonus = get_bonus() / 100
		projectile.weapon_stats.bounce_dmg_reduction -= bonus
		
		if not _is_elite_wave or not _is_focus_mode:
			projectile.connect("hit_something", self, "_on_projectile_hit_something", [projectile])
		else:
			projectile.connect("hit_something", self, "_on_projectile_hit_something_elite_wave", [projectile, max(0, projectile.weapon_stats.bounce - 4), weapon_instance])


func _on_projectile_hit_something(thing_hit, _damage_dealt, projectile)->void :
	if is_instance_valid(projectile):
		projectile.weapon_stats.lifesteal *= 0.8
		
		var _damage_bonus = -projectile._hitbox.damage * projectile.weapon_stats.bounce_dmg_reduction
		if _damage_bonus < 1:
			projectile._hitbox.damage += 1
			
		if projectile.weapon_stats.bounce <= 0:
			var target = _player
			var direction = (target.global_position - thing_hit.global_position).angle() if target != null and thing_hit != null and is_instance_valid(thing_hit) else rand_range( - PI, PI)
			if randf() <= 0.3:
				direction = -direction
			projectile.velocity = Vector2.RIGHT.rotated(direction) * projectile.velocity.length()
			projectile.rotation = projectile.velocity.angle()
			projectile.weapon_stats.piercing += 999
			projectile.weapon_stats.piercing_dmg_reduction = min(0, projectile.weapon_stats.piercing_dmg_reduction)
			projectile.modulate = Color.red
			projectile.disconnect("hit_something", self, "_on_projectile_hit_something")


func _on_projectile_hit_something_elite_wave(thing_hit, _damage_dealt, projectile, max_bounce, _weapon_instance)->void :
	if is_instance_valid(projectile):
		projectile.weapon_stats.lifesteal *= 0.8
		
		var _damage_bonus = -projectile._hitbox.damage * projectile.weapon_stats.bounce_dmg_reduction
		if _damage_bonus < 1:
			projectile._hitbox.damage += 1
			
		if projectile.weapon_stats.bounce <= max_bounce:
			var target = null
			
			if _bosses_in_range.size() > 0:
				target = Utils.get_rand_element(_bosses_in_range)
			else:
				target = _player
				
			projectile.weapon_stats.bounce = 0
			var direction = (target.global_position - thing_hit.global_position).angle() if target != null and thing_hit != null and is_instance_valid(thing_hit) else rand_range( - PI, PI)
			projectile.velocity = Vector2.RIGHT.rotated(direction) * projectile.velocity.length()
			projectile.rotation = projectile.velocity.angle()
			projectile.weapon_stats.piercing += 999
			projectile.weapon_stats.piercing_dmg_reduction = min(0, projectile.weapon_stats.piercing_dmg_reduction)
			projectile.modulate = Color.red
			projectile.disconnect("hit_something", self, "_on_projectile_hit_something_elite_wave")


func get_args()->Array:
	var scaling_text = ""

	for scaling_stat in scaling_stats:
		scaling_text += Utils.get_scaling_stat_text(scaling_stat[0], scaling_stat[1])
	
	var bonus = get_bonus()
	var bounce_text = "[color=#00ff00]+" + "%.1f%%" % bonus if bonus >= 0 else "[color=red]" + "%.1f%%" % bonus
	bounce_text += "[/color]"
	bounce_text += "[color=#555555] | " + "%.1f%%" % (base_bonus * 100) + "[/color] "
		
	return [bounce_text, scaling_text]


func get_bonus()->float :
	var bonus: = base_bonus
	
	for scaling_stat in scaling_stats:
		bonus += RunData.effects[scaling_stat[0]] * scaling_stat[1]
	
	return bonus * 100
