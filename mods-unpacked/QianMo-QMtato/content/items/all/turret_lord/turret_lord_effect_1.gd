extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (float) var bonus_cri_chance: = 0.5
export (Array, Resource) var bonus_effects
export (int) var max_bonus_effects: = 2

var _count: = 0


func _on_qmtato_wave_start(_player)->void:
	var entity_spawner:EntitySpawner = RunData.get_tree().current_scene.get("_entity_spawner")
	
	_count = 0
	
	connect_safely(entity_spawner, "structure_spawned", self, "_on_structure_spawned")


func _on_structure_spawned(structure)->void :
	if structure is Landmine or structure is WanderingBot or structure is Garden or "qmtato_sign" in structure:
		return
	
	var stats = structure.get("stats")
	if stats and stats is RangedWeaponStats:
		stats.crit_chance += bonus_cri_chance
		
		var base_stats = structure.get("base_stats")
		if base_stats and base_stats is RangedWeaponStats:
			structure.base_stats = base_stats.duplicate()
			structure.base_stats.crit_chance += bonus_cri_chance
	
	if _count < max_bonus_effects:
		var effects = structure.get("effects")
		if effects is Array:
			_count += 1
			structure.modulate = Color.red
			structure.effects = effects.duplicate()
			structure.effects.push_back(Utils.get_rand_element(bonus_effects))


func get_args()->Array :
	var effects_text:String = ""
	for effect in bonus_effects:
		effects_text += effect.get_text() + "\n"
	effects_text = effects_text.trim_suffix("\n")
	
	return [str(bonus_cri_chance * 100), str(max_bonus_effects), effects_text]
