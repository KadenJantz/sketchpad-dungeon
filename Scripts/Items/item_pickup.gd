extends Interactable

@export var item:ItemStats
@export var count:int = 1

@onready var default_tex_y = $TextureRect.position.y
@onready var bounce_target = $TextureRect.position.y + BOUNCE_DIST

const BOUNCE_DIST = 5

func _ready():
	# Set up texture
	$TextureRect.texture = item.image
	$TextureRect.position.y = randf_range(default_tex_y, bounce_target)
	
	# Make item a copy
	if item:
		item = item.clone()
		
		# Set up weapon
		if item is WeaponStats and !item.color:
			item.random_color()
			
		# Set paint color
		if item.color:
			# Change item
			self.get_node("TextureRect").material.set_shader_parameter("color", item.color)
			
func _process(delta):
	$TextureRect.position.y = lerp($TextureRect.position.y, bounce_target, delta)
	
	if abs($TextureRect.position.y - bounce_target) < float(BOUNCE_DIST)/2:
		if bounce_target < default_tex_y:
			bounce_target += BOUNCE_DIST * 2
		else:
			bounce_target -= BOUNCE_DIST * 2

func interacted(_interactor):
	var inventory = _interactor.get_node("Inventory")
	
	if (inventory):
		inventory.add_item(item, count)
		
	queue_free()
