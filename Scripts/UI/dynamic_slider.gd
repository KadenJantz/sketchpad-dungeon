extends Control

class_name DynamicSlider

signal value_decreased(amount:int)
signal value_increased(amount:int)
signal color_changed(color:Color)

@export var display : CanvasItem
@export var speed = 0.0
@export var color_speed = 0.0

@export var fill_pieces : Array[CanvasItem] = []
@export var size_per_piece = 2
@export var max_pieces = 1
@export var max_value = 6 : set = set_max
@export var min_max_value = 4;
@export var value = 6 : set = set_value_instant

# Info for prests created from fill_pieces
var textures : Array[Texture2D]
var types : Array[String]
var parents : Array[CanvasItem]

# Initial distances from the bottom of the fill pieces
var _initial_distances : Array[int]

# 2D Array (initialized in ready)
var _all_pieces : Array

# Keep track of display
var _displayed_percent = 1.0
var _displayed_color
var _goal_color

# Private value
@onready var _value = value

func set_max(max_val : int):	
	if (max_val <= min_max_value):
		max_pieces = 0
	
	# Otherwise, excess max value is converted to pieces
	else:
		max_pieces = ceil(float(max_val - min_max_value) / size_per_piece)
	
	# Apply value
	max_value = max_val ;
	
	# Refresh
	refresh_max()
	
func refresh_max():
	if _all_pieces.is_empty():
		return
	
	var need_to_add_more = false
	
	# Remove unneeded pieces
	for i in range(fill_pieces.size()):
		var current_pieces : int = _all_pieces[i].size()
		
		while current_pieces > max_pieces:
			var unneeded_piece = _all_pieces[i].pop_back()
			unneeded_piece.queue_free()
			
			current_pieces -= 1
			
		# Mark if more are needed
		if _all_pieces[i].size() < max_pieces:
			need_to_add_more = true
		
	# Add additional pieces if needed
	if need_to_add_more:
		# Double iteration causes them to appear in order if fill pieces have the same parent
		for piece_num in range(max_pieces):
			for i in range(fill_pieces.size()):
				if piece_num < _all_pieces[i].size():
					continue
				
				# Duplicate original
				var new_piece = ClassDB.instantiate(types[i])
				new_piece.texture = textures[i]
				
				# Add to the parent
				var parent = parents[i]
				parent.add_child(new_piece)
				parent.move_child(new_piece, parent.get_child_count() - _initial_distances[i])
				
				# Add to 2D list
				_all_pieces[i].append(new_piece)
				
	# Update value quickly so the shader will refresh
	set_value(_value, true)

# Setter for exported value
func set_value_instant(new_value : int):
	value = new_value
	
	set_value(new_value, true)

# Directly sets true value	
func set_value(new_value : int, instant = false):	
	# Send signals
	if _value != null and !instant:
		if new_value > _value:
			value_increased.emit(new_value - _value)
		elif new_value < _value:
			value_decreased.emit(_value - new_value)
		
	_value = new_value
	
	# Auto update display when there is 0 speed
	if display != null and (speed <= 0 or instant):
		_update_display(new_value)
	
func set_color(color : Color, instant = false):
	_goal_color = color
	
	if instant or color_speed <= 0:
		_update_color(color)
	
	color_changed.emit(color)
	
func _update_color(goal_color : Color, delta = 1):
	# Avoid uneeded updates
	if goal_color.is_equal_approx(_displayed_color):
		return
	
	# If not instant, apply color speed
	if delta < 1 and color_speed > 0:
		delta *= color_speed
		
	delta = clamp(delta, 0, 1)
	_displayed_color = lerp(_displayed_color, goal_color, delta)
	
	_displayed_color.a = display.material.get_shader_parameter("color_1").a
	display.material.set_shader_parameter("color_1", _displayed_color)

	_displayed_color.a = display.material.get_shader_parameter("color_2").a
	display.material.set_shader_parameter("color_2", _displayed_color)
	
func _update_display(goal_value : float, delta = 1):
	var goal_percent := float(goal_value)/float(max_value)
	
	# Avoid uneeded updates
	if abs(goal_percent - _displayed_percent) < .01:
		return
		
	# If not instant, apply speed
	if delta < 1 and speed > 0:
		delta *= speed
	
	var percent : float = clamp(lerp(_displayed_percent, goal_percent, delta), 0, 1)
	
	display.material.set_shader_parameter("progress", percent)
	
	_displayed_percent = percent

func _ready() -> void:	
	for piece in fill_pieces:
		# Move fill pieces into all pieces 2d array
		var array = [piece]
		_all_pieces.append(array)
		
		# Also, record its current position as a child
		_initial_distances.append(piece.get_parent().get_child_count() - piece.get_index())
		
		# Record other preset info as well
		textures.append(piece.texture)
		types.append(piece.get_class())
		parents.append(piece.get_parent())

	set_max(max_value)
	
	if display != null:
		# Randomize Color
		_goal_color = ColorRandomizer.random_color()
		_displayed_color = Color.WHITE
		
		set_color(_goal_color, true)

func _process(delta: float) -> void:
	# Move slowly towards next part
	if display != null and speed > 0:
		_update_display(_value, delta)
		
	
	# Adjust color slowly
	if display != null and _goal_color != null and color_speed > 0:
		_update_color(_goal_color, delta)
