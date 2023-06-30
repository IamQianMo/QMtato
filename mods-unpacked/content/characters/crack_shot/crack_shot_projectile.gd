extends PlayerProjectile


func _on_Hitbox_hit_something(thing_hit:Node, damage_dealt:int)->void :
	_hitbox.ignored_objects = [thing_hit]
	
	if weapon_stats.piercing <= 0:
		set_to_be_destroyed()
	else :
		weapon_stats.piercing -= 1
		if _hitbox.damage > 0:
			_hitbox.damage = max(1, _hitbox.damage - (_hitbox.damage * weapon_stats.piercing_dmg_reduction))
	
	RunData.manage_life_steal(weapon_stats)
	
	emit_signal("hit_something", thing_hit, damage_dealt)
	
