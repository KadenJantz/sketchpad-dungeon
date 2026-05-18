extends Node2D

class_name DamageableObject

signal max_health_changed(max:int)
signal health_changed(health:int)
signal damaged(direction:Vector2, attacker, receptient)
signal knocked_back(direction:Vector2, attacker, receptient)
signal shield_changed(shields:int)
signal shield_lost(direction:Vector2, attacker, receptient)
signal died

@export var stats : Resource

@export var max_health = 5 : set = set_max_health

@export var shields = 0 : set = set_shield

@export var delay = 1.0

@export var moveable := true

var health : set = set_health

var alive := true

func _ready():
	if stats:
		# Load stats
		if "shields" in stats:
			shields = stats.shields
			
		if "health" in stats:
			max_health = stats.health
			health = stats.health
			
	# Refresh stats once ui is loaded
	await owner.ready
	
	max_health = max_health
	shields = shields
	health = max_health
	
	# Ensure actually movable
	if moveable and not get_parent() is CharacterBody2D:
		moveable = false
		
func set_shield(value:int):
	shield_changed.emit(value)
	
	shields = value
		
func set_health(value:int):
	# Clamp health from 0 to max health
	value = min(max(value, 0), max_health)
	health = value
	health_changed.emit(value)
		
func set_max_health(value:int):
	max_health_changed.emit(value)
	
	max_health = value

func take_damage(amount:int, source:Object, skip_shield := false, knockback_amount := 0.0, direction := Vector2.ZERO, body = self):
	# Can't take damage if already dead
	if health <= 0:
		return
	
	# Find direction of hit if applicable
	if direction == Vector2.ZERO:
		# Situation one: it is specified in the original source
		if "last_hit_pos" in source:
			if source is Node:
				direction = source.last_hit_pos - source.global_position
			else:
				direction = owner.global_position - source.last_hit_pos
			
		# Situation two: the parent of the attacking object is the attacker
		elif source is Node:
			direction = body.global_position - source.global_position
			
	# Apply any requested knockback if possible
	if moveable and knockback_amount > 0 and direction != Vector2.ZERO:
		#TODO: Either fix velocity reset or switch to move_and_collide
		get_parent().velocity += direction * knockback_amount
		knocked_back.emit(direction, source, self)
	
	# Shield can absorb a hit
	if !skip_shield and shields > 0:
		shields -= 1
		
		# Send out signal
		shield_lost.emit(direction, source, self)
		
		return
		
	health -= amount
	
	# Send out signal
	damaged.emit(direction, source, self)
	
	if health <= 0:
		# Dead!
		_die()

func _die():
	died.emit()
	alive = false
	
	# Negative delay means infinity
	if delay < 0:
		return
	
	await get_tree().create_timer(delay).timeout
	
	owner.queue_free()
