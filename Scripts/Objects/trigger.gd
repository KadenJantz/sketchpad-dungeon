extends Area2D

signal triggered

# How many ticks to wait between each check
@export var disabled = false;
# How many ticks to wait between each check
@export var frequency = 1
# How many seconds to wait after a detection before detecting
@export var delay = 0.0
# How many seconds to wait after a detection before triggering
@export var trigger_wait_time = 0

var delay_timer = 0

var tick = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if disabled:
		return
	
	# A tick has passed
	tick += 1
	
	# Check if tick count matches
	if tick % frequency != 0:
		return
		
	# Advance timer if it is active
	if delay_timer > 0:
		delay_timer -= delta
		
		# Check if still not 0
		if delay_timer > 0:
			return
		
	var areas := self.get_overlapping_areas()
	
	if areas.size() > 0:
		delay_timer = delay

		# Wait before triggering if needed
		if trigger_wait_time > 0:
			await get_tree().create_timer(trigger_wait_time).timeout
			
		triggered.emit()

func set_disabled(disable:bool):
	disabled = disable
