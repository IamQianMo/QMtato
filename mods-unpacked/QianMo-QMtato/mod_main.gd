extends Node


const MOD_DIR = "QianMo-QMtato/"
const MOD_NAME = "QianMo-QMtato"

var dir = ""
var ext_dir = ""
var trans_dir = ""
var QmtatoMainEventListener = null
var qmtato_content_data = null
var temp_content_data = null

var mod_effects: = [
	preload("res://mods-unpacked/QianMo-QMtato/content/effects/fruit_trees/fruit_tree_effect.gd"),
	preload("res://mods-unpacked/QianMo-QMtato/content/effects/treasure_area/treasure_area_effect.gd"),
]


func _init(_modLoader = ModLoader):
	ModLoaderLog.info("Init", MOD_NAME)
	
	# ModLoader 6.0
	dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR
	
	ext_dir = dir + "extensions/"
	trans_dir = dir + "translations/"
	
	# ModLoader 6.0
	ModLoaderMod.install_script_extension(ext_dir + "main.gd")
	ModLoaderMod.install_script_extension(ext_dir + "singletons/item_service.gd")
	ModLoaderMod.install_script_extension(ext_dir + "singletons/run_data.gd")
	
	# Show outdated warning in title screen
#	ModLoaderMod.install_script_extension(ext_dir + "title_screen.gd")
	
	ModLoaderMod.add_translation(trans_dir + "languages/mod_translation.zh.translation")
	ModLoaderMod.add_translation(trans_dir + "languages/mod_translation.en.translation")


func _ready():
	ModLoaderLog.info('Done', MOD_NAME)
	
	QmtatoMainEventListener = load(dir + "qmtato_main_event_listener.gd").new(dir)
	QmtatoMainEventListener.name = "QmtatoMainEventListener"
	ProgressData.add_child(QmtatoMainEventListener)
	var _error = QmtatoMainEventListener.connect("tiers_data_reseted", self, "_on_tiers_data_reseted")
	
	ItemService.effects.append_array(mod_effects)
	
	var ContentLoader = get_node("/root/ModLoader/Darkly77-ContentLoader/ContentLoader")
	
	ContentLoader.load_data(dir + "content_data/ghost_smg_content.tres", MOD_NAME)
	temp_content_data = load(dir + "content_data/ghost_smg_content.tres")
	qmtato_content_data = temp_content_data.duplicate()
	qmtato_content_data.weapons_characters.clear()
	_add_content_items(qmtato_content_data, temp_content_data)
	
	ContentLoader.load_data(dir + "content_data/face_puncher_content.tres", MOD_NAME)
	temp_content_data = load(dir + "content_data/face_puncher_content.tres")
	_add_content_items(qmtato_content_data, temp_content_data)
	
	ContentLoader.load_data(dir + "content_data/yongchun_fist_content.tres", MOD_NAME)
	temp_content_data = load(dir + "content_data/yongchun_fist_content.tres")
	_add_content_items(qmtato_content_data, temp_content_data)
	
	ContentLoader.load_data(dir + "content_data/terra_blade_content.tres", MOD_NAME)
	temp_content_data = load(dir + "content_data/terra_blade_content.tres")
	_add_content_items(qmtato_content_data, temp_content_data)
	
	ContentLoader.load_data(dir + "content_data/luoyang_shovel_content.tres", MOD_NAME)
	temp_content_data = load(dir + "content_data/luoyang_shovel_content.tres")
	_add_content_items(qmtato_content_data, temp_content_data)
	
	ContentLoader.load_data(dir + "content_data/qmtato_items_content.tres", MOD_NAME)
	temp_content_data = load(dir + "content_data/qmtato_items_content.tres")
	_add_content_items(qmtato_content_data, temp_content_data)
	
	# since Brotato 1.0 START
	ContentLoader.load_data(dir + "content_data/qmtato_preview_content_data.tres", MOD_NAME)
	temp_content_data = load(dir + "content_data/qmtato_preview_content_data.tres")
	_add_content_items(qmtato_content_data, temp_content_data)
	
	temp_content_data = load(dir + "content_data/qmtato_preview_starting_weapons.tres")
	for i in temp_content_data.weapons.size():
		for character in temp_content_data.weapons_characters[i]:
			character.starting_weapons.push_back(temp_content_data.weapons[i])
	# since Brotato 1.0 END
	
	_setup_item_service(qmtato_content_data)
	
	var _error_progress_data_connect = ProgressData.connect("ready", self, "_on_progress_data_ready")


func _setup_item_service(contents)->void :
	ItemService.weapons.append_array(contents.weapons)
#	ItemService.items.append_array(contents.items)
#	ItemService.characters.append_array(contents.characters)
#	ItemService.sets.append_array(contents.sets)                  # @since 2.1.0
#	ChallengeService.challenges.append_array(contents.challenges) # @since 2.1.0
#	ItemService.upgrades.append_array(contents.upgrades)          # @since 5.3.0
#	ItemService.consumables.append_array(contents.consumables)    # @since 5.3.0
#	ItemService.elites.append_array(contents.elites)              # @since 5.3.0
#	ItemService.difficulties.append_array(contents.difficulties)
#
#	for i in contents.weapons_characters.size():
#		if contents.weapons[i]:
#			var wpn_characters = contents.weapons_characters[i]
#			for character in wpn_characters:
#				character.starting_weapons.push_back(contents.weapons[i])  # @since 6.1.0


func _on_tiers_data_reseted()->void :
	call_deferred("check_mod_contents")


func _on_progress_data_ready()->void :
	call_deferred("check_mod_contents", true)
	
	# avoid crash when resume games with mod weapons save files
	call_deferred("_remove_duplicated_weapons")


func _remove_duplicated_weapons()->void :
	var ids: = []
	for weapon in qmtato_content_data.weapons:
		ids.push_back(weapon.my_id)
	
	var weapon_dict: = {}
	for weapon in ItemService.weapons:
		if weapon.my_id in ids:
			if weapon_dict.has(weapon):
				weapon_dict[weapon] += 1
			else:
				weapon_dict[weapon] = 1

	for weapon in weapon_dict.keys():
		var count = weapon_dict[weapon]
		if count > 1:
			var diff:int = count - 1
			for i in diff:
				ItemService.weapons.erase(weapon)


func check_mod_contents(is_init = false)->void :
	if QmtatoMainEventListener:
		var settings:Dictionary
		if is_init:
			settings = QmtatoMainEventListener.load_settings()
		else:
			settings = QmtatoMainEventListener.get_settings()

		var TierData = ItemService.TierData
		if not settings["QMTATO_ENABLE_ITEMS"]:
			for item in qmtato_content_data.items:
				ItemService._tiers_data[item.tier][TierData.ALL_ITEMS].erase(item)
				ItemService._tiers_data[item.tier][TierData.ITEMS].erase(item)
		if not settings["QMTATO_ENABLE_WEAPONS"]:
			for item in qmtato_content_data.weapons:
				ItemService._tiers_data[item.tier][TierData.ALL_ITEMS].erase(item)
				ItemService._tiers_data[item.tier][TierData.WEAPONS].erase(item)
		if not settings["QMTATO_ENABLE_CHARACTERS"]:
			for item in qmtato_content_data.characters:
				ItemService.characters.erase(item)

#		if not settings["QMTATO_ENABLE_ITEMS"]:
#			for mod_item in qmtato_content_data.items:
#				for item in ItemService.items:
#					if item.my_id == mod_item.my_id:
#						ItemService._tiers_data[item.tier][TierData.ALL_ITEMS].erase(item)
#						ItemService._tiers_data[item.tier][TierData.ITEMS].erase(item)
#						break
#		if not settings["QMTATO_ENABLE_WEAPONS"]:
#			for mod_item in qmtato_content_data.weapons:
#				for item in ItemService.weapons:
#					if item.my_id == mod_item.my_id:
#						ItemService._tiers_data[item.tier][TierData.ALL_ITEMS].erase(item)
#						ItemService._tiers_data[item.tier][TierData.WEAPONS].erase(item)
#						break
#		if not settings["QMTATO_ENABLE_CHARACTERS"]:
#			for mod_item in qmtato_content_data.characters:
#				for item in ItemService.characters:
#					if item.my_id == mod_item.my_id:
#						ItemService.characters.erase(item)
#						break


func _add_content_items(content_data:Resource, from_content_data:Resource)->void :
	for key in ["items", "weapons", "characters"]:
		var property = content_data.get(key)
		var from_property = from_content_data.get(key)
		if from_property is Array and not from_property.empty():
			property.append_array(from_property)
