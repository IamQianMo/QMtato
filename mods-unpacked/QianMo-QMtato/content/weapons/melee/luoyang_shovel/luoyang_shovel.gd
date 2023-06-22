extends "res://weapons/melee/melee_weapon.gd"


export (Resource) var hitting_sound


func _on_Hitbox_hit_something(thing_hit:Node, damage_dealt:int)->void :
	._on_Hitbox_hit_something(thing_hit, damage_dealt)
	
	if randf() < 0.05:
		SoundManager.play(hitting_sound, -10, 0.2)
