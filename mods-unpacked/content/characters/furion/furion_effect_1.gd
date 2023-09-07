extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (Array, Array) var health_scaling
export (Array, Array) var damage_scaling
export (Array, Array) var speed_scaling
export (Array, Array) var armor_scaling
export (int) var base_damage

var MOVEMENT_BEHAVIOR = load("res://mods-unpacked/QianMo-QMtato/content/characters/furion/furion_tree_movement_behavior.gd")
var HITBOX = load("res://overlap/hitbox.gd")


func _on_qmtato_wave_start(player)->void :
	._on_qmtato_wave_start(player)
	
	_main = RunData.get_tree().current_scene
	var entity_spawner = _main._entity_spawner
	entity_spawner.connect("neutral_spawned", self, "_on_neutral_spawned")


func add_weapon(instance:Weapon, original_weapon:Weapon, pos:int, parent, instance_position:Vector2)->void :
	instance.weapon_pos = pos
	instance.stats = original_weapon.stats
	instance.call_deferred("init_stats", true)

	for effect in original_weapon.effects:
		instance.effects.push_back(effect.duplicate())
	
	parent.add_child(instance)
	instance._parent = original_weapon._parent
	
	instance.apply_scale(Vector2(1.2, 1.2))
	instance_position.x += 30 if rand_range(0, 1) < 0.5 else -30
	instance_position.y -= rand_range(-20, 20)
	instance.global_position = instance_position


func _on_neutral_spawned(neutral) :
	var current_weapons:Array = _player.current_weapons
	if (current_weapons and not current_weapons.empty()): 
		var weapon = Utils.get_rand_element(current_weapons)
		var duplicated_weapon = weapon.duplicate()
		add_weapon(duplicated_weapon, weapon, 0, neutral, neutral.position)
	
	var movement = neutral.get_node_or_null("MovementBehavior")
	movement.set_script(MOVEMENT_BEHAVIOR)
	
	movement.call_deferred("init", neutral, _player)
	
	for stat in health_scaling:
		neutral.current_stats.health += Utils.get_stat(stat[0]) * stat[1]
	
	var speed_coef = 1
	var speed = 500
	for stat in speed_scaling:
		speed_coef += Utils.get_stat(stat[0]) / 100 * stat[1]
	speed = max(0, speed * speed_coef)
	
	var dmg = base_damage
	for stat in damage_scaling:
		dmg += Utils.get_stat(stat[0]) * stat[1]
	dmg = max(1, dmg) as int
	
	var armor = 0
	for stat in armor_scaling:
		armor += Utils.get_stat(stat[0]) * stat[1]
	
	neutral.number_of_hits_before_dying = 99999
	neutral.current_stats.speed = speed + rand_range(-25, 25)
	neutral.current_stats.armor = armor
	
	var collision = CollisionShape2D.new()
	collision.name = "Collision"
	var shape2d = CircleShape2D.new()
	shape2d.radius = 20
	collision.shape = shape2d
	
	var hitbox = Area2D.new()
	hitbox.collision_layer = 1 << 3
	hitbox.monitoring = false
	hitbox.monitorable = true
	hitbox.name = "Hitbox"
	hitbox.add_child(collision)
	hitbox.set_script(HITBOX)
	hitbox.damage = dmg
	
	neutral._hurtbox.collision_mask = 1 << 2 | 1 << 4
	neutral.collision_mask = 1 << 15
	neutral.collision_layer = 1 << 16
	neutral.call_deferred("add_child", hitbox)


func get_args()->Array :
	var dmg = base_damage
	var dmg_scaling = "("
	for stat in damage_scaling:
		dmg += Utils.get_stat(stat[0]) * stat[1]
		dmg_scaling += Utils.get_scaling_stat_text(stat[0], stat[1])
	dmg_scaling += ")"
	dmg = max(1, dmg) as int
	
	var health_boost = 0
	var health_scaling_text = "("
	for stat in health_scaling:
		health_boost += Utils.get_stat(stat[0]) * stat[1]
		health_scaling_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	health_scaling_text += ")"
	
	var speed_boost = 0
	var speed_scaling_text = "("
	for stat in speed_scaling:
		speed_boost += Utils.get_stat(stat[0]) * stat[1]
		speed_scaling_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	speed_scaling_text += ")"
	
	var armor_boost = 0
	var armor_scaling_text = "("
	for stat in armor_scaling:
		armor_boost += Utils.get_stat(stat[0]) * stat[1]
		armor_scaling_text += Utils.get_scaling_stat_text(stat[0], stat[1])
	armor_scaling_text += ")"
	
	return ["%s[color=gray] | %s[/color] %s" % [get_colored_text_by_value(dmg, base_damage), base_damage, dmg_scaling]
	, get_colored_text_by_value(health_boost as int, 0) + " " + health_scaling_text
	, get_colored_text_by_value(speed_boost, 0, true, "%d%%") + " " + speed_scaling_text
	, get_colored_text_by_value(armor_boost as int, 0) + " " + armor_scaling_text]
