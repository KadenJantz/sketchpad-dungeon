extends CanvasItem

@export var buttons:Array[Button]

func on_toggle():
	visible = !visible
	
	for button in buttons:
		button.disabled = !button.disabled
		
		if button.focus_mode == Control.FOCUS_NONE:
			button.focus_mode = Control.FOCUS_ALL
		else:
			button.focus_mode = Control.FOCUS_NONE
