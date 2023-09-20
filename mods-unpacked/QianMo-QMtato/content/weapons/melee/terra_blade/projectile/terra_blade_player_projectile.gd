extends "res://projectiles/player_projectile.gd"


const scale_per_second:Vector2 = Vector2(0.5, 0.5)


func _on_Hitbox_hit_something(thing_hit:Node, damage_dealt:int)->void :
	_hitbox.ignored_objects = [thing_hit]

	emit_signal("hit_something", thing_hit, damage_dealt)


func _physics_process(_delta:float)->void :
	scale += scale_per_second * _delta
	modulate.a += _delta
	
	velocity /= _delta * 2.3 + 1


func _on_DestroyTimer_timeout():
	set_to_be_destroyed()
