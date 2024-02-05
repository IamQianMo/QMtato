extends CenterContainer


func _on_RedirectButton_pressed():
	OS.shell_open("https://steamcommunity.com/sharedfiles/filedetails/?id=3153961011")


func _on_ConfirmButton_pressed():
	queue_free()
