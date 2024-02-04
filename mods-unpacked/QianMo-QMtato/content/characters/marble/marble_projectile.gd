extends "res://projectiles/player_projectile.gd"


onready var stop_timer:Timer = $StopTimer
onready var return_timer:Timer = $ReturnTimer
onready var hitbox = $Hitbox

var _is_returning: = false


func _ready():
	rotate(rand_range(-PI, PI))


func init(target_position:Vector2, slide_time:float)->void :
	stop_timer.wait_time = rand_range(slide_time * 0.75, slide_time * 1.25)
	stop_timer.start()
	
	velocity = (target_position - global_position) / slide_time


func start_return_behavior(target_position:Vector2 = Vector2.ZERO, slide_time:float = 1.5)->void :
	_hitbox.enable()
	
	return_timer.wait_time = slide_time
	return_timer.start()
	
	velocity = (target_position - global_position) / slide_time
	
	set_physics_process(true)
	
	_is_returning = true


func _on_StopTimer_timeout():
	if _is_returning:
		return
	
	velocity = Vector2.ZERO
	
	_hitbox.disable()
	set_physics_process(false)


func _on_ReturnTimer_timeout():
	set_to_be_destroyed()


func _on_Hitbox_hit_something(thing_hit:Node, damage_dealt:int)->void :
	._on_Hitbox_hit_something(thing_hit, damage_dealt)
	
	if thing_hit is Boss and is_instance_valid(thing_hit):
		thing_hit.take_damage(damage_dealt * 7, hitbox, false, false)
