extends BossCondition

class_name BossConditionAnd

@export var necessary_conditions : Array[BossCondition]

func Evaluate(source : Node) -> bool:
	for condition in necessary_conditions:
		if not condition.Evaluate(source):
			return false
	
	# Return true if all of them met
	return true
