extends CharacterBody2D

class_name Enemy

@export var enemy_stats:EnemyStats

@onready var health = $Health

# Get the gravity from the project settings to be synced with RigidBody nodes.
var _gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Used to disable gravity when needed
var floating : bool

func _ready():
	if health == null or enemy_stats == null: 
		return
	
	health.max_health = enemy_stats.health
	health.health = enemy_stats.health
	health.shields = enemy_stats.shields

func take_damage(amount:int, source, skip_shield = false, knockback_amount := 0.0, direction := Vector2.ZERO):
	if health == null: 
		return
		
	health.take_damage(amount, source, skip_shield, knockback_amount, direction, self)

func _physics_process(delta):
	# Do nothing if dead
	if health.health <= 0:
		return
	
	# Gravity
	if !is_on_floor() and !floating:
		velocity.y += _gravity * delta
		
	move_and_slide()
