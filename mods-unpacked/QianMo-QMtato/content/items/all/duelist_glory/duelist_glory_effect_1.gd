extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


var DUELIST_EFFECT = load("res://mods-unpacked/QianMo-QMtato/content/characters/duelist/duelist_effect_1.tres")

export (float) var extended_time: = 8.0
export (float) var chance_weapon: = 0.002


func _on_qmtato_wave_start(player)->void :
	._on_qmtato_wave_start(player)
	
	if not DUELIST_EFFECT or not is_instance_valid(DUELIST_EFFECT):
		DUELIST_EFFECT = load("res://mods-unpacked/QianMo-QMtato/content/characters/duelist/duelist_effect_1.tres")
	
	_main = RunData.get_tree().current_scene
	var wave_timer = _main._wave_timer
	wave_timer.start(wave_timer.time_left + extended_time)
	var entity_spawner = _main._entity_spawner
	entity_spawner.connect("enemy_spawned", self, "_on_enemy_spawned")


func _on_enemy_spawned(enemy)->void :
	if randf() <= chance_weapon:
		DUELIST_EFFECT._player = _player
		DUELIST_EFFECT.add_random_weapon(enemy)


func get_args()->Array :
	return [str(extended_time), str(chance_weapon * 100)]
