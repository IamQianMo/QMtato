extends PlayerProjectile


func _on_Hitbox_hit_something(thing_hit:Node, damage_dealt:int)->void :
	._on_Hitbox_hit_something(thing_hit, damage_dealt)
	
	var face_puncher_burning_effect = null
	for effect in _hitbox.effects:
		if effect.key == "face_puncher_burning":
			face_puncher_burning_effect = effect
			break
	
	if face_puncher_burning_effect:
		if randf() <= face_puncher_burning_effect.chance:
			var _damage = max(1, weapon_stats.damage * face_puncher_burning_effect.scale_factor) as int
			var _burning_data: = BurningData.new()
			_burning_data.chance = 1
			_burning_data.damage = _damage
			_burning_data.duration = face_puncher_burning_effect.duration
			_burning_data.from = _hitbox.from
			
			thing_hit.apply_burning(_burning_data)
