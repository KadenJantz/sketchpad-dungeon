extends CharacterBody2D

const SPEED = 130.0
const CROUCH_SPEED = 90.0
const JUMP_HEIGHT = 133
const LENIANCY_TIME = .3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var health_bar : DynamicSlider
@export var platform_collision : CollisionObject2D

@onready var health = $Health
@onready var skeleton = get_node("PlayerRig")
@onready var anim = skeleton.get_node("AnimationPlayer")

# Get the gravity from the project settings to be synced with RigidBody nodes.
var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
# Used to disable gravity when needed
var floating : bool

var last_hit_color = null
var _disabled = false

var can_jump : bool
var can_jump_timer : float

var crouched : bool

func _ready():
	anim.play("Idle")

func _physics_process(delta):
	if _disabled:
		return
	
	# Add the gravity.
	if not is_on_floor() and not floating:
		velocity.y += gravity * delta

	# Jump and walk
	_handle_movement(delta)
			
	# Use item
	var use_is_pressed = false
	
	if Input.is_action_pressed("player_use") and $Inventory.holder.item_held:
		var mouse_dir = global_position.angle_to_point(get_global_mouse_position())
		
		# Face toweards direction
		if (abs(mouse_dir) > PI/2) == (scale.y > 0) and !$Inventory.holder.on_cooldown:
			scale.x *= -1
		
		$Inventory.holder.play_use_anim(mouse_dir)
		
		use_is_pressed = true
		
	else:
		# Try to get controller aim
		var stick = Input.get_vector("player_use_left", "player_use_right", "player_use_up", "player_use_down")
		
		if stick.length() > 0 and $Inventory.holder.item_held:
			# Face toweards direction
			if (abs(stick.angle()) > PI/2) == (scale.y > 0) and !$Inventory.holder.on_cooldown:
				scale.x *= -1
				
			$Inventory.holder.play_use_anim(stick.angle())
			
			use_is_pressed = true
			
	# If item is in use but isn't pressed, stop using item
	if !use_is_pressed and $Inventory.holder.using:
		$Inventory.holder.done_using.emit()
			
	# Interact with objects	
	if Input.is_action_just_pressed("player_interact"):
		var interactable = null
		 
		for body in $PickupArea.get_overlapping_bodies():
			if body is Interactable:
				if (!interactable or body.position.distance_to(position) < interactable.position.distance_to(position)):
					interactable = body 
				
		if interactable:
			interactable.interacted(self)
			
	# Inventory controls
	if Input.is_action_just_pressed("player_slot_1"):
		$Inventory.current_slot = 0
	if Input.is_action_just_pressed("player_slot_2"):
		$Inventory.current_slot = 1
	if Input.is_action_just_pressed("player_slot_3"):
		$Inventory.current_slot = 2
	if Input.is_action_just_pressed("player_slot_next"):
		var next = $Inventory.current_slot + 1
		
		if next <  $Inventory.max_slots:
			$Inventory.current_slot = next
		else:
			$Inventory.current_slot = 0
	if Input.is_action_just_pressed("player_slot_back"):
		var back = $Inventory.current_slot - 1
		
		if back >= 0:
			$Inventory.current_slot = back
		else:
			$Inventory.current_slot = $Inventory.max_slots - 1
	
func _handle_movement(delta):
	# Handle crouching
	if Input.is_action_pressed("player_crouch"):
		if is_on_floor() and velocity.y == 0:
			set_crouched(true)
		
	if Input.is_action_just_released("player_crouch"):
		set_crouched(false)
		
	# Handle Jump.
	if Input.is_action_just_pressed("player_jump") and can_jump:
		set_crouched(false)
		velocity.y = -sqrt(2 * _gravity * JUMP_HEIGHT)
		anim.play("Jump")
		
		$PlayerRig/AnimationPlayer.speed_scale = 1
		
		can_jump = false
		
	# Jumping is enabled upon touching the floor
	elif !can_jump and is_on_floor():
		can_jump = true
		can_jump_timer = LENIANCY_TIME
		
	# Jumping is disabled after a delay when in the air
	elif can_jump and !is_on_floor():
		if can_jump_timer <= 0:
			can_jump = false
		else:
			can_jump_timer -= delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("player_left", "player_right")
	
	if direction:
		#Move in direction
		if crouched:
			velocity.x = direction * CROUCH_SPEED
		else:
			velocity.x = direction * SPEED
		
		#Handle visual
		if sign(scale.y) != sign(direction) and not $Inventory.holder.using:
			# Turn visual around
			scale.x *= -1
		
		if is_on_floor() and velocity.y == 0:
			if crouched:
				anim.play("Crouch_Walk")
			else:
				anim.play("Walk")
			
			# Scale speed for controllers (or special WASD keys)
			$PlayerRig/AnimationPlayer.speed_scale = abs(direction)
			
			# Reverse if walking backwards
			if sign(scale.y) != sign(direction) and $Inventory.holder.using:
				$PlayerRig/AnimationPlayer.speed_scale *= -1
			
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor() and velocity.y == 0:
			if crouched:
				anim.play("Crouch_Idle")
			else:
				anim.play("Idle")
			$PlayerRig/AnimationPlayer.speed_scale = 1
			
	move_and_slide()

func take_damage(amount:int, source : Node, skip_shield = false, knockback_amount := 0.0, direction := Vector2.ZERO):
	var damage_color = null
	
	# Get color of damage if possible
	if Utility.path_get(source, "owner/material/shader") != null:
		damage_color = source.owner.material.get_shader_parameter("color")
		
		if damage_color != null:
			# Update last hit color
			if damage_color != last_hit_color:
				last_hit_color = damage_color
				
				health_bar.set_color(damage_color)
	
	if health == null: 
		return
		
	health.take_damage(amount, source, skip_shield, knockback_amount, direction, self)

func set_crouched(crouch:bool):
	if crouched == crouch:
		return
	
	crouched = crouch
	set_collision_mask_value(6, not crouch)
	
	if crouch:
		$Inventory.holder.apply_offset_over_time(Vector2.DOWN * 300, .1);
	else:
		$Inventory.holder.apply_offset_over_time(Vector2.UP * 300, .1);

func set_disabled(disabled:bool):
	_disabled = disabled

func return_to_menu(delay:float = 0.0):
	if delay > 0:
		await get_tree().create_timer(delay).timeout
		
	get_tree().change_scene_to_file("res://Scenes/Levels/main.tscn")
