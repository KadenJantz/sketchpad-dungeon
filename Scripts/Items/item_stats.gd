extends Resource

class_name ItemStats

@export_group("Profile")
@export var name:String
@export var description:String
@export var image:Texture2D = null

@export_group("Attack")
@export var damage:float
@export var rate:float
@export var max_range:float
@export var knockback:float
@export var stun:float

@export_group("")
@export var item_mods:Array[Resource]

@export_group("Display")
@export var front_hand_pos:Vector2
@export_range(0, 360) var front_hand_rot:float
@export var length = 200
@export var held_offset:Vector2
@export_range(0, 360) var held_rotation:float
@export var directions:Array[float]

@export var use_anim:ItemAnim


func to_array():
	var stat_array = []
	
	stat_array.append(name)
	stat_array.append(description)
	_add_non_zero(stat_array, "Attack Damage", damage)
	_add_non_zero(stat_array, "Attack Rate", rate, " per second")
	_add_non_zero(stat_array, "Range", round(max_range))
	_add_non_zero(stat_array, "Knockback", knockback)
	_add_non_zero(stat_array, "Stun", stun)
	
	return stat_array

func _add_non_zero(array:Array, label:String, value, suffix:String = ""):
	if value != 0:
		array.append(label + ": " + str(value) + suffix)

func call_modifier_method(method:String, caller):
	# Go through item mods and call the method if avaliable
	for item_mod in item_mods:
		if item_mod.has_method(method):
			item_mod.call(method, caller, self)
