extends "res://entities/structures/turret/turret.gd"


onready var _reparing_timer = $ReparingTimer
onready var _invincibility_timer = $InvincibilityTimer
onready var _bonus_attack_timer = $BonusAttackTimer
onready var _cluster_rockets_timer = $ClusterRocketsTimer
onready var _hurt_box = $Hurtbox
onready var _repairing_box = $Repairingbox
onready var _repairing_sprite = $Repairingbox/Sprite
onready var _sprite = $Animation/Sprite
onready var _flash_timer = $FlashTimer

export (int) var max_health
export (int) var time_needed_trigger_skill = 15
export (PackedScene) var health_bar_scene
export (Resource) var explosion_effect
export (Resource) var cluster_rockets_scene

const COLOR_GREEN = Color(0.31, 1, 0.27, 0.5)
const COLOR_RED = Color(1.0, 0, 0, 0.5)

var _health_bar_instance = null
var _current_health: = 10
var _floating_text_manager:FloatingTextManager = null
var _effects_manager:EffectsManager = null
var _damage_reduction: = 0.1
var _time_count: = 0
var _range: = 0
var _is_in_skill:bool = false


func _ready():
	if not _health_bar_instance == null and is_instance_valid(_health_bar_instance):
		_health_bar_instance.queue_free()
	
	_range_shape.shape.radius += Utils.get_stat("stat_range")
	_range = _range_shape.shape.radius
	_damage_reduction = 10.0 / (10.0 + (abs(Utils.get_stat("stat_armor")) / 1.5))
	if Utils.get_stat("stat_armor") < 0:
		_damage_reduction = 1.0 / _damage_reduction
		
	var atk_spd = Utils.get_stat("stat_attack_speed") / 100.0
	
	if atk_spd > 0:
		_max_cooldown = max(2, stats.cooldown * (1 / (1 + atk_spd))) as int
	else :
		_max_cooldown = max(2, stats.cooldown * (1 + abs(atk_spd))) as int
	
	max_health += (Utils.get_stat("stat_max_hp") * 1.5) as int
	_current_health = max_health
	_health_bar_instance = health_bar_scene.instance()
	add_child(_health_bar_instance)
	_health_bar_instance.init(max_health, time_needed_trigger_skill)
	
	_effects_manager = RunData.get_tree().current_scene._effects_manager
	_floating_text_manager = RunData.get_tree().current_scene._floating_text_manager


func _on_Hurtbox_area_entered(hitbox:Area2D)->void :
	if not hitbox.get("active"):
		return
	if not hitbox.active or hitbox.ignored_objects.has(self):
		return 
	if hitbox.deals_damage:
		if not hitbox.is_healing:
			take_damage(hitbox.damage, hitbox)
			hitbox.hit_something(self, hitbox.damage)
		else:
			heal(hitbox.damage)


func take_damage(damage:int, hitbox):
	if not _invincibility_timer.is_stopped():
		return
	_invincibility_timer.start()
	
	sprite.material.set_shader_param("flash_modifier", 1)
	_flash_timer.start()
	
	_hurt_box.disable()
	
	damage = (damage * _damage_reduction) as int
	if hitbox.from is Boss:
		damage = (damage * 0.5) as int
	_current_health -= damage
	if _current_health <= 0:
		die()
	
	_effects_manager.play_hit_effect(global_position, global_position - hitbox.global_position, 1.0)
	_floating_text_manager.display("-" + str(damage), global_position, Color.red)
	_health_bar_instance.emit_signal("health_changed", _current_health)


func die(_knockback_vector:Vector2 = Vector2.ZERO, p_cleaning_up:bool = false)->void:
	if not _health_bar_instance == null and is_instance_valid(_health_bar_instance):
		_health_bar_instance.queue_free()
	
	if not _reparing_timer.is_stopped():
		_reparing_timer.stop()
	if not _bonus_attack_timer.is_stopped():
		_bonus_attack_timer.stop()
	
	_repairing_box.hide()
	
	.die(_knockback_vector, p_cleaning_up)


func _on_ReparingTimer_timeout():
	heal((max_health * 0.1) as int)
	
	if not _is_in_skill:
		_time_count += 1
		if _time_count >= time_needed_trigger_skill and _cluster_rockets_timer.is_stopped():
			_time_count = 0
			_repairing_sprite.modulate = COLOR_RED
			_cluster_rockets_timer.start()
			_is_in_skill = true
		
		_health_bar_instance.emit_signal("charge_changed", _time_count)


func heal(healed:int)->void:
	if _current_health < max_health:
		var max_healed = max_health - _current_health
		if healed <= max_healed:
			_current_health += healed
		else:
			_current_health += max_healed
			healed = max_healed
		_floating_text_manager.display("+" + str(healed), global_position, Color.green)
		_health_bar_instance.emit_signal("health_changed", _current_health)


func _on_Repairingbox_body_entered(body):
	if body.collision_layer & 1 << 10:
		return
	
	if _reparing_timer.is_stopped():
		_reparing_timer.start()
	if _bonus_attack_timer.is_stopped():
		_bonus_attack_timer.start()


func _on_Repairingbox_body_exited(body):
	if body.collision_layer & 1 << 10:
		return
	
	if not _reparing_timer.is_stopped():
		_reparing_timer.stop()
	if not _bonus_attack_timer.is_stopped():
		_bonus_attack_timer.stop()
		_bonus_attack_timer.wait_time = 1


func _on_InvincibilityTimer_timeout():
	_hurt_box.enable()


func shoot()->void :
	if _current_target.size() == 0 or not is_instance_valid(_current_target[0]):
		_is_shooting = false
		_cooldown = rand_range(max(1, _max_cooldown * 0.7), _max_cooldown * 1.3)
	else :
		_next_proj_rotation = (_current_target[0].global_position - global_position).angle()

	SoundManager2D.play(Utils.get_rand_element(stats.shooting_sounds), global_position, stats.sound_db_mod, 0.2)

	for i in stats.nb_projectiles:
		var proj_rotation = rand_range(_next_proj_rotation - stats.projectile_spread, _next_proj_rotation + stats.projectile_spread)
		var knockback_direction: = - Vector2(cos(proj_rotation), sin(proj_rotation))
		var _projectile = WeaponService.spawn_projectile(proj_rotation, 
			stats, 
			_muzzle.global_position, 
			knockback_direction, 
			false, 
			effects
		)
		_projectile.rotation = 0
		_projectile.from = self


func _on_BonusAttackTimer_timeout():
	shoot()
	
	if _bonus_attack_timer.wait_time >= 0.5:
		_bonus_attack_timer.wait_time *= 0.9


var _rockets_count: = 0
func _on_ClusterRocketsTimer_timeout():
	_rockets_count += 1
	if _rockets_count >= 15:
		_rockets_count = 0
		_repairing_sprite.modulate = COLOR_GREEN
		if not _cluster_rockets_timer.is_stopped():
			_cluster_rockets_timer.stop()
		_is_in_skill = false
	
	var x = _muzzle.global_position.x
	var y = _muzzle.global_position.y
	var start_x = x + 3000
	var start_y = y + 3000
	x = rand_range(x - _range, x + _range)
	y = rand_range(y - _range, y + _range)
	if randf() <= 0.5:
		start_x = -start_x
	if randf() <= 0.5:
		start_y = -start_y
	if randf() <= 0.5:
		start_x = rand_range(-abs(start_x), abs(start_x))
	else:
		start_y = rand_range(-abs(start_y), abs(start_y))
	
	spawn_cluster_rockets(Vector2(start_x, start_y), Vector2(x, y))


func explode(pos:Vector2, damage:int, accuracy:float = 1, crit_chance:float = 0.1, crit_dmg:float = 2, burning_data:BurningData = BurningData.new(), is_healing:bool = false, ignored_objects:Array = [], damage_tracking_key:String = "")->Node:
	var instance = WeaponService.explode(explosion_effect, pos, damage, accuracy, crit_chance, crit_dmg, burning_data, is_healing, ignored_objects, damage_tracking_key)
	SoundManager2D.play(Utils.get_rand_element(stats.shooting_sounds), global_position, stats.sound_db_mod, 0.2)
	return instance


func spawn_cluster_rockets(start_pos:Vector2, end_pos:Vector2):
	var main = get_tree().current_scene
	var projectile = cluster_rockets_scene.instance()
	var velocity = (end_pos - start_pos) / 2
	main.call_deferred("add_child", projectile)
	projectile.set_deferred("from", self)
	projectile.set_deferred("global_position", start_pos)
	projectile.set_deferred("spawn_position", start_pos)
	projectile.set_deferred("velocity", velocity)
	projectile.set_deferred("rotation", velocity.angle())
	projectile.call_deferred("set_destroy_time", 2)
	projectile.call_deferred("set_target_position", end_pos)


func reload_data()->void :
	stats = WeaponService.init_ranged_stats(base_stats, "", [], effects, true)
	
	for effect in effects:
		if effect is BurningEffect:
			var base_burning = BurningData.new(
				effect.burning_data.chance, 
				max(1.0, effect.burning_data.damage + WeaponService.get_scaling_stats_value(stats.scaling_stats)) as int, 
				effect.burning_data.duration, 
				effect.burning_data.spread, 
				effect.burning_data.type
			)
			
			stats.burning_data = WeaponService.init_burning_data(base_burning, false, true)


func _on_FlashTimer_timeout():
	sprite.material.set_shader_param("flash_modifier", 0)
