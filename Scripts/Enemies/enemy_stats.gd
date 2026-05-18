extends Resource

class_name EnemyStats

@export_file("*.tscn") var scene : String
@export var tags : Array[String]
@export var cost : int = 1

@export_group("Movement")
@export var move_speed = 0
@export var reaction_time = .5

@export_group("Profile")
@export var name:String
@export var description:String

@export_group("Health")
@export var health = 3
@export var shields = 0

@export_group("Attack")
@export var damage = 1
@export var attack_duration = 0.5
@export var attack_delay = 0.5
@export var attack_cooldown = 1.0
@warning_ignore("shadowed_global_identifier")
@export var range = 1.0
@export var knockback = 0.0
@export var stun = 0.0
