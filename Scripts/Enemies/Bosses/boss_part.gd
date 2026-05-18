extends Node2D

class_name BossPart

@export var masks : Array[ColorMask]

@export var alive : bool = true:
	set = set_alive

@export var dead_scale : Vector2
@export var alive_scale := Vector2.ONE
@export var scale_speed := 1.0

func _ready() -> void:
	alive = alive

func _physics_process(delta: float) -> void:
	if alive and get_color_percent() > ColorOverlay.current.overlay_cutoff:
		alive = false
		
	# Scale to correct scale over time
	var correct_scale := alive_scale
	if not alive:
		correct_scale = dead_scale
		
	if scale != correct_scale:
		scale = scale.lerp(correct_scale, delta * scale_speed)

func set_alive(value : bool) -> void:
	alive = value

func get_color_percent() -> float:
	var total_mask_pixels := 0.0
	var total_color_pixels := 0.0
	
	for mask in masks:
		total_mask_pixels += mask.mask_pixel_count
		total_color_pixels += mask.pixel_count

	return total_color_pixels / total_mask_pixels
