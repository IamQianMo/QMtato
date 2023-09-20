extends Node


signal health_changed(current_health)
signal charge_changed(charge_now)


onready var _hint = $HealthBar/Hint
onready var _health_bar = $HealthBar
onready var _skill_time_remain = $SkillTimeRemain
onready var _skill_time_hint = $SkillTimeRemain/Hint

var _max_health: = 10
var _max_charge: = 15
var _current_health: = 10


func _ready():
	var _error = connect("health_changed", self, "_on_health_changed")
	_error = connect("charge_changed", self, "_on_charge_change")


func init(max_health:int, max_charge:int)->void:
	_max_health = max_health
	_max_charge = max_charge
	_current_health = max_health
	update_health()
	_skill_time_remain.set_max(max_charge)
	update_charge(0)


func _on_charge_change(charge_now)->void:
	update_charge(charge_now)


func _on_health_changed(current_health)->void:
	_current_health = current_health
	update_health()


func update_health():
	_health_bar.value = (_current_health * 1.0) / _max_health
	_hint.text = str(_current_health) + "/" + str(_max_health)


func update_charge(charge_now):
	_skill_time_remain.value = charge_now
	_skill_time_hint.text = str(charge_now) + "/" + str(_max_charge)
