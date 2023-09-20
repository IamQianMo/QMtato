extends "res://weapons/ranged/ranged_weapon.gd"


const NULL_EXPLODING_EFFECT = preload("res://mods-unpacked/QianMo-QMtato/content/weapons/effect_gyrojets/null_exploding_effect.tres")

var gyrojets_effect = null
var _qmtato_main = null
#var _projectiles: = []


func _ready():
	_qmtato_main = RunData.get_tree().current_scene
	
	for effect in effects:
		if effect.key == "gyrojets_effect":
			gyrojets_effect = effect
			break


func on_projectile_shot(projectile)->void :
	.on_projectile_shot(projectile)
	
	projectile.call_deferred("init", gyrojets_effect)
#	_projectiles.push_back(projectile)


#func shoot()->void :
#	.shoot()
#
#	var is_big_reload = current_stats.additional_cooldown_every_x_shots != - 1 and _nb_shots_taken % current_stats.additional_cooldown_every_x_shots == 0
#	if is_big_reload:
#		for projectile in _projectiles:
#			if is_instance_valid(projectile):
#				projectile.explode_now()
#		_projectiles.clear()


func init_stats(at_wave_begin:bool = true)->void :
	if not effects.has(NULL_EXPLODING_EFFECT):
		effects.push_back(NULL_EXPLODING_EFFECT)
	.init_stats(at_wave_begin)
	effects.erase(NULL_EXPLODING_EFFECT)
