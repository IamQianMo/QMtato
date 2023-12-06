extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


signal dig_completed(area_instance)

export (float) var dig_time: = 5.0

var area_scene = preload("res://mods-unpacked/QianMo-QMtato/content/effects/treasure_area/area_scene.tscn")
var consumable_scene = load("res://items/consumables/consumable.tscn")
var unit_stats = load("res://entities/units/neutral/tree_stats.tres").duplicate()
var fake_unit = preload("res://mods-unpacked/QianMo-QMtato/content/effects/treasure_area/treasure_fake_unit.tscn")
var _area_instances: = []
var _floating_text_manager = null
var _zone_min_pos
var _zone_max_pos
var _area_number: = 0


static func get_id()->String:
	return "qmtato_effect_treasure_area"


func _on_qmtato_wave_start(player:Player)->void :
	._on_qmtato_wave_start(player)
	
	_main = RunData.get_tree().current_scene
	_floating_text_manager = _main._floating_text_manager
	
	_zone_min_pos = ZoneService.current_zone_min_position
	_zone_max_pos = ZoneService.current_zone_max_position
	
	connect_safely(_main._wave_timer, "timeout", self, "_on_wave_timer_timeout")
	connect_safely(self, "dig_completed", self, "_on_dig_completed")
	
	if custom_key == "visible_mark":
		var number: = 0
		for item in RunData.items:
			for effect in item.effects:
				if effect.get_id() == "qmtato_effect_treasure_area" and effect.custom_key == "visible_mark":
					number += effect.value
		for i in number:
			spawn_area()
	else:
		for i in value:
			spawn_area()


func _on_wave_timer_timeout()->void :
	for instance in _area_instances:
		if is_instance_valid(instance):
			instance.queue_free()
	
	_area_instances.clear()


func _on_dig_completed(instance)->void :
	_area_instances.erase(instance)
	
	var treasure_text: = tr("DIG_COMPLETED")
	var rnd = randf()
	if rnd < 0.35:
		var dist = rand_range(100, 200)
		var consumable = consumable_scene.instance()
		var consumable_to_spawn = ItemService.item_box if randf() < 0.98 else ItemService.legendary_item_box
		var pos = instance.global_position
		consumable.consumable_data = consumable_to_spawn
		consumable.global_position = pos
		_main._consumables_container.call_deferred("add_child", consumable)
		consumable.call_deferred("set_texture", consumable_to_spawn.icon)
		var _error = consumable.connect("picked_up", _main, "on_consumable_picked_up")
		consumable.push_back_destination = Vector2(rand_range(pos.x - dist, pos.x + dist), rand_range(pos.y - dist, pos.y + dist))
		_main._consumables.push_back(consumable)
		
		treasure_text += tr("TREASURE_ITEM_BOX")
	elif rnd < 0.95:
		var gold_increase = RunData.current_wave * 4 + 30
		var min_value = RunData.current_wave * 2 + 10
		var gold_number = rand_range(min_value, gold_increase) as int
		spawn_gold(instance, gold_number)

		treasure_text += "%d %s" % [gold_number, tr("MATERIALS")]
	else:
		var scene = load("res://entities/units/enemies/013/13.tscn")
	
		var entity_spawner = _main._entity_spawner
		entity_spawner.spawn_entity_birth(EntityType.ENEMY, scene, instance.global_position, null)
		
		scene = load("res://entities/units/enemies/005/5.tscn")
		entity_spawner.spawn_entity(scene, instance.global_position)
		
		var gold_increase = RunData.current_wave * 2 + 30
		var min_value = RunData.current_wave + 10
		var gold_number = rand_range(min_value, gold_increase) as int
		spawn_gold(instance, gold_number)
		
		treasure_text += tr("TREASURE_ENEMY")
		
	_floating_text_manager.display(treasure_text, _player.global_position, Color.aqua)
	
	instance.queue_free()


func spawn_gold(instance, gold_number)->void :
	unit_stats.value = gold_number
	unit_stats.gold_spread = 100
	
	var _fake_unit = fake_unit.instance()
	_fake_unit._move_locked = true
	_fake_unit.set_physics_process(false)
	_fake_unit._current_movement = Vector2.ZERO
	call_deferred("add_child", _fake_unit)
	_fake_unit.stats = unit_stats
	_fake_unit.global_position = instance.global_position
	
	if is_instance_valid(_fake_unit):
		_main.call_deferred("spawn_gold", _fake_unit, EntityType.NEUTRAL)
	
	_fake_unit.call_deferred("queue_free")


func spawn_area()->void :
	var instance = area_scene.instance()
	var d = 150.0
	var min_x = _zone_min_pos.x + d
	var max_x = _zone_max_pos.x - d
	if min_x > max_x:
		min_x = 0
		max_x = 0
		
	var min_y = _zone_min_pos.y + d
	var max_y = _zone_max_pos.y - d
	if min_y > max_y:
		min_y = 0
		max_y = 0
	
	var pos = Vector2(
			rand_range(min_x, max_x), 
			rand_range(min_y, max_y)
		)
	instance.init(self, dig_time, _player, _floating_text_manager)
	instance.set_deferred("global_position", pos)
	
	_main.call_deferred("add_child", instance)
	
	if custom_key == "visible_mark":
		instance.get_node("CollisionShape2D/Sprite").set_deferred("visible", true)
	
	_area_instances.push_back(instance)


func get_args()->Array :
	return [str(value), "%.1fs" % dig_time]
