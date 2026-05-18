extends Node2D

@export var stats : BossStats

@export var reusable_states : Array[BossState]
@export var limited_states : Dictionary[BossState, int]
@export var parts : Array[BossPart]

var current_state : BossState
var target : Node2D
var disabled : bool

var states_used : int

var _delay : float

var _rng = RandomNumberGenerator.new()

func _ready() -> void:
	_delay = stats.initial_delay
	target = get_tree().get_nodes_in_group("player")[0]

func _physics_process(delta: float) -> void:
	if disabled:
		return
	
	# Check if dead
	if ColorOverlay.current.color_bar.percent_opaque >= 1:
		set_alive(false)
	if not is_alive():
		print("boss dead")
		disabled = true
		return
	
	# Tick
	_delay -= delta
	
	# Wait for delay
	if _delay <= 0:
		# Try to start new state
		start_new_state()

### STATE MANAGEMENT ###

func start_new_state():
	var failed_states : Array[int]
	
	var total =  limited_states.size() + reusable_states.size()
	
	# Go through random states
	while failed_states.size() < total:
		var r := _rng.randi_range(0, total - 1)
		
		# No repeats!
		if r in failed_states:
			continue
			
		# Get state from lists
		var state : BossState
		
		if r < limited_states.size():
			state = limited_states.keys()[r]
		else:
			state = reusable_states[r - limited_states.size()]
			
		if state.Evaluate(self):
			switch_state(state)
			break
		else:
			failed_states.append(r)
			
	# Blank state
	if failed_states.size() >= total:
		switch_state(null)
	
func switch_state(new_state : BossState):
	# Countdown if limited state
	if new_state in limited_states.keys():
		limited_states[new_state] -= 1;
		if limited_states[new_state] <= 0:
			limited_states.erase(new_state)
			
	if current_state != null:
		current_state.Exit(self)
	if new_state != null:
		new_state.Enter(self)
	current_state = new_state
	
	states_used += 1
	if new_state != null:
		_delay = new_state.duration;
	
### GETTERS/SETTERS ###
func is_alive() -> bool:
	# Alive if any parts are alive
	for part in parts:
		if part.alive:
			return true
	
	# Dead if all parts are not alive
	return false

func set_alive(value : bool) -> void:
	for part in parts:
		part.alive = value
