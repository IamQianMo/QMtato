extends Effect


export (int) var convert_percent: = 50
export (int) var convert_amount: = 4
export (String) var stat_converted: = "stat_armor"

var _converted_value: = 0
var _added_value = 0


func apply()->void :
	_converted_value = 0
	
	var stat_value = RunData.effects[stat_converted] as float
	_converted_value = (stat_value * (convert_percent / 100.0)) as int
	
	RunData.effects[stat_converted] -= _converted_value
	
	_added_value = (1.0 * _converted_value * value / convert_amount) as int
	RunData.effects[key] += _added_value


func unapply()->void :
	RunData.effects[stat_converted] += _converted_value
	RunData.effects[key] -= _added_value
	
	_converted_value = 0


func get_args()->Array :
	var args = ["%d%%" % convert_percent, 
		tr(stat_converted.to_upper()), 
		tr(key.to_upper()), 
		str(convert_amount),
		str(value)]
	
	return args
