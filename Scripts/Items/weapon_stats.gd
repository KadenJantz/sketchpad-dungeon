extends ItemStats

class_name WeaponStats

@export_group("Attack")
@export var crit_mult = 1.0

@export_group("Profile")
@export var properties = {"Color": false, "Melee": false, "Ranged": false, "Refill": false, "Single-target": false}

var color

const MAX_LINE_LENGTH = 60

func to_array():
	#get base array
	var stat_array = super()
	
	# Add crtical hit multiplier if applicable
	if crit_mult != 1:
		stat_array.append("Critical Multiplier: " + str(crit_mult) + "x")
	
	var enabled = []
	
	#Get all enabled properties
	for property in properties.keys():
		if properties.get(property):
			enabled.append('|' + property + '|')
	
	#ensures new lines are inserted after eachother
	var line_num = 2
	
	#group and add properties
	var n = 0
	while n < len(enabled):
		var line = enabled[n]
		
		#Add additional properties if avaliable and under limit
		while n < len(enabled) - 1 and len(line) + len(enabled[n + 1]) < MAX_LINE_LENGTH:
			line += " " + enabled[n + 1]
			
			n += 1
			
		#insert on next avaliable line
		stat_array.insert(line_num, line)
		line_num += 1
		
		n += 1
		
	#return the array with the weapon adjustments
	return stat_array

func random_color():
	color = ColorRandomizer.random_color()
	
func get_critical():
	return roundi(damage * crit_mult)
			
# Override duplicate
func clone(subresources = false) -> Resource:
	var dupe = super.duplicate(subresources)
	
	dupe.color = color
	
	return dupe
