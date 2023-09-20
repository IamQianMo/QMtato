extends "res://weapons/melee/melee_weapon.gd"


func set_can_rotate(can_rotate:bool = true)->void :
	if not can_rotate:
		_is_shooting = true


func should_shoot()->bool :
	return false


func shoot()->void :
	pass
