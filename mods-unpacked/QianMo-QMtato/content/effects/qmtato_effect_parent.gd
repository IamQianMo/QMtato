extends "res://items/global/effect.gd"


var _player = null
var _main = null


static func get_id()->String:
	return "qmtato_effect"


func apply()->void:
	pass


func unapply()->void:
	if RunData.is_connected("qmtato_on_wave_start", self, "_on_qmtato_wave_start_prefix"):
		RunData.disconnect("qmtato_on_wave_start", self, "_on_qmtato_wave_start_prefix")


func apply_connection()->void:
	_player = TempStats.player
	if not RunData.is_connected("qmtato_on_wave_start", self, "_on_qmtato_wave_start_prefix"):
		RunData.connect("qmtato_on_wave_start", self, "_on_qmtato_wave_start_prefix")


func _on_qmtato_wave_start_prefix(player):
	yield(RunData.get_tree().create_timer(0.1), "timeout")
	
	if player and is_instance_valid(player):
		_on_qmtato_wave_start(player)


func _on_qmtato_wave_start(player)->void:
	_player = player


func connect_safely(obj, signal_name:String, target, call_back:String, binds:Array = [])->void:
	if obj == null or not is_instance_valid(obj) or obj.is_connected(signal_name, target, call_back):
		return
	if binds.size() == 0:
		var _error = obj.connect(signal_name, target, call_back)
	else:
		var _error = obj.connect(signal_name, target, call_back, binds)


func disconnect_safely(obj, signal_name:String, target, call_back:String)->void:
	if obj == null or not is_instance_valid(obj) or not obj.is_connected(signal_name, target, call_back):
		return
	obj.disconnect(signal_name, target, call_back)


func is_mobile_device()->bool:
	var system_name = OS.get_name()
	
	return system_name == "Android" or system_name == "iOS"


func instance_of(obj:Object, parent:Script)->bool :
	var script:Script = obj.get_script()
	var parent_resource_path = parent.resource_path
	if parent and script:
		if script.resource_path == parent_resource_path:
			return true
		else:
			script = script.get_base_script()
			while script:
				if script.resource_path == parent_resource_path:
					return true
				script = script.get_base_script()
	return false


# NOTE: Parameter squeeze is used for result type (Array or String)
func get_colored_text_by_value(val, base_val, squeeze:bool = true, format:String = "%s", reversed:bool = false) :
	var result
	if val < base_val:
		if not reversed:
			result = [("[color=red]" + format + "[/color]") % val, -1]
		else:
			result = [("[color=#00ff00]" + format + "[/color]") % val, -1]
	else:
		if val >= 0:
			if not reversed:
				result = [("[color=#00ff00]" + format + "[/color]") % val, 1]
			else:
				result = [("[color=red]" + format + "[/color]") % val, 1]
		else:
			if not reversed:
				result = [("[color=#00ff00]" + format + "[/color]") % val, -1]
			else:
				result = [("[color=red]" + format + "[/color]") % val, -1]
	
	if squeeze:
		return result[0]
	else:
		return result


# NOTE: Parameter isign is used for color. (-1 = red, 1 = green, others = white)
func get_colored_text_by_sign(text, isign:int = 0)->String :
	if isign == -1:
		return "[color=red]%s[/color]" % text
	elif isign == 1:
		return "[color=#00ff00]%s[/color]" % text
	else:
		return "[color=white]%s[/color]" % text
