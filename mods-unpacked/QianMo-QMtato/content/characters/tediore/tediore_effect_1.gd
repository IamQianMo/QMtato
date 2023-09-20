extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


export (PackedScene) var controller_scene:PackedScene = null


func _on_qmtato_wave_start(player)->void:
	._on_qmtato_wave_start(player)
	
	detach_weapons()


func detach_weapons(weapon = null, show_legs = true, player = null)->void :
	var current_player = _player if is_instance_valid(_player) else player
	if current_player and is_instance_valid(current_player):
		if not weapon:
			for weapon in current_player.current_weapons.duplicate():
				if is_instance_valid(weapon) and not has_controller(weapon):
					var controller = controller_scene.instance()
					controller.name = "QMtatoTedioreController"
					controller.init(weapon, current_player, rand_range(400.0, 600.0), show_legs)
					weapon.call_deferred("add_child", controller)
		else:
			if is_instance_valid(weapon) and not has_controller(weapon):
				var controller = controller_scene.instance()
				controller.name = "QMtatoTedioreController"
				controller.init(weapon, current_player, rand_range(400.0, 600.0), show_legs)
				weapon.call_deferred("add_child", controller)


func has_controller(weapon)->bool :
	return weapon.has_node("QMtatoTedioreController")


func detach_weapon(weapon = null, show_legs = true, player = null)->void :
	call_deferred("detach_weapons", weapon, show_legs, player)
