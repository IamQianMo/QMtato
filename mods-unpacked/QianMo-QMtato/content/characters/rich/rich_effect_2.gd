extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (StreamTexture) var gold_icon: StreamTexture
export (Array, Array) var gold_damage_scale_stats: Array = [["materials", 0.5]]

var GOLD_HITBOX_SCENE: PackedScene = load("res://mods-unpacked/QianMo-QMtato/content/characters/rich/gold_hitbox.tscn")

var _items_container: Node2D
var _current_base_damage: = 1
var _extra_gold_damage: float = 0 # The gold number damage
var _gold_damage_scale_materials: Array = []


func _on_qmtato_wave_start(player)->void:
	._on_qmtato_wave_start(player)
	
	_main = RunData.get_tree().current_scene
	_items_container = _main._items_container
	connect_safely(RunData, "stats_updated", self, "_on_stats_updated")
	
	_gold_damage_scale_materials.clear()
	var has_gold_stat: = false
	for stat in gold_damage_scale_stats:
		if stat[0] == "materials":
			has_gold_stat = true
			_gold_damage_scale_materials.append(stat[1])
	if has_gold_stat:
		connect_safely(RunData, "gold_changed", self, "_on_gold_changed")
	
	var _error_connect = _items_container.connect("child_entered_tree", self, "_on_items_container_child_entered_tree")


func _on_items_container_child_entered_tree(node: Node)->void :
	if node is Gold:
		var hitbox = GOLD_HITBOX_SCENE.instance()
		hitbox.set_damage(
						get_damage(), 
						1.0, 
						Utils.get_stat("stat_crit_chance") / 100.0, 
						2.0, 
						WeaponService.init_burning_data())
		
		node.add_child(hitbox)


func _on_stats_updated()->void :
	var damage: float = 0
	_extra_gold_damage = 0
	for stat in gold_damage_scale_stats:
		if stat[0] == "materials":
			_extra_gold_damage += RunData.gold * stat[1]
		else:
			damage += Utils.get_stat(stat[0]) * stat[1]
	
	_current_base_damage = RunData.get_dmg(damage)


func _on_gold_changed(new_value)->void :
	_extra_gold_damage = 0
	for scale in _gold_damage_scale_materials:
		_extra_gold_damage += new_value * scale


func get_damage()->int :
	return round(_current_base_damage + _extra_gold_damage) as int


func get_args()->Array :
	_on_stats_updated()
	
	var scale_text: = ""
	var w = 20 * ProgressData.settings.font_size
	
	for stat in gold_damage_scale_stats:
		if stat[0] == "materials":
			scale_text += "%d%%[img=%sx%s]%s[/img]" % [round(stat[1] * 100.0), w, w, gold_icon.resource_path]
		else:
			scale_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	
	return ["[color=#00ff00]%d[/color]" % get_damage(), scale_text]
