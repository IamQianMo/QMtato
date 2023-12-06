extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


const FAKE_WEAPON_DATA = preload("res://mods-unpacked/QianMo-QMtato/content/characters/turret_master/fake_weapon/fake_weapon_data.tres")

var _tediore_effect = null
var _entity_spawner = null
var _combo_with_tediore: = false


func _on_qmtato_wave_start(player)->void :
	._on_qmtato_wave_start(player)
	
	_main = RunData.get_tree().current_scene
	
	_entity_spawner = _main.get("_entity_spawner")
	if _entity_spawner:
		connect_safely(_entity_spawner, "structure_spawned", self, "_on_structure_spawned")
	
	_combo_with_tediore = false
	if check_character("qmtato_character_tediore"):
		_combo_with_tediore = true
		_tediore_effect = preload("res://mods-unpacked/QianMo-QMtato/content/characters/tediore/tediore_effect_1.tres")
	
	del_weapons()


func del_weapons()->void :
	if is_instance_valid(_player):
		for weapon in _player.current_weapons.duplicate():
			if is_instance_valid(weapon):
				_player.current_weapons.erase(weapon)
				weapon.queue_free()


func unapply()->void :
	.unapply()
	
	disconnect_safely(_entity_spawner, "structure_spawned", self, "_on_structure_spawned")


func _on_structure_spawned(structure)->void :
	if structure is WanderingBot:
		return
	
	var structure_parent = structure.get_parent()
	
	if structure_parent and is_instance_valid(structure):
		structure_parent.call_deferred("remove_child", structure)
		
		var pos_array: = []
		for weapon in _player.current_weapons:
			pos_array.push_back(weapon.global_position)
		
		var weapon_pos = _player.current_weapons.size()
		_player.add_weapon(FAKE_WEAPON_DATA, weapon_pos)
		
		for i in pos_array.size():
			_player.current_weapons[i].global_position = pos_array[i]
		
		if _combo_with_tediore and _tediore_effect:
			if structure is Landmine:
				_tediore_effect.call_deferred("detach_weapon", _player.current_weapons[weapon_pos], false, _player)
			else:
				_tediore_effect.call_deferred("detach_weapon", _player.current_weapons[weapon_pos], true, _player)
		
		var pos = Vector2.ZERO
		if structure is Landmine:
			var r = 150.0
			var angle = rand_range(0, 2 * PI)
			var direction = Vector2(cos(angle), sin(angle))
			
			pos += direction * r
			
			_player.current_weapons[weapon_pos].call_deferred("set_can_rotate", false)
		
		structure.set_deferred("global_position", pos)
		_player.current_weapons[weapon_pos].call_deferred("add_child", structure)
		
		structure.connect("died", self, "_on_structure_died", [_player.current_weapons[weapon_pos]])


func _on_structure_died(_structure, weapon)->void :
	if is_instance_valid(weapon):
		_player.current_weapons.erase(weapon)
		weapon.queue_free()
	
	if not _combo_with_tediore:
		_player.current_weapons.shuffle()
		_player._weapons_container.update_weapons_positions(_player.current_weapons)


func check_character(id:String)->bool :
	if RunData.current_character == null:
		return false
	
	var gmo_characters = RunData.get("gmo_characters")
	if gmo_characters:
		if gmo_characters.empty():
			for item in RunData.items:
				if item is CharacterData:
					if item.my_id == id:
						gmo_characters.push_back(id)
						break
	else:
		gmo_characters = []
	
	return RunData.current_character.my_id == id or (RunData.current_character.my_id == "GMO_dummy" and gmo_characters.has(id))
