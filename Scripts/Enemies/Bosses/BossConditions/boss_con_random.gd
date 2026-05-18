extends BossCondition

class_name BossConditionRandom

@export var chance : float = 1.0;

var _rng = RandomNumberGenerator.new()

func Evaluate(_source : Node) -> bool:
	return _rng.randf() <= chance
