extends "res://overlap/hitbox.gd"


func init(exploding_effect:ExplodingEffect = null, explode_instantly:bool = false)->void :
	if not explode_instantly or not exploding_effect:
		deals_damage = false
	else:
		deals_damage = true
		
		if exploding_effect:
			effects.push_back(exploding_effect)
