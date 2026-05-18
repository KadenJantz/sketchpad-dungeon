extends Sprite2D

class_name ColorMask

@export var mask: Texture2D
@export var resolution_scale := 1.0

var pixel_count : int
var mask_pixel_count : int
var color_counts : Dictionary

var mask_image: Image
var dyn_image: Image
var updated : bool

func _ready() -> void:
	# Register mask
	ColorOverlay.current.masks.append(self)
	
	# Apply mask to sprite
	dyn_image = Image.create(int(mask.get_width() * resolution_scale), int(mask.get_height() * resolution_scale),false,Image.FORMAT_RGBA8)
	dyn_image.fill(Color.WHITE)
	texture = ImageTexture.create_from_image(dyn_image)
	
	# Get mask image from mask
	mask_image = mask.get_image()
	for x in texture.get_size().x:
		for y in texture.get_size().y:
			if mask_image.get_pixel(round(x/resolution_scale), round(y/resolution_scale)).a > 0:
				mask_pixel_count += 1
	
func _process(_delta: float) -> void:
	# Update texture with dyn_image if it has changed
	if dyn_image != null and updated:
		texture = ImageTexture.create_from_image(dyn_image)
		updated = false
	
func is_pixel_in_mask(pixel_pos : Vector2) -> bool:
	# Pixel must be within image
	if pixel_pos.x < 0 or pixel_pos.y < 0 or pixel_pos.x >= texture.get_width() or pixel_pos.y >= texture.get_height():
		return false
	
	if mask_image.get_pixelv(pixel_pos/resolution_scale).a < 0.5:
		return false
	
	return true

func get_pixel_pos(pos : Vector2) -> Vector2:
	var local_pos = to_local(pos)
	
	return round((local_pos + Vector2(texture.get_width(), texture.get_height())/2.0))
	
func try_set_pixel(pos : Vector2, color : Color) -> bool:
	return try_set_pixel(pos, color)
	
func try_set_pixelv(pos : Vector2, color : Color) -> bool:
	var pixel_pos = get_pixel_pos(pos)
	
	if is_pixel_in_mask(pixel_pos):
		set_pixelv(pixel_pos, color)
		return true
		
	else:
		return false
		
	
func set_pixel(x : float, y : float, color : Color) -> void:
	set_pixelv(Vector2(x, y), color)
	
func set_pixelv(pixel_pos : Vector2, color : Color) -> void:
	var old_color := dyn_image.get_pixelv(pixel_pos)
	
	# No reason to replace a color with itself
	if color == old_color:
		return
		
	# Apply pixel
	dyn_image.set_pixelv(pixel_pos, color)
	
	# Update color counts if they will be used
	if ColorOverlay.current.count_masks_only:
		_alter_color_counts(old_color, color)
	
	# Make sure update is scheduled
	updated = true

#-- Color Counting Methods --#
func _alter_color_counts(old_color : Color, new_color : Color):
	# Add to pixel counter if drawing on blank space
	if old_color == Color.WHITE and new_color != Color.WHITE:
		pixel_count += 1
		
	# Decrease pixel counter if erased
	elif old_color != Color.WHITE and new_color == Color.WHITE:
		# Pixel was erased
		pixel_count -= 1
		
	# Decrease color count of old color
	if old_color != Color.WHITE:
		color_counts[old_color] = color_counts.get(old_color, 0) - 1 
		
		ColorOverlay.current.counts_updated = true

	# Increase color count of new color
	if new_color != Color.WHITE:
		color_counts[new_color] = color_counts.get(new_color, 0) + 1
		
		ColorOverlay.current.counts_updated = true
