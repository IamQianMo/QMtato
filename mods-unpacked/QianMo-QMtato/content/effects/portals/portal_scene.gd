extends Area2D


export (PackedScene) var portal_particle
export (Array, Resource) var weapon_datas
export (Resource) var gold_on_kill_effect

onready var _collision = $Collision
onready var _timer = $ChangePositionTimer
onready var _cooldown_timer = $CooldownTimer

var _target_portal:Area2D = null
var _ignored_objects: = []
var _distance: = 0.0
var _player
var _wait_time: = 15.0
var _effect_parent = null
var _damage_percent: = 0.2
var _teleport_queue: = []


func init(effect_parent, target_portal, wait_time=15.0, damage_percent=0.2)->void :
	_target_portal = target_portal
	_wait_time = wait_time
	_effect_parent = effect_parent
	_damage_percent = damage_percent


func _ready():
	_distance = (global_position - _target_portal.global_position).length()
	
	_timer.wait_time = _wait_time
	_timer.start()
	
	_player = TempStats.player


func enable()->void :
	_collision.set_deferred("disabled", false)
	_collision.show()


func disable()->void :
	_collision.set_deferred("disabled", true)
	_collision.hide()


func get_radius()->float :
	return _collision.shape.radius * scale.x


func set_color(color:Color)->void :
	_collision.modulate = color


func append_ignored_objects(body)->void :
	_ignored_objects.push_back(body)


func _on_PortalArea_body_entered(body):
	if not _ignored_objects.has(body):
		if body is Player:
			_teleport_queue.append(body)
			_cooldown_timer.start()
		else:
			_target_portal.append_ignored_objects(body)
			var instance = portal_particle.instance()
			body.call_deferred("add_child", instance)
			instance.connect("particle_end", self, "_on_particle_ended")


func _on_particle_ended(body)->void :
	if not body.dead:
		if body is Boss:
			var dmg = max(1, body.current_stats.health * _damage_percent) as int
			body.take_damage(dmg)
		else:
			var dmg = max(1, body.max_stats.health * _damage_percent) as int
			body.take_damage(dmg)
	
	if not _teleport_queue.has(_player):
		var target_radius = _target_portal.get_radius()
		var direction = (body.global_position - _target_portal.global_position).normalized()
		var offset_vector = direction * target_radius

		body.global_position = _target_portal.global_position + offset_vector


func _on_PortalArea_body_exited(body):
	_ignored_objects.erase(body)
	
	if body is Player:
		_teleport_queue.erase(body)


func _on_PortalArea_area_entered(area):
	var body = area.get_parent()
	
	if body is Projectile:
		if _ignored_objects.has(_player) and body is PlayerProjectile:
			return
		
		if not _ignored_objects.has(body):
			_target_portal.append_ignored_objects(body)
			
			if body is PlayerProjectile:
#				body.set_deferred("spawn_position", _target_portal.global_position)
#				body.weapon_stats.piercing += 1
#				body.weapon_stats.max_range *= 3
				
#				var angle = body.velocity.angle()
#				var duplicated_projectile = WeaponService.spawn_projectile(
#					angle, 
#					body.weapon_stats, 
#					_target_portal.global_position, 
#					body._hitbox.knockback_direction, 
#					true, 
#					body._hitbox.effects, 
#					body._hitbox.from, 
#					body._hitbox.damage_tracking_key
#				)
#				_ignored_objects.append(duplicated_projectile)
#				_target_portal.append_ignored_objects(duplicated_projectile)
#				duplicated_projectile.connect("tree_exiting", self, "_on_projectile_exiting_tree", [duplicated_projectile])
#				body.velocity = -body.velocity
				
#				body._hitbox.damage *= 2
				
#				var angle = rand_range(-0.03 * PI, 0.03 * PI)
#				var new_velocity = body.velocity.rotated(angle)
#				body.set_deferred("velocity", new_velocity)
#				body.set_deferred("rotation", new_velocity.angle())
				if not body.is_connected("tree_exiting", self, "_on_projectile_exiting_tree"):
					body.connect("tree_exiting", self, "_on_projectile_exiting_tree", [body])
					body.spawn_position = _target_portal.global_position
					
					var stats = body.weapon_stats
					stats.max_range *= 3
						
					body.set_deferred("scale", body.scale * rand_range(1.0, 1.5))
					
					if randf() < 0.6:
						var effects = body._hitbox.effects.duplicate()
						effects.append_array(Utils.get_rand_element(weapon_datas).effects)
						body.call_deferred("set_effects", effects)
						for effect in effects:
							if effect is ExplodingEffect:
								body._hitbox.damage *= 0.7
						
						var rnd = randf()
						if rnd < 0.3:
							stats.crit_chance += 1.0
							body._hitbox.crit_chance += 1.0
							body._hitbox.effects.push_back(gold_on_kill_effect)
						elif rnd < 0.6:
							body._hitbox.damage *= 2
						elif rnd < 0.9:
							stats.bounce += rand_range(1, 3) as int
						else:
							var factor = rand_range(0.5, 1.5)
							stats.projectile_speed *= factor
							body.velocity *= factor
						
						var sprite = body.get_node_or_null("Sprite")
						if sprite:
							sprite.modulate = Color(rand_range(0, 1), rand_range(0, 1), rand_range(0, 1))
			
			var direction = body.global_position - global_position
			body.global_position = _target_portal.global_position + direction


func _on_projectile_exiting_tree(projectile)->void :
	_ignored_objects.erase(projectile)


func _on_ChangePositionTimer_timeout():
	_ignored_objects.clear()
	
	change_position()


func change_position()->void :
	_effect_parent.portal_list.push_back(self)
	
	var pos = _effect_parent.get_pos()
	set_deferred("global_position", pos)
	_effect_parent.call_deferred("correct_distance")


func _on_CooldownTimer_timeout():
	if _teleport_queue.has(_player):
		_target_portal.append_ignored_objects(_player)
		_player.global_position = _target_portal.global_position + Vector2(rand_range(-50, 50), rand_range(-50, 50))
		_teleport_queue.erase(_player)


func _on_PortalArea_area_exited(area):
	var body = area.get_parent()
	
	if body is Projectile:
		_ignored_objects.erase(body)
