extends BossCondition

class_name BossConditionOr

@export var sufficient_conditions : Array[BossCondition]

func Evaluate(source : Node) -> bool:
	for condition in sufficient_conditions:
		if condition.Evaluate(source):
			return true
	
	# Return false if none of them met
	return false
