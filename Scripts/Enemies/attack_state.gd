extends State

@export var stats : EnemyStats
@export var attack_friction = .1
@export var paint_effect : PackedScene
signal begin
signal start_attack 
signal end_attack
signal reset

var _attacking = false
var _attacked_already = false
var _is_reset = true

var timer = 0

# Info for hit
var last_hit_pos : Vector2

@onready var _hit : Node2D = $Hit

func _supports(_node):
	return true
	
func _physics_process(delta):
	if timer <= 0:
		if !_is_reset:
			reset.emit()
			_is_reset = true
		
	else:
		timer -= delta
	
	if disabled:
		return
		
	# Detects new enabled so the signal can be sent out
	if _is_reset:
		begin.emit()
		timer = stats.attack_cooldown + stats.attack_duration + stats.attack_delay
		_is_reset = false
		
	# Start attacking if enabled
	if !_attacking and timer <= stats.attack_cooldown + stats.attack_duration:
		# Should be attacking during attack duration
		if timer > stats.attack_cooldown:
			set_attacking(true)
			
	# Check if attack time is done
	if timer <= stats.attack_cooldown:
		set_attacking(false)
		
	# Trigger attack if applicable
	if _attacking and _hit.is_colliding():
		_attack()

func set_attacking(attacking:bool):
	if attacking:
		_attacked_already = false
		
		# Nothing has been hit yet, so no exemptions
		_hit.clear_exceptions()
		
		# Damaging enabled
		start_attack.emit()
		
	else:
		# Damaging disabled
		end_attack.emit()
	
	# Update state accordingly
	_attacking = attacking

# Should not be necessary but fixes issue
func set_disabled(disable:bool):
	
	super.set_disabled(disable)
	
func _attack():
	# Only attack once
	if _attacked_already:
		return
	
	var body : Object
	
	# Get hit from shapecast
	if _hit is ShapeCast2D:
		body = _hit.get_collider(0)
		
		# Record hit pos
		last_hit_pos = _hit.get_collision_point(0)
			
	# or get hit from raycast
	elif _hit is RayCast2D:
		body = _hit.get_collider()
		
		# Record hit pos
		last_hit_pos = _hit.get_collision_point()
	
	# Call attack
	if body and body.has_method("take_damage"):
		body.call("take_damage", stats.damage, self)
		
	elif body and body.owner.has_method("take_damage"):
		body.owner.call("take_damage", stats.damage, self)

	# Disable attack state but don't stop attacking yet
	_attacked_already = true
