extends "res://weapons/melee/melee_weapon.gd"


onready var animation_player: AnimationPlayer = $AnimationPlayer


func shoot()->void :
	.shoot()
	
	animation_player.play("shoot")


func _on_AnimationPlayer_animation_finished(anim_name: String):
	if anim_name == "shoot":
		animation_player.play("RESET")
