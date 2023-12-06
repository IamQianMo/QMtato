extends "res://entities/structures/turret/turret.gd"


export (PackedScene) var fruit_scene
export (float) var push_back_distance: = 50.0

var qmtato_sign: = true
var _bonus_stats: = [["stat_luck", 5, 1]]
var _consumables_container = null
var _current_fruit = null
var _is_random: = true
var _main
var _key:String


func _ready():
	_main = RunData.get_tree().current_scene
	
	_range_shape.set_deferred("disabled", true)
	_current_target = [self, 1]
	
	_consumables_container = RunData.get_tree().current_scene._consumables_container


func shoot()->void :
	_is_shooting = false
	_cooldown = max(2, _max_cooldown)
	
	if is_instance_valid(_current_fruit):
		var pos = global_position
		var push_back_vector: = Vector2.RIGHT.rotated(rand_range(0, 2 * PI))
		var actual_push_back_distance = rand_range(push_back_distance * 0.5, push_back_distance * 1.5)
		
		var fruit_parent = _current_fruit.get_parent()
		if fruit_parent:
			fruit_parent.remove_child(_current_fruit)
			_current_fruit.global_position = pos + _current_fruit.position
			_consumables_container.call_deferred("add_child", _current_fruit)
		
		_current_fruit.push_back_destination = push_back_vector * actual_push_back_distance + pos
		_current_fruit.enable()

	var _error = generate_fruit()


func should_shoot()->bool:
	_current_target = [self, 1]
	return _cooldown == 0 and not _is_shooting


func generate_fruit()->Area2D:
	_current_fruit = fruit_scene.instance()

	if _current_fruit:
		if _is_random:
			var actual_stats = _bonus_stats.duplicate(true)
			var luck = Utils.get_stat("stat_luck") / 100.0
			if luck < 0:
				luck = 1 / (abs(luck) + 1)
			else:
				luck += 1.0
			var total_weight = 0
			for i in actual_stats.size():
				var stat_name = actual_stats[i][0]
				if actual_stats[i][1] > 0:
					if stat_name == "number_of_enemies" or stat_name == "enemy_speed":
						total_weight += actual_stats[i][2]
						continue
					actual_stats[i][2] *= luck
				total_weight += actual_stats[i][2]
			actual_stats.sort_custom(self, "sort_by_weight")
			
			var rnd = rand_range(0, total_weight)
			var acutal_stat = null
			var weight_now = 0
			for stat in actual_stats:
				weight_now += stat[2]
				if rnd < weight_now:
					acutal_stat = stat
					break
					
			if not acutal_stat:
				acutal_stat = _bonus_stats[_bonus_stats.size()-1]
			
			_current_fruit.call_deferred("init", [acutal_stat], _cooldown / 60.0, _key)
		else:
			_current_fruit.call_deferred("init", _bonus_stats, _cooldown / 60.0, _key)
		
		_current_fruit.set_deferred("position", Vector2(0, -30) * scale)
		_current_fruit.set_deferred("rotation", rand_range(0, 2 * PI))
		_current_fruit.connect("picked_up", _main, "on_consumable_picked_up")
		_current_fruit.disable()
		
		call_deferred("add_child", _current_fruit)
	
	return _current_fruit


func set_data(data:Resource)->void:
	.set_data(data)
	
	var bonus_stats = data.get("bonus_stats")
	if bonus_stats:
		_bonus_stats = data.bonus_stats
		_is_random = data.is_random
		_key = data.key


func _on_AnimationPlayer_animation_finished(anim_name:String)->void :
	if anim_name == "shoot" and not dead:
		_is_shooting = false
		_cooldown = max(1, _max_cooldown)
		_animation_player.playback_speed = 1.0
		_animation_player.play("idle")


func sort_by_weight(a, b)->bool:
	if a[2] > b[2]:
		return true
	return false
