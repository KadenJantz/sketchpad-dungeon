extends CanvasItem

class_name ColorRandomizer

@export var other_objects : Array[CanvasItem]

static var colors = [Color.CORNFLOWER_BLUE, Color.MEDIUM_PURPLE, Color.CRIMSON, Color.DARK_ORANGE, Color.YELLOW, Color.LIME_GREEN]

static func random_color() -> Color:
	var ran_num = randi() % len(colors)
	
	return colors[ran_num]

var applied_color : Color

func _ready():
	# Grab a color
	applied_color = ColorRandomizer.random_color()
	
	# Apply to parent
	var parent = get_parent()
	
	if parent is CanvasItem:
		parent.material.set_shader_parameter("color", applied_color)
		
	# Apply to any other objects
	for object in other_objects:
		object.material.set_shader_parameter("color", applied_color)
