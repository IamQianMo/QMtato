extends "res://mods-unpacked/QianMo-QMtato/content/effects/qmtato_effect_parent.gd"


enum BonusType {HEALTH, SPEED, RANGED, FISHERMAN, DODGE, NORMAL, BULL, SUMMON, EMPTY, EXPLORER}


export (Dictionary) var taged_sprites: Dictionary = {}
export (float) var random_chance: = 0.7

var BOSS_PROTECTION_POTATOS_SCENE: PackedScene

var _possible_random_types: = [BonusType.NORMAL, BonusType.HEALTH, BonusType.SPEED, BonusType.DODGE]
var _entity_spawner = null


func _on_qmtato_wave_start(_player)->void:
	BOSS_PROTECTION_POTATOS_SCENE = load("res://mods-unpacked/QianMo-QMtato/content/characters/enemy/boss_protection_potatos_scene.tscn")
	
	_main = RunData.get_tree().current_scene
	_entity_spawner = _main._entity_spawner
	
	connect_safely(_entity_spawner, "enemy_spawned", self, "_on_enemy_spawned")


func unapply()->void :
	.unapply()
	
	disconnect_safely(_entity_spawner, "enemy_spawned", self, "_on_enemy_spawned")


func _on_enemy_spawned(enemy)->void :
	var filename: String = enemy.filename
	if filename.empty():
		return
	
	var enemy_name: = get_enemy_name_by_resource_path(filename)
	
	if enemy is Boss:
		var protection_count: int = 8
		match enemy_name:
			"10.tscn":
				change_texture(enemy, taged_sprites.cyborg)
				protection_count = 5
			"20.tscn":
				change_texture(enemy, taged_sprites.crazy)
				protection_count = 6
			"21.tscn":
				change_texture(enemy, taged_sprites.knight)
			"22.tscn":
				change_texture(enemy, taged_sprites.streamer)
			"27.tscn":
				change_texture(enemy, taged_sprites.jack)
				protection_count = 3
			"28.tscn":
				change_texture(enemy, taged_sprites.pacifist)
			"32.tscn":
				change_texture(enemy, taged_sprites.glutton)
				protection_count = 6
			"33.tscn":
				change_texture(enemy, taged_sprites.king)
				protection_count = 5
			"34.tscn":
				change_texture(enemy, taged_sprites.golem)
				protection_count = 10
			_:
				change_texture(enemy, taged_sprites.demon)
		
		attach_protection(enemy, protection_count)
		return
	
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


func attach_protection(enemy, count: int = 6)->void :
	var damage: int = 1
	var hitbox = enemy.get_node_or_null("Hitbox")
	if not hitbox == null:
		damage = max(1, round(hitbox.damage * 0.5)) as int
	var protection: Node2D = BOSS_PROTECTION_POTATOS_SCENE.instance()
	protection.set_damage(damage)
	enemy.add_child(protection)
	protection.init(count)


func attach_bonus(enemy, type: int)->void :
	var sprite: Sprite = enemy.sprite
	match type:
		BonusType.NORMAL:
			if randf() < 0.5:
				sprite.texture = taged_sprites.normal
			else:
				sprite.texture = taged_sprites.wildling
		BonusType.HEALTH:
			sprite.texture = taged_sprites.health
			enemy.current_stats.health *= 2
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
			enemy.current_stats.health *= 1.25
		BonusType.EXPLORER:
			sprite.texture = taged_sprites.explorer


func change_texture(enemy, texture: Texture, scale: Vector2 = Vector2.ONE)->void :
	var sprite: Sprite = enemy.sprite
	var image_texture: ImageTexture = ImageTexture.new()
	var image: Image = texture.get_data()
	image.resize(sprite.texture.get_width(), sprite.texture.get_height())
	image_texture.create_from_image(image)
	sprite.texture = image_texture


func get_enemy_name_by_resource_path(path: String)->String :
	var last_splitter: = path.find_last("/")
	
	var enemy_name: = path.right(last_splitter + 1)
	
	return enemy_name
