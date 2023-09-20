extends Node2D


signal toggle_changed(status)
signal hit_something(thing_hit)
signal killed_by_mark


onready var _black = $Animation/Black
onready var _white = $Animation/White
onready var _animation_player = $AnimationPlayer

var _current_status: = false
var _is_playing: = false
var _applied_effect: = -1
var _bonus_speed = 50
var _base_damage = 10

var _parent:Unit = null
var _scaling_stats: = []


func init(current_status:bool, scaling_stats:Array, base_damage:int, bonus_speed)->void:
	_current_status = current_status
	_scaling_stats = scaling_stats
	_base_damage = base_damage
	_bonus_speed = bonus_speed


func _ready():
	_parent = get_parent()
	
	if _parent.dead:
		queue_free()
		return
	
	var _error = connect("toggle_changed", self, "_on_toggle_changed")
	_error = _parent.connect("died", self, "_on_unit_died")
	change_sprite(_current_status)


func _on_unit_died(_unit)->void :
	hide()


func _on_toggle_changed(status:bool)->void:
	if _applied_effect == -1:
		if status:
			_applied_effect = 0
			modify_enemy_speed(-_bonus_speed)
		else:
			_applied_effect = 1
			modify_enemy_speed(_bonus_speed)
	
	if not status == _current_status and not _is_playing:
		_current_status = status
		change_sprite(status)
		_animation_player.play("start")
		_is_playing = true


func change_sprite(status:bool)->void:
	if status:
		_white.show()
	else:
		_black.show()


func get_current_status()->bool:
	return _current_status


func release_marks()->void:
	if not _animation_player == null:
		_animation_player.play("died")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "start":
		var dmg:float = _base_damage
		for stat in _scaling_stats:
			dmg += Utils.get_stat(stat[0]) * stat[1]
		dmg = RunData.get_dmg(dmg) as int
		
		if not _parent.dead:
			var dmg_taken = _parent.take_damage(dmg)
			RunData.tracked_item_effects["character_neutralization"] += dmg_taken[1]
			reset_enemy()
		
		if _parent.dead:
			emit_signal("killed_by_mark")
			release_marks()
		else:
			queue_free()


func reset_enemy()->void:
	if _applied_effect == 0:
		modify_enemy_speed(_bonus_speed)
	else:
		modify_enemy_speed(-_bonus_speed)


func modify_enemy_speed(value:int)->void:
	_parent.current_stats.speed += value


func _on_Hurtbox_body_entered(body):
	emit_signal("hit_something", body)
