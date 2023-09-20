extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (Array, PackedScene) var enemy_scenes

var _timer:Timer = null
var _wave_timer:Timer = null
var _is_elite_spawned:bool = false
var _entity_spawner = null
var _wave_manager = null
var _elite_enemy = null
var _weapons_list:Dictionary = {}
var _is_wave_ended: = false


func _on_qmtato_wave_start(player)->void:
	._on_qmtato_wave_start(player)
	
	_is_elite_spawned = false
	_is_wave_ended = false
	
	_timer = Timer.new()
	_timer.autostart = true
	_timer.wait_time = 1
	_timer.one_shot = false
	player.add_child(_timer)
	connect_safely(_timer, "timeout", self, "_on_timer_timeout")
	
	_main = RunData.get_tree().current_scene
	_wave_timer = _main._wave_timer
	_entity_spawner = _main._entity_spawner
	_wave_manager = _main._wave_manager
	
	_player.connect("died", self, "_on_player_died")
	
	_weapons_list.clear()


func _on_player_died(player)->void :
	var burning_timer = player.get_node_or_null("BurningTimer")
	if burning_timer and is_instance_valid(burning_timer):
		if not burning_timer.is_stopped():
			burning_timer.stop()


func _on_timer_timeout()->void :
	if _wave_timer.time_left <= 5.0:
		_wave_timer.start(25)
		_timer.stop()
		disconnect_safely(_timer, "timeout", self, "_on_timer_timeout")
		
		duel_time()


func duel_time()->void :
	_main._cleaning_up = true
	clean_up_entity_spawner()
	_wave_manager.clean_up_room()
	
	_main._cleaning_up = false
	
	var all_weapons = ItemService.weapons
	var wave_unit_data = WaveUnitData.new()
	wave_unit_data.type = WaveUnitData.Type.ENEMY
	wave_unit_data.unit_scene = Utils.get_rand_element(enemy_scenes)
	wave_unit_data.min_number = 1
	wave_unit_data.max_number = 1
	wave_unit_data.spawn_chance = 1
	var group_data = WaveGroupData.new()
	group_data.repeating = -1
	group_data.wave_units_data = [wave_unit_data]
	
	var group_pos:Vector2 = _entity_spawner.get_group_pos(group_data)
	var spawn_pos = _entity_spawner.get_spawn_pos_in_area(group_pos, group_data.area, group_data.spawn_dist_away_from_edges, group_data.spawn_edge_of_map)
	_entity_spawner.spawn([[wave_unit_data.type, wave_unit_data.unit_scene, spawn_pos]])
	connect_safely(_entity_spawner, "enemy_spawned", self, "_on_enemy_spawned")
	
	connect_safely(_wave_timer, "timeout", self, "_on_wave_timer_timeout")


func clean_up_entity_spawner()->void :
	_entity_spawner._cleaning_up = true
	_entity_spawner._structure_timer.stop()
	
	_entity_spawner.queue_to_spawn.clear()
	_entity_spawner.queue_to_spawn_bosses.clear()
	_entity_spawner.queue_to_spawn_structures.clear()
	_entity_spawner.queue_to_spawn_summons.clear()
	_entity_spawner.queue_to_spawn_trees.clear()
	
	for birth in _entity_spawner.births:
		if birth:
			birth.call_deferred("queue_free")
	_entity_spawner.births.clear()
	
#	for boss in bosses:
#		boss.die(Vector2.ZERO, _cleaning_up)
	
	for enemy in _entity_spawner.enemies:
		enemy.die(Vector2.ZERO, true)
	_entity_spawner.enemies.clear()
	
	for neutral in _entity_spawner.neutrals:
		neutral.die(Vector2.ZERO, true)
	_entity_spawner.neutrals.clear()
	
	for structure in _entity_spawner.structures:
		structure.die(Vector2.ZERO, true)
	_entity_spawner.structures.clear()
	
	_entity_spawner._cleaning_up = false


func _on_wave_timer_timeout()->void :
	_main._cleaning_up = true
	if _elite_enemy and is_instance_valid(_elite_enemy):
		_elite_enemy.die(Vector2.ZERO, true)
	
	_is_wave_ended = true


func _on_enemy_spawned(enemy)->void :
	if _is_elite_spawned:
		enemy.die(Vector2.ZERO, true)
		return
	
	_is_elite_spawned = true
	
	_elite_enemy = enemy
	
	_entity_spawner.births.clear()
	_entity_spawner.enemies.clear()
	
	_player.stats.knockback_resistance = 0.75
	
	enemy.max_stats.health = enemy.max_stats.health * 0.35 + Utils.get_stat("stat_max_hp") * (RunData.current_wave * 0.75 + 10)
	enemy.current_stats.health = enemy.max_stats.health
	enemy.emit_signal("health_updated", enemy.current_stats.health, enemy.max_stats.health)
	enemy.current_stats.speed = min(enemy.current_stats.speed * 0.75, _player.current_stats.speed * 0.75)
	
	enemy.connect("died", self, "_on_enemy_died")
	add_weapon(Utils.get_rand_element(ItemService._tiers_data[ItemData.Tier.RARE][ItemService.TierData.WEAPONS]), enemy)


func _on_enemy_died(enemy)->void :
	if not _is_wave_ended:
		_wave_timer.start(1.1)
		_is_wave_ended = true
	
	if _weapons_list.has(enemy):
		if _weapons_list[enemy] and is_instance_valid(_weapons_list[enemy]):
			_weapons_list[enemy].queue_free()


func setup_weapon(instance)->void :
	var range2d:Area2D = instance._range
	range2d.collision_mask = 1 << 1
	var hitbox = instance._hitbox
	hitbox.collision_layer = 1 << 4
	
	if instance is RangedWeapon:
		instance._shooting_behavior.connect("projectile_shot", self, "_on_projectile_shot")
		
	instance._parent = _player
	
	var current_stats = instance.current_stats
	current_stats.max_range *= 1.25
	current_stats.damage = max(1, current_stats.damage * 0.2) as int
	hitbox.set_damage(current_stats.damage, current_stats.accuracy, current_stats.crit_chance, current_stats.crit_damage, current_stats.burning_data, current_stats.is_healing)
	
	instance._range_shape.shape.radius *= 1.25


func add_weapon(weapon, parent)->void :
	var instance = weapon.scene.instance()
	
	_weapons_list[parent] = instance
	
	instance.weapon_pos = 0
	instance.stats = weapon.stats.duplicate()
	instance.stats.accuracy *= 0.5
	instance.weapon_id = weapon.weapon_id
	instance.tier = weapon.tier
	instance.weapon_sets = weapon.sets
	
	instance.call_deferred("init_stats", true)
	call_deferred("setup_weapon", instance)
	
	for effect in weapon.effects:
		var duplicated_effect = effect.duplicate()
		instance.effects.push_back(duplicated_effect)

		if not duplicated_effect.get_id().find("qmtato_effect") == -1:
			duplicated_effect._on_qmtato_wave_start(_player)
		elif not duplicated_effect.get_id().find("VLM_effect") == -1:
			duplicated_effect.on_wave_start(_player)
	
	parent.add_child(instance)
	
	var instance_position:Vector2 = parent.global_position
	instance.apply_scale(Vector2(1.2, 1.2))
	instance_position.x += 30 if rand_range(0, 1) < 0.5 else -30
	instance_position.y -= rand_range(-50, 50)
	instance.global_position = instance_position


func _on_projectile_shot(projectile:Node2D)->void :
	if is_instance_valid(projectile):
		projectile.velocity *= 0.85
		projectile.modulate = Color.red
		
		var hitbox = projectile.get_node_or_null("Hitbox")
		if is_instance_valid(hitbox):
			hitbox.collision_layer = 1 << 4
