extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


enum BonusType {HEALTH, SPEED, RANGED, FISHERMAN, DODGE, NORMAL, BULL, SUMMON, EMPTY, EXPLORER}


export (Dictionary) var taged_sprites: Dictionary = {}
export (float) var random_chance: = 0.7

var _possible_random_types: = [BonusType.NORMAL, BonusType.HEALTH, BonusType.SPEED, BonusType.DODGE]


func _on_qmtato_wave_start(_player)->void:
	_main = RunData.get_tree().current_scene
	
	connect_safely(_main._entity_spawner, "enemy_spawned", self, "_on_enemy_spawned")


func unapply()->void :
	.unapply()
	
	disconnect_safely(_main._entity_spawner, "enemy_spawned", self, "_on_enemy_spawned")


func _on_enemy_spawned(enemy)->void :
	var filename: String = enemy.filename
	if filename.empty():
		return
	
	if enemy is Boss:
		return
	
	var enemy_name: = get_enemy_name_by_resource_path(filename)
	print(enemy_name)
	match enemy_name:
		"3.tscn", "8.tscn", "17.tscn":
			attach_bonus(enemy, BonusType.RANGED)
		"5.tscn", "25.tscn", "8.tscn":
			attach_bonus(enemy, BonusType.BULL)
		"12.tscn":
			attach_bonus(enemy, BonusType.SPEED)
		"13.tscn":
			attach_bonus(enemy, BonusType.EXPLORER)
		"16.tscn", "24.tscn":
			attach_bonus(enemy, BonusType.SUMMON)
		"23.tscn":
			attach_bonus(enemy, BonusType.EMPTY)
		"26.tscn":
			attach_bonus(enemy, BonusType.FISHERMAN)
		_:
			if randf() < random_chance:
				attach_bonus(enemy, Utils.get_rand_element(_possible_random_types))
			else:
				attach_bonus(enemy, BonusType.NORMAL)


func attach_bonus(enemy, type: int)->void :
	var sprite: Sprite = enemy.sprite
	match type:
		BonusType.NORMAL:
			sprite.texture = taged_sprites.normal
		BonusType.HEALTH:
			sprite.texture = taged_sprites.health
			enemy.current_stats.health *= 1.75
			enemy.current_stats.speed *= 0.75
		BonusType.SPEED:
			sprite.texture = taged_sprites.speed
			enemy.current_stats.health *= 0.75
			enemy.current_stats.speed *= 1.5
		BonusType.DODGE:
			sprite.texture = taged_sprites.dodge
			enemy.current_stats.health *= 0.5
			enemy.current_stats.dodge += 0.33
		BonusType.RANGED:
			sprite.texture = taged_sprites.ranged
		BonusType.FISHERMAN:
			sprite.texture = taged_sprites.fisherman
		BonusType.BULL:
			sprite.texture = taged_sprites.bull
		BonusType.EMPTY:
			sprite.texture = taged_sprites.empty_sprite
		BonusType.SUMMON:
			sprite.texture = taged_sprites.summon
		BonusType.EXPLORER:
			sprite.texture = taged_sprites.explorer


func get_enemy_name_by_resource_path(path: String)->String :
	var last_splitter: = path.find_last("/")
	
	var enemy_name: = path.right(last_splitter+1)
	
	return enemy_name
