extends "res://effects/weapons/null_effect.gd"


export (int) var chance: = 100


func get_args()->Array :
	return [str(chance), str(value)]
