extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (PackedScene) var portal_scene:PackedScene
export (float) var change_wait_time: = 15.0
export (Array, Color) var colors = [Color.yellow, Color.red]
export (float) var damage_percent: = 0.2
export (float) var max_distance: = 700.0
export (float) var min_distance: = 400.0

const CONER_CHOICES: = [0, 1, 2, 3]

var portal_num: = 0
var portal_list: = []

var _zone_min_pos
var _zone_max_pos
var _already_used_corner_id: = []


func _on_qmtato_wave_start(player)->void :
	._on_qmtato_wave_start(player)
	
	_already_used_corner_id.clear()
	
	_main = RunData.get_tree().current_scene as Node
	
	_zone_min_pos = ZoneService.current_zone_min_position
	_zone_max_pos = ZoneService.current_zone_max_position
	
	portal_num = 1
#	for item in RunData.items:
#		for effect in item.effects:
#			if effect.get_id() == "qmtato_effect" and effect.key == "qmtato_portal":
#				portal_num += effect.value
	
	for i in portal_num:
		var portal1 = portal_scene.instance()
		var portal2 = portal_scene.instance()
		
		portal_list.clear()
		
		portal_list.append(portal1)
		portal1.call_deferred("init", self, portal2, change_wait_time, damage_percent)
		portal1.set_deferred("global_position", get_pos())
		_main.call_deferred("add_child", portal1)
		portal1.call_deferred("set_color", colors[0])

		portal_list.append(portal2)
		portal2.call_deferred("init", self, portal1, change_wait_time, damage_percent)
		portal2.set_deferred("global_position", get_pos())
		_main.call_deferred("add_child", portal2)
		portal2.call_deferred("set_color", colors[1])
		
		call_deferred("correct_distance")


func get_args()->Array :
	var portal1 = "[color=#%s]%s1[/color]" % [colors[0].to_html(), tr("PORTAL")]
	var portal2 = "[color=#%s]%s2[/color]" % [colors[1].to_html(), tr("PORTAL")]
	
	return [portal1, portal2, "%.1fs" % change_wait_time, "%d%%" % (damage_percent * 100)]


func get_pos(width:float=150.0)->Vector2 :
	if portal_list.size() > 2:
		portal_list.remove(0)
		portal_list.remove(1)
	
	var min_x = _zone_min_pos.x + width
	var max_x = _zone_max_pos.x - width
	if min_x > max_x:
		min_x = 0
		max_x = 0
		
	var min_y = _zone_min_pos.y + width
	var max_y = _zone_max_pos.y - width
	if min_y > max_y:
		min_y = 0
		max_y = 0
	
	var pos
	var rand_offset = Vector2(rand_range(0, 80), rand_range(0, 80))
	
	var usable_corners: = CONER_CHOICES.duplicate()
	for corner in _already_used_corner_id:
		usable_corners.erase(corner)
	_already_used_corner_id.clear()
	
	var corner_id = 0
	var order = portal_list.size() - 1
	if order == 1:
		corner_id = 4
	else:
		corner_id = Utils.get_rand_element(usable_corners)
		_already_used_corner_id.append(corner_id)
	
	match corner_id:
		0:
			pos = Vector2(
				max_x,
				max_y
			)
			rand_offset.x = -rand_offset.x
			rand_offset.y = -rand_offset.y
		1:
			pos = Vector2(
				max_x,
				min_y
			)
			rand_offset.x = -rand_offset.x
		2:
			pos = Vector2(
				min_x,
				min_y
			)
		3:
			pos = Vector2(
				min_x,
				max_y
			)
			rand_offset.y = -rand_offset.y
		4:
			pos = Vector2(
				rand_range(min_x, max_x),
				rand_range(min_y, max_y)
			)
	
	return pos + rand_offset


func correct_distance()->void :
	if portal_list.size() == 2:
		var pos1:Vector2 = portal_list[0].global_position
		var pos2:Vector2 = portal_list[1].global_position
		var direction:Vector2 = pos2 - pos1
		var distance = direction.length()
		direction = direction.normalized()
		if distance > max_distance:
			var position_offset = direction * max_distance
			
			var target_position = portal_list[1].global_position
			target_position = pos1 + position_offset
			
			var x = target_position.x
			var y = target_position.y
			if x > _zone_max_pos.x or x < _zone_min_pos.x:
				target_position.x -= position_offset.x * 2
			if y > _zone_max_pos.y or y < _zone_min_pos.y:
				target_position.y -= position_offset.y * 2
			
			portal_list[1].global_position = target_position
		elif distance < min_distance:
			var position_offset = direction * min_distance
			
			var target_position = portal_list[1].global_position
			target_position = pos1 + position_offset
			
			var x = target_position.x
			var y = target_position.y
			if x > _zone_max_pos.x or x < _zone_min_pos.x:
				target_position.x -= position_offset.x * 2
			if y > _zone_max_pos.y or y < _zone_min_pos.y:
				target_position.y -= position_offset.y * 2
			
			portal_list[1].global_position = target_position
