extends "res://effects/weapons/null_effect.gd"


export (Resource) var exploding_effect = null
export (bool) var stick: = true
export (bool) var explode_instantly: = false
export (float) var damage_increase_per_stack: = 0.2
export (float) var explosion_delay: = 2.0
export (int) var type: = 0


func get_args()->Array :
	var text:String = tr("QMTATO_GYROJETS")
	
	if stick or explode_instantly:
		text += "\n"
		
		if stick:
			text += tr("QMTATO_GYROJETS_STICK") + "\n"
		
		if explode_instantly:
			text += tr("QMTATO_GYROJETS_EXPLODE_INSTANTLY") + "\n"
	
	text = text.trim_suffix("\n")
	
	return [text, "%.1f" % explosion_delay, str(round(damage_increase_per_stack * 100))]
