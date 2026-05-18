extends BossCondition

class_name BossConditionRegion

@export var tracked_object : NodePath
@export var region_area2d : NodePath

var track_obj : Node2D
var region : Area2D

func Evaluate(source : Node) -> bool:
	
	# Convert node paths to nodes
	if track_obj == null:
		if tracked_object.is_empty() and "target" in source:
			track_obj = source.target
		else:
			track_obj = source.get_node(tracked_object)
	if region == null:
		region = source.get_node(region_area2d)
		
	# Give warnings if nodes are missing from their paths
	if track_obj == null:
		push_warning("Could not find " + str(tracked_object) + " from source \"" + source.name + "\" for use in Boss Condition Region check!")
		return false
	elif region == null:
		push_warning("Could not find " + str(region_area2d) + " from source \"" + source.name + "\" for use as Boss Condition Region!")
		return false
	
	# Different methods depending on tracked object type
	if track_obj is Area2D:
		return region.overlaps_area(track_obj)
	else:
		return region.overlaps_body(track_obj)
