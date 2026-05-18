extends Node

@export var to_disable : Node2D

@export var instant = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if instant and can_process():
		disable()
		
func disable():
	set_enabled(false)

func set_enabled(enabled : bool):
	to_disable.visible = false
	
	if enabled:
		to_disable.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		to_disable.process_mode = Node.PROCESS_MODE_DISABLED
