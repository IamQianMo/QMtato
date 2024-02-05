extends "res://ui/menus/title_screen/title_screen.gd"


var WARNING_SCENE: = load("res://mods-unpacked/QianMo-QMtato/content/UI/outdated_warning.tscn")


func _ready():
	add_child(WARNING_SCENE.instance())
