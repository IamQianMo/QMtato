extends "res://mods-unpacked/QianMo-QMtato/content/effects/fruit_trees/fruit.gd"


var _shader_progress: = 1.0
var _enemy_puppet_scene = null
var _consumable_to_spawn = null

export (Array, Resource) var turrets_effect


func _ready():
	_main = RunData.get_tree().current_scene
	rotation = 0


func _physics_process(delta):
	if not push_back and not _disabled:
		monitorable = false
		attracted_by = null
		
		var stat_name = _bonus_stats[0][0]
		if stat_name == "free_puppet" and not _enemy_puppet_scene:
			if randf() < 0.5:
				_enemy_puppet_scene = load("res://entities/units/enemies/005/5.tscn")
				call_deferred("set_texture", load("res://entities/units/enemies/005/5.png"))
			else:
				_enemy_puppet_scene = load("res://entities/units/enemies/018/18.tscn")
				call_deferred("set_texture", load("res://entities/units/enemies/018/18.png"))
		elif stat_name == "treasure_item_box" and not _consumable_to_spawn:
			_consumable_to_spawn = ItemService.item_box if randf() < 0.98 else ItemService.legendary_item_box
			call_deferred("set_texture", _consumable_to_spawn.icon)
		
		_shader_progress -= delta * 0.5
		sprite.material.set_shader_param("progress", _shader_progress)
		
		if _shader_progress <= 0:
			if stat_name == "free_turret":
				spawn_special_fruits(0)
			elif stat_name == "free_puppet":
				spawn_special_fruits(1)
			elif stat_name == "treasure_item_box":
				spawn_special_fruits(2)
			
			_main._consumables.erase(self)
			queue_free()


func pickup()->void :
	pass


func spawn_special_fruits(id:int):
	match id:
		0:
			var entity_spawner = _main._entity_spawner
			var struct = Utils.get_rand_element(turrets_effect)
			var pos = global_position
			
			entity_spawner.queue_to_spawn_structures.push_back([EntityType.STRUCTURE, struct.scene, pos, struct])
		1:
			var entity_spawner = _main._entity_spawner
			var scene = _enemy_puppet_scene
			var enemy = entity_spawner.spawn_entity(scene, global_position)
			entity_spawner.enemies.push_back(enemy)
			enemy.connect("died", entity_spawner, "_on_enemy_died")
			enemy.connect("wanted_to_spawn_an_enemy", entity_spawner, "on_enemy_wanted_to_spawn_an_enemy")
			entity_spawner.emit_signal("enemy_spawned", enemy)
			
			control_enemy(enemy)
		2:
			var dist = rand_range(0, 1)
			var consumable_scene = preload("res://items/consumables/consumable.tscn")
			var consumable = consumable_scene.instance()
			var consumable_to_spawn = ItemService.item_box if randf() < 0.98 else ItemService.legendary_item_box
			var pos = global_position
			consumable.consumable_data = consumable_to_spawn
			consumable.global_position = pos
			_main._consumables_container.call_deferred("add_child", consumable)
			consumable.call_deferred("set_texture", consumable_to_spawn.icon)
			var _error = consumable.connect("picked_up", _main, "on_consumable_picked_up")
			consumable.push_back_destination = Vector2(rand_range(pos.x - dist, pos.x + dist), rand_range(pos.y - dist, pos.y + dist))
			_main._consumables.push_back(consumable)


func control_enemy(enemy)->void:
	var hitbox = enemy._hitbox
	var hurtbox = enemy._hurtbox
	
	var entity_spawner = _main._entity_spawner
	entity_spawner.enemies.erase(enemy)
	
	enemy.modulate = Color.blueviolet
	enemy.current_stats.speed *= 3
	enemy.max_stats.health *= 3
	enemy.current_stats.health = enemy.max_stats.health
	
	var dmg = RunData.get_dmg(Utils.get_stat("stat_melee_damage") + Utils.get_stat("stat_ranged_damage") + Utils.get_stat("stat_elemental_damage") + hitbox.damage)
	hitbox.damage += dmg
	
	enemy.collision_layer = 1 << 1 | 1 << 10
	enemy.collision_mask = enemy.collision_mask | 1 << 10
	hitbox.collision_layer = 1 << 3
	hurtbox.collision_mask = 1 << 2 | 1 << 4
	hitbox.ignored_objects.push_back(enemy)
	
	var puppet_area_scene = preload("res://mods-unpacked/QianMo-QMtato/content/characters/puppeteer/puppet_area.tscn")
	var instance = puppet_area_scene.instance()
	instance.name = "fruit_puppet"
	enemy.call_deferred("add_child", instance)
	instance.call_deferred("init", _player, {"_controlling_enemies": [[enemy]]})
	instance.call_deferred("change_control_mode", false)


func _on_wavetimer_timeout()->void:
	._on_wavetimer_timeout()
	
	queue_free()


func _on_Timer_timeout():
	_current_growth += 0.2
	
	scale = Vector2(_current_growth, _current_growth) * 0.7
	
	if _current_growth >= 1.0:
		_timer.stop()
