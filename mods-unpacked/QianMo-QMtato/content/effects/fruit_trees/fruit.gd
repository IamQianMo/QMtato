extends Consumable


onready var _timer = $Timer

export (Resource) var consumable_data_export

var _bonus_stats: = [["stat_luck", 5, 1]]
var _growth_time: = 20.0
var _current_growth: = 0.0
var _disabled: = true
var _main
var _wave_ended: = false
var _player:Player = null
var _key:String


func _ready():
	consumable_data = consumable_data_export
	scale = Vector2(0.1, 0.1)
	
	_timer.wait_time = _growth_time / 5
	_timer.start()
	
	if _disabled:
		disable()
	else:
		enable()
		
	_main = RunData.get_tree().current_scene
	var wave_timer:WaveTimer = _main._wave_timer
	var _error = wave_timer.connect("timeout", self, "_on_wavetimer_timeout")
	
	_player = TempStats.player
	_error = _player._item_attract_area.connect("area_entered", self, "_on_attract_arad_entered")


func _on_attract_arad_entered(area)->void:
	if area == self:
		attracted_by = _player


func _on_wavetimer_timeout()->void:
	_wave_ended = true
	
	if _disabled:
		queue_free()


func enable()->void:
	set_physics_process(true)
	scale = Vector2(1, 1)
	if not _timer.is_stopped():
		_timer.stop()
	_disabled = false
	
	_main._consumables.push_back(self)
	
	call_deferred("correct_push_back")


func correct_push_back()->void :
	if (push_back_destination.x >= ZoneService.current_zone_max_position.x 
	or push_back_destination.y >= ZoneService.current_zone_max_position.y
	or push_back_destination.x <= ZoneService.current_zone_min_position.x
	or push_back_destination.y <= ZoneService.current_zone_min_position.y):
		push_back_destination = Vector2.RIGHT.rotated(push_back_destination.angle() + PI) * (push_back_destination - global_position).length() + global_position


func disable()->void:
	set_physics_process(false)
	monitorable = false
	_disabled = true


func init(bonus_stats, growth_time=20.0, key="lemon_tree")->void:
	_bonus_stats = bonus_stats
	_growth_time = growth_time
	_key = key


func pickup()->void :
	.pickup()
	
	if RunData.effects["character_orchard_man"] > 0:
		RunData.tracked_item_effects["character_orchard_man"] += 1
		
		for i in RunData.effects["character_orchard_man"]:
			if randf() > 0.25:
				continue
				
			for stat in _bonus_stats:
				var stat_value = stat[1]
				
				if _wave_ended:
					if stat_value < 0:
						stat_value = min(-1, stat_value / 2.0) as int
					else:
						stat_value = max(1, stat_value / 2.0) as int
				
				if stat[0] == "materials":
					if stat_value >= 0:
						RunData.add_gold(stat_value)
					else:
						RunData.remove_gold(-stat_value)
				else:
					if stat_value >= 0:
						RunData.add_stat(stat[0], stat_value)
					else:
						RunData.remove_stat(stat[0], -stat_value)
				
				if not RunData.tracked_item_effects["fruit_tree_stats_gained"].has(_key):
					RunData.tracked_item_effects["fruit_tree_stats_gained"][_key] = [[stat[0], stat_value]]
				else:
					var flag = false
					for tracked_stat in RunData.tracked_item_effects["fruit_tree_stats_gained"][_key]:
						if tracked_stat[0] == stat[0]:
							tracked_stat[1] += stat_value
							flag = true
							break
					if not flag:
						RunData.tracked_item_effects["fruit_tree_stats_gained"][_key].push_back([stat[0], stat_value])
	
	for stat in _bonus_stats:
		var stat_value = stat[1]
		
		if _wave_ended:
			if stat_value < 0:
				stat_value = min(-1, stat_value / 2.0) as int
			else:
				stat_value = max(1, stat_value / 2.0) as int
		
		if stat[0] == "materials":
			if stat_value >= 0:
				RunData.add_gold(stat_value)
			else:
				RunData.remove_gold(-stat_value)
		else:
			if stat_value >= 0:
				RunData.add_stat(stat[0], stat_value)
			else:
				RunData.remove_stat(stat[0], -stat_value)
		
		if not RunData.tracked_item_effects["fruit_tree_stats_gained"].has(_key):
			RunData.tracked_item_effects["fruit_tree_stats_gained"][_key] = [[stat[0], stat_value]]
		else:
			var flag = false
			for tracked_stat in RunData.tracked_item_effects["fruit_tree_stats_gained"][_key]:
				if tracked_stat[0] == stat[0]:
					tracked_stat[1] += stat_value
					flag = true
					break
			if not flag:
				RunData.tracked_item_effects["fruit_tree_stats_gained"][_key].push_back([stat[0], stat_value])


func _on_Timer_timeout():
	_current_growth += 0.2
	
	scale = Vector2(_current_growth, _current_growth)
	
	if _current_growth >= 1.0:
		_timer.stop()
