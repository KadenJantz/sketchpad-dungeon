extends Button

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (get_viewport().gui_get_focus_owner() == null and !disabled and visible):
		grab_focus()
