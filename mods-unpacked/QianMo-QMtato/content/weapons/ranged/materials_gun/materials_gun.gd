extends "res://weapons/ranged/ranged_weapon.gd"


const DEFAULT_SPRITE = preload("res://items/materials/material_0000.png")
const MAX_MATERIALS:int = 6

onready var _attract_area = $Sprite/AttractArea/Collision
onready var _pickup_area = $Sprite/PickupArea/CollisionShape2D

var materials_queue: = []
var gold_on_kill_effect = null
var lose_gold_on_shot_effect = null
var boosted_damage_factor: = 0.3
var _qmtato_main = null
var _is_testing: = false


func _ready():
	_qmtato_main = RunData.get_tree().current_scene
	
	if _qmtato_main.name == "TitleScreen":
		_is_testing = true
	
	var wave_timer = _qmtato_main.get("_wave_timer")
	if wave_timer is WaveTimer:
		_qmtato_main._wave_timer.connect("timeout", self, "_on_wave_timer_timeout")
	
	for effect in effects:
		if effect.key == "gold_on_kill":
			gold_on_kill_effect = effect
		elif effect.key == "lose_gold_on_shot":
			lose_gold_on_shot_effect = effect


func on_weapon_hit_something(_thing_hit:Node, _damage_dealt:int)->void :
	.on_weapon_hit_something(_thing_hit, _damage_dealt)
	
	if randf() < (gold_on_kill_effect.chance / 100.0) and not _is_testing:
		RunData.add_gold(gold_on_kill_effect.value)
		RunData.add_xp(gold_on_kill_effect.value)
		RunData.emit_signal("stat_added", "stat_materials", gold_on_kill_effect.value, - 15.0)


func should_shoot()->bool :
	if not materials_queue.empty():
		return .should_shoot()
	else:
		materials_queue.push_back([1, rand_range(0, 2 * PI), DEFAULT_SPRITE, Color.red, Vector2(1.0, 1.0)])
		
		if randf() < (lose_gold_on_shot_effect.value / 100.0) and not _is_testing:
			RunData.gold -= 1
			RunData.emit_signal("gold_changed", RunData.gold)
		
		return false


func on_projectile_shot(projectile:Node2D)->void :
	.on_projectile_shot(projectile)
	
	var gold_data = materials_queue.pop_back()
	if gold_data:
		var hitbox = projectile.get("_hitbox")
		if hitbox and "damage" in hitbox:
			hitbox.damage *= gold_data[0] * boosted_damage_factor + 1.0
		
		projectile.set_deferred("rotation", gold_data[1])
		projectile.set_deferred("scale", gold_data[4])
		
		var sprite = projectile.get_node_or_null("Sprite")
		if sprite:
			var animation_player:AnimationPlayer = projectile.get_node_or_null("AnimationPlayer")
			if animation_player:
				animation_player.advance(animation_player.current_animation_length)
			sprite.set_deferred("texture", gold_data[2])
			sprite.set_deferred("modulate", gold_data[3])


func _on_wave_timer_timeout()->void :
	_attract_area.set_deferred("disabled", true)
	_pickup_area.set_deferred("disabled", true)
	
	var total: = 0.0
	for gold in materials_queue:
		total += gold[0] * 0.5
	var actual_value = round(total) as int
	RunData.add_gold(actual_value)
	RunData.add_xp(actual_value)


func _on_AttractArea_area_entered(area:Area2D):
	if materials_queue.size() > 3 or not area is Gold:
		return
	
	if area.is_connected("picked_up", _qmtato_main, "on_gold_picked_up"):
		area.disconnect("picked_up", _qmtato_main, "on_gold_picked_up")
	area.set_collision_layer(1 << 15)
	area.attracted_by = self


func _on_PickupArea_area_entered(area:Area2D):
	if materials_queue.size() > MAX_MATERIALS or not area is Gold:
		return
	
	_qmtato_main._golds.erase(area)
	
	if ProgressData.settings.alt_gold_sounds:
		SoundManager.play(Utils.get_rand_element(_qmtato_main.gold_alt_pickup_sounds), - 5, 0.2)
	else :
		SoundManager.play(Utils.get_rand_element(_qmtato_main.gold_pickup_sounds), 0, 0.2)
	
	var value = area.value
	
	if randf() < RunData.effects["chance_double_gold"] / 100.0:
		RunData.tracked_item_effects["item_metal_detector"] += value
		value *= 2
		area.boosted *= 2
	
	if randf() < RunData.effects["heal_when_pickup_gold"] / 100.0:
		RunData.emit_signal("healing_effect", 1, "item_cute_monkey")
	
	var gold_rotation = area.rotation
	var gold_sprite = area.get("sprite")
	var gold_modulate = area.modulate
	var gold_scale = area.scale
	
	if gold_sprite:
		gold_sprite = gold_sprite.texture.duplicate()
	else:
		gold_sprite = DEFAULT_SPRITE
	materials_queue.push_back([value, gold_rotation, gold_sprite, gold_modulate, gold_scale])
	
	area.pickup()
