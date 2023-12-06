extends "res://projectiles/player_explosion.gd"


var _player = null
var _knockback: = 50.0
var _bosses: = []


func _ready():
	var _error = connect("hit_something", self, "_on_hit_something")
	
	if not ProgressData.settings.explosions:
		$Sprite.show()


func init(player:Player)->void:
	_player = player


func _physics_process(delta):
	scale += delta * Vector2.ONE * 5
	_knockback -= delta * 15


func _on_hit_something(thing_hit, _damage_dealt)->void:
	if not thing_hit == null and is_instance_valid(thing_hit):
		if thing_hit is Neutral:
			return
		
		var raw_direction = global_position - thing_hit.global_position
		
		if thing_hit.stats.knockback_resistance >= 1:
			if thing_hit is Boss:
				_bosses.append(thing_hit)
			thing_hit.stats.knockback_resistance *= 0.5
		thing_hit._knockback_vector += raw_direction.normalized() * _knockback * (1 + thing_hit.stats.knockback_resistance) 


func _on_Timer_timeout()->void:
	for boss in _bosses:
		if not boss == null and is_instance_valid(boss):
			boss.stats.knockback_resistance = 1
	
	._on_Timer_timeout()
