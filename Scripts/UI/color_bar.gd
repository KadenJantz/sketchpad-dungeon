extends HBoxContainer

class_name ColorBar

var percent_opaque := 0.0
var total_pixels := 0

func _enter_tree() -> void:
	ColorOverlay.current.color_bar = self
	
func _exit_tree() -> void:
	if ColorOverlay.current.color_bar == self:
		ColorOverlay.current.color_bar = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if ColorOverlay.current.counts_updated:
		ColorOverlay.current.counts_updated = false
		
		# Start by recalculating percentage
		recalc_percent()
		# Apply calculation to display
		refresh_display()
		
func recalc_percent() -> void:
	var max_pixels = ColorOverlay.current.get_max_pixel_count()
	percent_opaque = 0.0
	total_pixels = 0
	
	for i in ColorOverlay.current.get_images().size():
		var overlay_opaque = ColorOverlay.current.get_image_pixel_count(i)
		var overlay_pixels = ColorOverlay.current.get_image_max_pixel_count(i)
		
		# Not drawn on yet, skip
		if overlay_opaque <= 0:
			continue
		
		# Add to total
		total_pixels += overlay_opaque
		
		# Calc percent of pixels opaque
		var percentage = float(overlay_opaque)/float(overlay_pixels)
		
		# Apply cutoff
		if percentage > ColorOverlay.current.overlay_cutoff:
			percentage = ColorOverlay.current.overlay_cutoff + (percentage - ColorOverlay.current.overlay_cutoff) * ColorOverlay.current.cutoff_modifier
			
		# Add to completion percent out of all overlay's pixels
		percent_opaque += percentage * overlay_pixels / max_pixels
		
	
	# Adjust for requirement
	percent_opaque /= ColorOverlay.current.required_percentage
	if percent_opaque > 1:
		percent_opaque = 1
	
func refresh_display() -> void:
	for color : Color in ColorOverlay.current.get_all_colors():
		var color_count = ColorOverlay.current.get_color_count(color)
		
		var node_name = str(color.to_rgba32())
		
		# Just ensure no rect is present for zeros
		if color_count <= 0:
			if has_node(node_name):
				get_node(node_name).queue_free()
				
			continue
		
		var rect : ColorRect
		
		if has_node(node_name):
			rect = get_node(node_name)
			
		else:
			rect = ColorRect.new()
			add_child(rect)
			rect.name = node_name
			color.a = .8
			rect.color = color
			
		rect.custom_minimum_size.x = float(color_count)/float(total_pixels) * percent_opaque*size.x
