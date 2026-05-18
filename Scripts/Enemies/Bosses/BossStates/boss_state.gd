extends Resource

class_name BossState

@export var duration : float

@export var necessary_conditions : Array[BossCondition]

func Evaluate(source : Node2D) -> bool:
	for condition in necessary_conditions:
		if not condition.Evaluate(source):
			return false
	
	# Return true if all of them met
	return true

func Enter(source : Node2D) -> void:
	# Notify all conditions
	for condition in necessary_conditions:
		condition.Enter(source)
	
func Exit(source : Node2D) -> void:
	# Notify all conditions
	for condition in necessary_conditions:
		condition.Exit(source)
