extends Node2D

class_name Status

@export var duration := 1.0

var disabled := false:
	set(value):
		if value != disabled:
			if value:
				on_disable()
			else:
				on_enable()
				
		disabled = value

var _timer := 0.0

func _physics_process(delta: float) -> void:
	if _timer == 0:
		begin()
		if not disabled:
			on_enable()
	
	_timer += delta
	
	if _timer >= duration:
		end()
		disabled = true
		queue_free()

# Called before first physics frame
func begin() -> void:
	pass
	
# Called after final physics frame
func end() -> void:
	pass

func on_disable() -> void:
	pass

func on_enable() -> void:
	pass
