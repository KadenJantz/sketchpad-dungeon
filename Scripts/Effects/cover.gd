extends Sprite2D

@export var enabled = false
@export var time = 1.0
@export var end_difference = 4

var _timer = 0

# Called when the node enters the scene tree for the first time.
func begin(from_direction : Vector2, speed : float = 1.0) -> void:
	if speed == 0:
		queue_free()
		return
	
	texture.fill_from = from_direction
	texture.fill_to = from_direction
	texture.fill_to.x += .001
	
	if from_direction == Vector2.ZERO:
		texture.fill_to += .001
		
	time /= speed
	
	enabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if enabled:
		texture.fill_to.x = lerp(texture.fill_to.x, texture.fill_to.x + end_difference, delta/time)
		
		_timer += delta
		
		if _timer >= time:
			queue_free()
		
func round_furthest(input : float):
	if input < 0.5:
		return 1
	else:
		return 0
