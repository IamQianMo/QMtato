extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


const TEDIORE_EFFECT = preload("res://mods-unpacked/QianMo-QMtato/content/characters/tediore/tediore_effect_1.tres")

var items_count: = 0


func _on_qmtato_wave_start(player)->void:
	items_count = 0
	
	for item in RunData.items:
		for effect in item.effects:
			if effect.custom_key == "item_smart_gun":
				items_count += 1
	
	var weapons = player.current_weapons.duplicate()
	for i in items_count:
		if not weapons.empty():
			var weapon = Utils.get_rand_element(weapons)
			TEDIORE_EFFECT.detach_weapon(weapon, true, player)
			weapons.erase(weapon)
