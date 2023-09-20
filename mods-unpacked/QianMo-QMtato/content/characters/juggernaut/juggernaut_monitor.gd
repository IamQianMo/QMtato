extends Node


export (float) var scaling_factor: = 0.5
export (Resource) var juggernaut_voice

onready var _cooldown_bar = $CooldownBar
onready var _hint = $CooldownBar/Hint
onready var _blade_fury_duration_timer = $BladeFuryDurationTimer
onready var _cooldown_timer = $CooldownTimer
onready var _cooldown_hint = $CooldownBar/Hint
onready var _hitbox = $Hitbox
onready var _sprite = $Hitbox/Knife

const REMOVE_ATTACK_SPEED = 200

var _player = null
var _is_in_blade_fury: = false
var _original_rotation = 0
var _wave_ended: = false
var _time:float = 0
var _rotation_speed = 25
var _cooldown: = 18.0

var _time_step:float = 0.15
var _is_blade_fury_ready: = false

var _trail_scene_instance = null


func _ready():
	set_physics_process(false)
	
	var wave_timer = RunData.get_tree().current_scene._wave_timer
	if not wave_timer.is_connected("timeout", self, "_on_wave_timer_timeout"):
		wave_timer.connect("timeout", self, "_on_wave_timer_timeout")
	
	apply_cooldown()
	_cooldown_timer.start()
	
	_hitbox.connect("hit_something", self, "_on_hitbox_hit_something")


func _on_hitbox_hit_something(thing_hit, damage_dealt)->void:
	RunData.tracked_item_effects["character_juggernaut"] += damage_dealt
	
	var raw_direction = _player.global_position - thing_hit.global_position
	thing_hit._knockback_vector += raw_direction.normalized() * 12


func init(player):
	_player = player


func _unhandled_input(event):
	if event.is_pressed():
		if event is InputEventKey:
			if (event.scancode == KEY_F or event.scancode == KEY_SPACE) and not _is_in_blade_fury and _is_blade_fury_ready:
				avtive_blade_furry()
		elif event is InputEventJoypadButton:
			if event.button_index == JOY_XBOX_A and not _is_in_blade_fury and _is_blade_fury_ready:
				avtive_blade_furry()


func avtive_blade_furry()->void:
	if _wave_ended:
		return
	
	_cooldown_bar.hide()
	
	var dmg = RunData.get_dmg(Utils.get_stat("stat_melee_damage") * scaling_factor) as int
	var crit_chance = 0.05 + (Utils.get_stat("stat_crit_chance") / 100.0)
	_hitbox.set_damage(dmg, 1.0, crit_chance, 2, RunData.effects["burn_chance"], false)
	_hitbox.show()
	_hitbox.enable()
	
	if not _blade_fury_duration_timer.is_stopped():
		_blade_fury_duration_timer.stop()
	_blade_fury_duration_timer.start()
	
	set_physics_process(true)
	
	if randf() <= 0.5:
		SoundManager2D.play(juggernaut_voice, _player.global_position, 1.5, 0.05)
	
	if not _cooldown_timer.is_stopped():
		_cooldown_timer.stop()
	
	_original_rotation = _player.rotation
	_is_in_blade_fury = true
	
	RunData.effects["stat_attack_speed"] -= REMOVE_ATTACK_SPEED
	RunData.effects["stat_speed"] += 30
	_player.update_player_stats()


func _physics_process(delta):
	_player.rotation += _rotation_speed * delta


func _on_wave_timer_timeout()->void:
	if _is_in_blade_fury:
		_on_BladeFuryDurationTimer_timeout()
	
	_cooldown_timer.stop()
	_wave_ended = true
	
	queue_free()


func _on_CooldownTimer_timeout():
	update_cooldown(1)


func update_cooldown(value:float)->void:
	_cooldown_bar.value += value
	_cooldown_hint.text = "%.1f%%" % _cooldown_bar.value
	
	if _cooldown_bar.value >= 100:
		_is_blade_fury_ready = true
		_cooldown_timer.stop()
		_cooldown_hint.text = "Ready"


func _on_BladeFuryDurationTimer_timeout():
	if _wave_ended:
		return
		
	_cooldown_bar.show()
	_hitbox.hide()
	_hitbox.disable()
	
	if not _cooldown_timer.is_stopped():
		_cooldown_timer.stop()
	
	_is_in_blade_fury = false
	_is_blade_fury_ready = false
	
	update_cooldown(-100)
	set_physics_process(false)
	
	_player.rotation = _original_rotation
	
	RunData.effects["stat_attack_speed"] += REMOVE_ATTACK_SPEED
	RunData.effects["stat_speed"] -= 30
	_player.update_player_stats()
	_player.reset_weapons_cd()
	
	apply_cooldown()
	_cooldown_timer.start()


func apply_cooldown()->void :
	var atk_speed = Utils.get_stat("stat_attack_speed") / 100.0
	_time_step = _cooldown / 100.0
	if atk_speed >= 0:
		_time_step *= 1 / (1 + atk_speed)
	else:
		_time_step *= 1 + abs(atk_speed)
	_cooldown_timer.wait_time = _time_step
