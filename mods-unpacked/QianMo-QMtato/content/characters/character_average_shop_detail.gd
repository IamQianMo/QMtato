extends "res://items/global/effect.gd"


func apply()->void :
	pass


func unapply()->void :
	pass


func get_args()->Array:
	
	var small_icon:Texture
	var w = 20 * ProgressData.settings.font_size
	var text:String = ""
	
	if not RunData.current_character == null:
		for wanted_tag in RunData.current_character.wanted_tags:
			small_icon = ItemService.get_stat_small_icon(wanted_tag)
			
			if small_icon:
				text += "[img=%sx%s]%s[/img] " % [w, w, small_icon.resource_path]
	else:
		small_icon = ItemService.get_stat_small_icon("stat_melee_damage")
		if small_icon:
			text += "[img=%sx%s]%s[/img] " % [w, w, small_icon.resource_path]
	
	text = text.trim_suffix(" ")
	
	return [text]
	
