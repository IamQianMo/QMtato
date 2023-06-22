class_name QmtatoMainEventListener
extends Node


signal player_spawned(player)
signal tiers_data_reseted


const MOD_NAME = "QianMo-QMtato"

var dir = ""
var ModsConfigInterface = null

var _player = null
var _applied_effects = []
var _applying_effects = []
var _setting_changed: = false

var _current_settings:Dictionary = {
	"QMTATO_ENABLE_ITEMS": true,
	"QMTATO_ENABLE_WEAPONS": true,
	"QMTATO_ENABLE_CHARACTERS": true,
}


func _init(dirs:String):
	name = "QmtatoMainEventListener"
	dir = dirs


func _ready():
	ModsConfigInterface = get_node_or_null("/root/ModLoader/dami-ModOptions/ModsConfigInterface")
	if ModsConfigInterface:
		ModsConfigInterface.connect("setting_changed", self, "_on_setting_changed")
	
	if not RunData.has_user_signal("qmtato_on_wave_start"):
		RunData.add_user_signal("qmtato_on_wave_start")
	var _error = connect("player_spawned", self, "_on_player_spawned")
	
	if ModsConfigInterface:
		call_deferred("_load_settings_init")


func _on_player_spawned(player):
	if not is_instance_valid(player):
		return
	
	_player = player
	
	for item in RunData.items:
		for effect in item.effects:
			if not effect.get_id().find("qmtato_effect") == -1:
				effect.apply_connection()
				_applying_effects.append(effect)
				if not _applied_effects.has(effect):
					_applied_effects.append(effect)
	for weapon in RunData.weapons:
		for effect in weapon.effects:
			if not effect.get_id().find("qmtato_effect") == -1:
				effect.apply_connection()
				_applying_effects.append(effect)
				if not _applied_effects.has(effect):
					_applied_effects.append(effect)
	for effect in _applied_effects.duplicate():
		if not _applying_effects.has(effect):
			effect.unapply()
			_applied_effects.erase(effect)
	_applying_effects.clear()
	
	RunData.emit_signal("qmtato_on_wave_start", player)


func load_settings()->Dictionary :
	var path = ProgressData.SAVE_PATH
	path = path.replace("/save.json", "/qmtato_settings.json")
	
	var save_file = File.new()
	if not save_file.file_exists(path):
		save_settings()
		return get_settings()
	
	var error = save_file.open(path, File.READ)
	if not error:
		var settings = parse_json(save_file.get_line())
		
		for key in _current_settings.keys():
			if settings.has(key):
				_current_settings[key] = settings[key]
		
		save_file.close()
	
	return get_settings()


func save_settings()->void :
	if not _setting_changed:
		return
	_setting_changed = false
	
	var path = ProgressData.SAVE_PATH
	path = path.replace("/save.json", "/qmtato_settings.json")
	
	var save_file = File.new()
	var error = save_file.open(path, File.WRITE)
	
	if not error:
		if save_file:
			save_file.store_line(to_json(get_settings()))
			save_file.close()


func get_settings()->Dictionary :
	if not ModsConfigInterface:
		return {
				"QMTATO_ENABLE_ITEMS": true,
				"QMTATO_ENABLE_WEAPONS": true,
				"QMTATO_ENABLE_CHARACTERS": true,
			}
	return _current_settings


func _on_setting_changed(setting_name, value, mod_name)->void :
	if mod_name == MOD_NAME:
		_current_settings[setting_name] = value
		
		_setting_changed = true
		save_settings()


func _load_settings_init()->void :
	var _error_settings = load_settings()
	
	var settings = get_settings()
	
	if ModsConfigInterface:
		for key in settings.keys():
			ModsConfigInterface.on_setting_changed(key, settings[key], MOD_NAME)
