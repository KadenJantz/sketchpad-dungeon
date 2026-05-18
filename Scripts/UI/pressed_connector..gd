extends Button

@export var target:Node
@export var folder:Label

var current_callable:Callable

# Called when the node enters the scene tree for the first time.
func _ready():
	_connect()
	
func _connect():
	var callable = Callable(target, "apply_from_path")
	
	callable = callable.bindv([folder.text, text])
	
	#Connect signal using text
	pressed.connect(callable)
	
	current_callable = callable
	
func reconnect():
	pressed.disconnect(current_callable)
	_connect()
