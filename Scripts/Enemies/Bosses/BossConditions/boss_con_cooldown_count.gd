extends BossCondition

class_name BossConditionCooldownCount

@export var min_count : int

var last_count : int

func Evaluate(source : Node) -> bool:
	return source.states_used - last_count > min_count

func Enter(source : Node) -> void:
	last_count = source.states_used
