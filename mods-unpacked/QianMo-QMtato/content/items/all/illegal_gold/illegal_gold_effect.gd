extends Effect


export (int) var gold_increase_per_wave: = 20

var _gold_added: = 0


func apply()->void :
	_gold_added = value + (RunData.current_wave * gold_increase_per_wave)
	RunData.add_gold(_gold_added)


func unapply()->void:
	RunData.remove_gold(_gold_added)
	_gold_added = 0


func get_args()->Array:
	if _gold_added == 0:
		var scaling_text = "%d (%d + %dx%d)" % [value + (RunData.current_wave * gold_increase_per_wave), value, RunData.current_wave, gold_increase_per_wave]
		return [scaling_text]
	else:
		return [str(_gold_added)]
