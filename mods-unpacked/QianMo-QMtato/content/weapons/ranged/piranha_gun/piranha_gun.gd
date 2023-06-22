extends RangedWeapon


var _current_projectiles:Array = []
var _projectile_cooldown:float = 8
var _piranha_gun_effect = null
var _max_projectiles_num: = 2


func shoot()->void :
	if _current_projectiles.size() >= _max_projectiles_num:
		return
	
	.shoot()


func on_projectile_shot(projectile:Node2D)->void :
	.on_projectile_shot(projectile)
	
	_current_projectiles.push_back(projectile)
	projectile.call_deferred("set_piranha_cooldown", _projectile_cooldown)
	
	var _error = projectile.connect("tree_exiting", self, "_on_projectile_tree_exiting", [projectile])


func _on_projectile_tree_exiting(projectile)->void :
	_current_projectiles.erase(projectile)


func init_stats(at_wave_begin:bool = true)->void :
	.init_stats(at_wave_begin)
	
	if not _piranha_gun_effect:
		for effect in effects:
			if effect.key == "piranha_effect":
				_piranha_gun_effect = effect
				_max_projectiles_num = _piranha_gun_effect.max_projectiles_num
				break
	
	var atk_spd = Utils.get_stat("stat_attack_speed") / 100.0
	if atk_spd > 0:
		_projectile_cooldown = max(2, _piranha_gun_effect.value * (1 / (1 + atk_spd))) as int
	else :
		_projectile_cooldown = max(2, _piranha_gun_effect.value * (1 + abs(atk_spd))) as int
