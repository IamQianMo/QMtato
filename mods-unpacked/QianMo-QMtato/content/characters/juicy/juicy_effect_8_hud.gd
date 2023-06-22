extends TextureProgress


onready var label = $MarginContainer/LemonLabel

var _unchecked_value = 0


func set_value(p_value)->void :
	value = p_value
	_unchecked_value = p_value
	
	label.text = "%d / %d" % [_unchecked_value, max_value]


func set_max_value(p_max_value)->void :
	max_value = p_max_value
	value = _unchecked_value
	
	label.text = "%d / %d" % [_unchecked_value, max_value]
