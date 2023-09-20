extends "res://overlap/hitbox.gd"


var _main


func _ready():
	var _error = connect("hit_something", self, "_on_hit_something")
	_main = get_tree().current_scene


func _on_hit_something(thing_hit, _damage_dealt)->void:
	if not thing_hit == null and is_instance_valid(thing_hit):
		var projectile_stat = WeaponService.init_ranged_stats(effects[0].weapon_stats)
		
		var direction:Vector2 = thing_hit.global_position - global_position
		var rotation = direction.angle()
		for _i in range(projectile_stat.nb_projectiles):
			var _error = WeaponService.spawn_projectile(rotation, projectile_stat, global_position, Vector2.ONE.rotated(rotation), true, [], from)
