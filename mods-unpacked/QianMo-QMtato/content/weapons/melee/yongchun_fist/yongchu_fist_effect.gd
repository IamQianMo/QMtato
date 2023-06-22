extends Effect


func apply()->void :
	
	value = 4
	if check_character("character_multitasker") or check_character("character_cryptid"):
		value = 2
	if check_character("character_ghost"):
		value = 1
	if check_character("character_ghost") and check_character("character_multitasker"):
		value = 0
	
	RunData.effects[key] += value


func get_args()->Array:
	var temp_value = value
	
	if check_character("character_multitasker") or check_character("character_cryptid"):
		temp_value = 2
	if check_character("character_ghost"):
		temp_value = 1
	if check_character("character_ghost") and check_character("character_multitasker"):
		temp_value = 0
		
	var displayed_key = key
	
	return [str(temp_value), tr(displayed_key.to_upper())]


func check_character(id:String)->bool :
	if RunData.current_character == null:
		return false
	return RunData.current_character.my_id == id or (RunData.current_character.my_id == "GMO_dummy" and RunData.gmo_characters.has(id))
