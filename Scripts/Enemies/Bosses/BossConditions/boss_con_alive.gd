extends BossCondition

class_name BossConditionAlive

@export var part : int
@export var required_life_state = true

func Evaluate(source : Node) -> bool:
	return source.parts[part].alive == required_life_state
