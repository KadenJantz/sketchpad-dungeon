extends BoxContainer


@export var stats:Resource

@export var image_slot:TextureRect

@export var skip_lines:Array[int]

@export var min_lines:int = 10

@export var example_label:Node

var _label_type

# Called when the node enters the scene tree for the first time.
func _ready():
	_label_type = example_label.get_class()
	
	if stats != null:
		apply_resource(stats)


func apply_from_path(folder:String, res_name:String):
	
	res_name = res_name.to_lower().replace(" ", "_")
	
	var path = "res://Stats/" + folder + "/" + res_name + ".tres"
	
	apply_resource(load(path))
	
	
func apply_from_folder(folder:String):
	var contents = _list_files_in_directory("res://Stats/" + folder)
	
	#Avoid errors
	if not contents:
		return
		
	var name_array = []
	
	var image_array = []
		
	for file in contents:
		var res = load("res://Stats/" + folder + "/" + file)
		
		if not res is Resource:
			continue
			
		name_array.append(res.name)
		
		if res.image:
			image_array.append(res.image)
			
	if len(image_array) > 0:
		display_lines(name_array, image_array)
	else:
		display_lines(name_array)
	

func apply_resource(new_stats:Resource):
	# Apply new stats
	stats = new_stats
	
	# Apply image
	if image_slot != null:
		image_slot.texture = stats.image
	
	# Get lines from stats
	var stat_array = stats.to_array()
	
	display_lines(stat_array)
	
	
func display_lines(line_array, image_array = null):
	# Count up current lines
	var lines_required = len(line_array)
	
	for line in skip_lines:
		if line < lines_required:
			lines_required += 1
	
	# If not enough lines, add lines
	while get_child_count() < lines_required:
		var new_line = get_child(get_child_count()-1).duplicate()
		
		add_child(new_line)
		
	# If below the min lines remove lines until at minimum
	while get_child_count() > lines_required and get_child_count() > min_lines:
		var child = get_child(get_child_count()-1)
		remove_child(child)
		child.queue_free()
	
	# Apply lines
	var line_num = 0
	
	for line in len(line_array):
		# Ignore some lines
		while skip_lines.has(line_num):
			line_num += 1
		
		var label = _find_child_type(get_child(line_num), _label_type)
		# Set line text to label
		label.text = line_array[line]
		
		#Other button changes
		if label is Button:
			_configure_button(label, line_array[line])
		
		# Add image if avaliable
		if image_array and len(image_array) > line:
			label.icon = image_array[line]
		
		# Next line
		line_num += 1
		
	# Clean up any remaining lines
	while line_num < get_child_count():
		# Ignore some lines
		while skip_lines.has(line_num):
			line_num += 1
			
		# If still below after skipping, clear line
		if line_num < get_child_count():
			var label = _find_child_type(get_child(line_num), _label_type)
			label.text = ''
			
			#Other button changes
			if label is Button:
				_configure_button(label, null)
				
			# Next line
			line_num += 1

func _configure_button(button, text):
	if (text == null):
		# Disable Button
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
		
	else:
		#Set up button
		button.name = text
		button.reconnect()
		
		# Re-enable button
		button.disabled = false
		button.focus_mode = Control.FOCUS_ALL


func _list_files_in_directory(path):
	var files = []
	var dir = DirAccess.open(path)
	
	if not dir:
		print("Error: " + path + " does not exist!")
		return
	
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files


func _find_child_type(parent, type):
	# Iterate through children
	for i in parent.get_child_count():
		var child = parent.get_child(i)
		
		# Return first child that matches
		if child.get_class() == type:
			return child
