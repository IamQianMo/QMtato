extends "res://singletons/item_service.gd"


var QmtatoMainEventListener = null


func _ready():
	QmtatoMainEventListener = ProgressData.get_node_or_null("QmtatoMainEventListener")


func init_unlocked_pool()->void :
	.init_unlocked_pool()
	
	if QmtatoMainEventListener:
		QmtatoMainEventListener.emit_signal("tiers_data_reseted")
