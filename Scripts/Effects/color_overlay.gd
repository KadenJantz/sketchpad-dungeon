extends Node2D

class_name ColorOverlay

static var current : ColorOverlay

@export var required_percentage := .25
@export var overlay_cutoff := .25
@export var cutoff_modifier := .3

@export var overlay_pixels = Vector2(256, 256)
@export var overlay_grid = Vector2i(5, 2)

@onready var pixel_width = overlay_pixels.x * overlay_grid.x
@onready var pixel_height = overlay_pixels.y * overlay_grid.y

@export var count_masks_only : bool

# Color bars assign themselves
var color_bar : ColorBar

var overlays: Array[Sprite2D]
var masks: Array[ColorMask]
var image_queue: Array

var pixel_counts: Array[int]
var color_counts: Dictionary
var counts_updated := false

func _init() -> void:
	current = self

func _ready():	
	# Set up array
	overlays.resize(overlay_grid.x * overlay_grid.y)
	
	for i in range(len(overlays)):
		# Base image on initial child
		var new_image
		if i == 0:
			new_image = get_child(0)
		else:
			new_image = get_child(0).duplicate()
			add_child(new_image)
		
		# Get x and y in grid
		var x = floori(i/overlay_grid.y)
		var y = i % overlay_grid.y
		
		# Calculate position based on grid position
		new_image.position.x = (x * overlay_pixels.x) - (pixel_width - overlay_pixels.x)/2.0
		new_image.position.y = (y * overlay_pixels.y) - (pixel_height - overlay_pixels.y)/2.0
	
		var dynImage = Image.create(overlay_pixels.x, overlay_pixels.y,false,Image.FORMAT_RGBA8)
		dynImage.fill(Color.WHITE)
		
		new_image.texture = ImageTexture.create_from_image(dynImage)
		
		overlays[i] = new_image
		pixel_counts.insert(i, 0)
		
func _process(_delta: float) -> void:
	# Past here is only image loading stuff
	if image_queue.is_empty():
		return
		
	# Apply images to repective sprites
	var imageNum := 1
	while imageNum < len(image_queue):
		overlays[image_queue[imageNum-1]].texture = ImageTexture.create_from_image(image_queue[imageNum])
		
		imageNum += 2
		
	image_queue.clear()
	
func get_images() -> Array:
	if count_masks_only:
		return masks
	else:
		return overlays
		
func get_image_pixel_count(i : int):
	if count_masks_only:
		return masks[i].pixel_count
	else:
		return pixel_counts[i]
		
func get_image_max_pixel_count(i : int):
	if count_masks_only:
		return masks[i].mask_pixel_count
	else:
		return overlay_pixels.x * overlay_pixels.y
		
func get_max_pixel_count():
	if count_masks_only:
		var total_count : int = 0
		for mask in masks:
			total_count += mask.mask_pixel_count
		return total_count
	else:
		return pixel_counts.size() * overlay_pixels.x * overlay_pixels.y
	
func set_circle(pixel_pos:Vector2, radius:float, color:Color, consistency = 1.0):
	var dyn_images = image_queue
	
	var x = radius
	var y = 0
	 
	# Printing the initial point the 
	# axes after translation 
	_set_pixel(dyn_images, x + pixel_pos.x, -y + pixel_pos.y, color, consistency)
	 
	# When radius is zero only a single 
	# point be printed 
	if (radius > 0) :
		_set_pixel(dyn_images, x + pixel_pos.x, -y + pixel_pos.y, color, consistency)
		_set_pixel(dyn_images, y + pixel_pos.x, x + pixel_pos.y, color, consistency)
		_set_pixel(dyn_images, -y + pixel_pos.x, x + pixel_pos.y, color, consistency)
	 
	# Initialising the value of P 
	var P = 1 - radius
 
	while x > y:
	 
		y += 1
		 
		# Mid-point inside or on the perimeter
		if P <= 0: 
			P = P + 2 * y + 1
			 
		# Mid-point outside the perimeter 
		else:         
			x -= 1
			P = P + 2 * y - x + 1
		 
		# All the perimeter points have 
		# already been printed 
		if (x < y):
			break
		 
		# Printing the generated point its reflection 
		# in the other octants after translation 
		_set_pixel(dyn_images, x + pixel_pos.x, y + pixel_pos.y, color)
		_set_pixel(dyn_images, -x + pixel_pos.x, y + pixel_pos.y, color)
		_set_pixel(dyn_images, x + pixel_pos.x, -y + pixel_pos.y, color)
		_set_pixel(dyn_images, -x + pixel_pos.x, -y + pixel_pos.y, color)
		
		for x_mid in range(x - 1):
			_set_pixel(dyn_images, x_mid + pixel_pos.x, y + pixel_pos.y, color)
			_set_pixel(dyn_images, -x_mid + pixel_pos.x, y + pixel_pos.y, color)
			_set_pixel(dyn_images, x_mid + pixel_pos.x, -y + pixel_pos.y, color)
			_set_pixel(dyn_images, -x_mid + pixel_pos.x, -y + pixel_pos.y, color)
			
			if x_mid > y:
				_set_pixel(dyn_images, y + pixel_pos.x, x_mid + pixel_pos.y, color)
				_set_pixel(dyn_images, -y + pixel_pos.x, x_mid + pixel_pos.y, color)
				_set_pixel(dyn_images, y + pixel_pos.x, -x_mid + pixel_pos.y, color)
				_set_pixel(dyn_images, -y + pixel_pos.x, -x_mid + pixel_pos.y, color)
		 
		# If the generated point on the line x = y then 
		# the perimeter points have already been printed 
		if x != y:
			_set_pixel(dyn_images, y + pixel_pos.x, x + pixel_pos.y, color)
			_set_pixel(dyn_images, -y + pixel_pos.x, x + pixel_pos.y, color)
			_set_pixel(dyn_images, y + pixel_pos.x, -x + pixel_pos.y, color)
			_set_pixel(dyn_images, -y + pixel_pos.x, -x + pixel_pos.y, color)
	
	image_queue = dyn_images

func _try_set_pixel_on_masks(pixel_pos:Vector2, color:Color) -> bool:
	for mask in masks:
		if mask == null:
			continue
			
		if mask.try_set_pixelv(pixel_pos, color):
			return true
			
	return false

func set_pixelv(pixel_pos:Vector2, color:Color) -> bool:
	var dyn_images = image_queue
	
	_set_pixelv(dyn_images, pixel_pos, color)
	
	image_queue = dyn_images
	
	return true
	
func _set_pixelv(dyn_images:Array, pixel_pos:Vector2, color:Color, chance := 1.0):
	# Return if generation fails
	if (chance != 1.0 and randf() >= chance):
		return
		
	# Try adding pixel to a mask first
	if _try_set_pixel_on_masks(pixel_pos, color):
		return
		
	# Get pixel from position
	var pixel = _get_pixelv(pixel_pos)
	
	# Check that pixel exists
	if (pixel.x / overlay_pixels.x >= overlay_grid.x or pixel.y / overlay_pixels.y >= overlay_grid.y or pixel.x < 0 or pixel.y < 0):
		return false
	
	var overlay_num = _pixel_to_overlayv(pixel)
	
	var dyn_image : Image
	
	# Get from list if avaliable
	var i := 0
	while i + 1 < len(dyn_images):
		if dyn_images[i] == overlay_num:
			# This is the right image
			dyn_image = dyn_images[i+1]
			break
			
		i += 2
		
	# Add to list to change if not already added
	if !dyn_image:
		dyn_images.append(overlay_num)
		
		dyn_image = overlays[overlay_num].texture.get_image()
		dyn_images.append(dyn_image)
		
	# Make pixels reasonable
	var pixel_x = int(pixel.x) % int(overlay_pixels.x)
	var pixel_y = int(pixel.y) % int(overlay_pixels.y)
	
	# No reason to replace a color with itself
	var old_color := dyn_image.get_pixel(pixel_x, pixel_y)
	if old_color == color:
		return
	
	# Take a moment to update color info for this image if it is the main one
	if !count_masks_only:
		_alter_color_counts(overlay_num, old_color, color)
	
	# Apply pixel
	dyn_image.set_pixel(pixel_x, pixel_y, color)
	
func _set_pixel(dyn_images:Array, x, y, color:Color, chance := 1.0):
	var pixel_pos = Vector2(x, y)
	_set_pixelv(dyn_images, pixel_pos, color, chance)
	
func _get_pixelv(pixel_pos:Vector2) -> Vector2:
	pixel_pos -= position
	return round(pixel_pos/scale + Vector2(pixel_width, pixel_height)/2.0)
	
func _get_pixel(x, y) -> Vector2:
	var pixel_pos = Vector2(x, y)
	return _get_pixelv(pixel_pos)
	
func _pixel_to_overlayv(pixel_pos:Vector2i) -> int:
	return _pixel_to_overlay(pixel_pos.x, pixel_pos.y)
	
func _pixel_to_overlay(pixel_x:int, pixel_y:int) -> int:
	var grid_x = floori(pixel_x/overlay_pixels.x)
	var grid_y = floori(pixel_y/overlay_pixels.y)
	return _grid_to_overlay(grid_x, grid_y)
	
func _grid_to_overlay(grid_x:int, grid_y:int) -> int:
	return grid_x * overlay_grid.y + grid_y

#-- Color Counting Methods --#
func get_all_colors() -> Array:
	if count_masks_only:
		var color_keys : Array[Color]
		
		for mask in masks:
			for color_key in mask.color_counts.keys():
				if not color_key in color_keys:
					color_keys.append(color_key)
					
		return color_keys;
	
	else:
		return color_counts.keys()
		
func get_color_count(color : Color) -> int:
	if count_masks_only:
		var color_count : int = 0
		
		for mask in masks:
			if color in mask.color_counts.keys():
				color_count += mask.color_counts[color]
				
		return color_count
		
	else:
		return color_counts[color]

func _alter_color_counts(overlay_num : int, old_color : Color, new_color : Color):
	# Add to pixel counter if drawing on blank space
	if old_color == Color.WHITE and new_color != Color.WHITE:
		pixel_counts[overlay_num] += 1
		
	# Decrease pixel counter if erased
	elif old_color != Color.WHITE and new_color == Color.WHITE:
		# Pixel was erased
		pixel_counts[overlay_num] -= 1
		
	# Decrease color count of old color
	if old_color != Color.WHITE:
		color_counts[old_color] = color_counts.get(old_color, 0) - 1 
		
		counts_updated = true

	# Increase color count of new color
	if new_color != Color.WHITE:
		color_counts[new_color] = color_counts.get(new_color, 0) + 1
		
		counts_updated = true
