extends SpellField

@export var start_delay : float
# Damages only once if 0
@export var tick_time : float
@export var damage : int

# To be passed to damageable objects
@export var skip_shield : bool
@export var source : Node = self

# Persistant list of times in ms objects were last damaged. Only resets on refresh
var last_damage : Dictionary[Node2D, float]

func refresh() -> void:
	# Damages reset
	last_damage.clear()
	
	super()
	
func _physics_process(delta: float) -> void:
	super(delta)
	
	if is_queued_for_deletion():
		return
		
	# Source must always be set
	if source == null:
		source = self
	
	for obj in objects:
		if Time.get_ticks_msec() - objects[obj] < start_delay * 1000.0:
			continue
			
		# Attempt damage
		try_damage(obj, damage)

func try_damage(target : Node2D, dmg : int):
	# Object must be damageable
	if target == null || not target.has_method("take_damage"):
		remove_object(target)
		return
		
	# Wait for tick time
	if target in last_damage and (tick_time <= 0 or Time.get_ticks_msec() - last_damage[target] < tick_time * 1000.0):
		return
	
	last_damage[target] = Time.get_ticks_msec()
	
	if target.has_method("take_damage"):
		target.take_damage(dmg, source, skip_shield)
