extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (PackedScene) var puppet_area_scene
export (PackedScene) var monitor_scene
export (PackedScene) var mobile_scene
export (PackedScene) var range_scene
export (float) var chance: = 0.08
export (float) var health_factor: = 2.0
export (float) var damage_factor: = 2.0
export (float) var speed_factor: = 2.0
export (Array, Array) var health_scaling: = [["stat_max_hp", 1.0]]
export (Array, Array) var damage_scaling: = [["stat_melee_damage", 1.0]]
export (Array, Array) var speed_scaling: = [["stat_speed", 1.0]]
export (int) var max_puppets: = 8

var _controlling_enemies: = []
var _timer
var _entity_spawner:EntitySpawner = null
var _monitor_instance = null
var _mobile_button_instance = null
var _puppeteer_range_instance = null


func _on_qmtato_wave_start(player)->void:
	._on_qmtato_wave_start(player)
	
	_controlling_enemies.clear()
	_main = RunData.get_tree().current_scene
	_entity_spawner = _main._entity_spawner
	
	var _error = _entity_spawner.connect("enemy_spawned", self, "_on_enemy_spawned")
	
	var projectiles_node = RunData.get_tree().current_scene.get_node_or_null("Projectiles")
	connect_safely(projectiles_node, "child_entered_tree", self, "_on_node_added")
	
	if not _monitor_instance == null and is_instance_valid(_monitor_instance):
		_monitor_instance.queue_free()
	_monitor_instance = monitor_scene.instance()
	_player.add_child(_monitor_instance)
	_monitor_instance.init(self)
	
	if not _mobile_button_instance == null and is_instance_valid(_mobile_button_instance):
		_mobile_button_instance.queue_free()
	if is_mobile_device():
		_mobile_button_instance = mobile_scene.instance()
		var _main_ui = RunData.get_tree().current_scene.get_node("UI/DimScreen")
		_main_ui.add_child(_mobile_button_instance)
	
	if not _puppeteer_range_instance == null and is_instance_valid(_puppeteer_range_instance):
		_puppeteer_range_instance.queue_free()
	_puppeteer_range_instance = range_scene.instance()
	_puppeteer_range_instance.call_deferred("init", self)
	player.add_child(_puppeteer_range_instance)
	_puppeteer_range_instance.set_range()


func unapply()->void :
	.unapply()
	
	var projectiles_node = RunData.get_tree().current_scene.get_node_or_null("Projectiles")
	disconnect_safely(projectiles_node, "child_entered_tree", self, "_on_node_added")


func apply_targets()->void:
	_puppeteer_range_instance.apply_targets()


func get_control_mode()->bool:
	return _monitor_instance._control_mode


func get_enemies_in_range()->Array:
	return _puppeteer_range_instance.enemies_in_range


func _on_enemy_spawned(enemy)->void:
	if randf() > chance or enemy is Boss:
		return
	if _controlling_enemies.size() >= max_puppets:
		return
	
	control_enemy(enemy)


func control_enemy(enemy)->void:
	var hitbox = enemy.get("_hitbox")
	if not hitbox or not is_instance_valid(hitbox):
		return
	
	var attack_behavaior = enemy.get("_attack_behavior")
	if attack_behavaior and attack_behavaior is SpawningAttackBehavior:
		return
	
	var hurtbox = enemy.get("_hurtbox")
	_entity_spawner.enemies.erase(enemy)
	
	enemy.modulate = Color.blueviolet
	enemy.current_stats.speed *= get_speed_factor()
	enemy.max_stats.health *= get_health_factor()
	hitbox.damage *= get_damage_factor()
	enemy.current_stats.health = enemy.max_stats.health
	
	enemy.collision_layer = 1 << 1 | 1 << 10
	enemy.collision_mask = enemy.collision_mask | 1 << 10
	hitbox.collision_layer = 1 << 3
	hurtbox.collision_mask = 1 << 2 | 1 << 4
	hitbox.ignored_objects.push_back(enemy)
	
	var instance = puppet_area_scene.instance()
	instance.name = "puppet"
	enemy.call_deferred("add_child", instance)
	instance.call_deferred("init", _player, self)
	instance.call_deferred("change_control_mode", _monitor_instance._control_mode)
	
	_controlling_enemies.push_back([enemy, instance])
	enemy.connect("died", self, "_on_puppet_died", [instance])


func _on_node_added(node):
	if node is EnemyProjectile:
		yield(node, "ready")
		var hitbox = node._hitbox
		if hitbox == null or not is_instance_valid(hitbox):
			return
		
		for e in _controlling_enemies:
			hitbox.ignored_objects.push_back(e[0])
		hitbox.ignored_objects.push_back(_player)
			
		yield(RunData.get_tree().create_timer(0.05), "timeout")
		if not hitbox == null and is_instance_valid(hitbox):
			var from = hitbox.from
			if not from == null and is_instance_valid(from):
				var flag = false
				for e in _controlling_enemies:
					if from == e[0]:
						flag = true
						break
				if not flag:
					hitbox.ignored_objects.clear()
				else:
					node.modulate = Color.green
					hitbox.collision_layer = 1 << 3


func _on_puppet_died(body, puppet_instance)->void:
	_controlling_enemies.erase([body, puppet_instance])


func get_health_factor()->float:
	var base = health_factor
	
	for stat in health_scaling:
		base += Utils.get_stat(stat[0]) * stat[1]
		
	return base


func get_damage_factor()->float:
	var base = damage_factor
	
	for stat in damage_scaling:
		base += Utils.get_stat(stat[0]) * stat[1]
		
	return base


func get_speed_factor()->float:
	var base = speed_factor
	
	for stat in speed_scaling:
		base += Utils.get_stat(stat[0]) * stat[1]
		
	return base


func get_args()->Array:
	var prefix = "[color=#00ff00]"
	var suffix = "[/color]"
	var gray_prefix = "[color=#555555]"
	var gary_suffix = "[/color]"
	var chance_text = prefix + "%d%%" % (chance * 100) + suffix
	
	var scaling_text = ""
	for stat in health_scaling:
		scaling_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	var health_text = "%s%d%%%s %s| %d%%%s(%s)" % [prefix, get_health_factor() * 100, suffix, gray_prefix, health_factor * 100, gary_suffix, scaling_text]
	
	scaling_text = ""
	for stat in damage_scaling:
		scaling_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	var dmg_text = "%s%d%%%s %s| %d%%%s(%s)" % [prefix, get_damage_factor() * 100, suffix, gray_prefix, damage_factor * 100, gary_suffix, scaling_text]
	
	scaling_text = ""
	for stat in speed_scaling:
		scaling_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	var speed_text = "%s%d%%%s %s| %d%%%s(%s)" % [prefix, get_speed_factor() * 100, suffix, gray_prefix, speed_factor * 100, gary_suffix, scaling_text]
	
	var max_puppets_text = prefix + "%d" % (max_puppets) + suffix
	var key = "SPACE" if not InputService.using_gamepad else "A"
	key = prefix + key + suffix
	
	return [chance_text, health_text, dmg_text, speed_text, key, max_puppets_text]
