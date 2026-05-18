extends Node2D

class_name Inventory

@export var display:Container

@export var holder:ItemHolder

@export_range(0, 10, 1, "or_greater") var max_slots = 3

@onready var label = display.get_parent().get_node("Name")

var slots:Array[Slot]

var current_slot = 0: set = _set_item_slot

# Called when the node enters the scene tree for the first time.
func _ready():
	# Fill in slots
	for slot in range(max_slots):
		slots.append(Slot.new())
		
	# Set up slots
	if display:
		var slot_prefab = load("res://Scenes/Item Management/item_slot.tscn")
		
		for slot in range(0, max_slots):
			var new_slot = slot_prefab.instantiate()
			
			display.add_child(new_slot)
			
	# Refresh selected slot
	current_slot = current_slot

	
func get_slot(slot:int) -> Slot:
	# Make sure slot exists
	if slot >= max_slots or slot < 0:
		return null
		
	return slots[slot]
		
func add_item(item:ItemStats, count:int = 1):
	var slot = current_slot
	
	for i in range(len(slots)):
		if slots[i].count == 0:
			slot = i
			break
			
	if item is ConsumableStats:
		for i in range(len(slots)):
			if slot.item == item and slot.count <= item.max_stack:
				add_to_slot(i, count)
				return
				
	set_slot(slot, item, count)

func set_slot(slot:int, item:ItemStats, count:int = 1):
	if slots[slot].item != null:
		var dropped_item = load("res://Scenes/Item Management/item_pickup.tscn").instantiate()
		
		dropped_item.item = slots[slot].item
		dropped_item.count = slots[slot].count
		
		get_tree().root.add_child(dropped_item)
		
		dropped_item.position = global_position
	
	# Create copy of item
	slots[slot].item = item
	
	# Set count accordingly
	if item is ConsumableStats:
		
		slots[slot].count = count
	else:
		slots[slot].count = 1
		
	_refresh_slot(slot)
		
func add_to_slot(slot:int, change:int):
	var slot_ref = get_slot(slot)
	
	# Check to ensure it exists
	if slot_ref:
		return slot_ref.add_item(change)
	else:
		return null
		
func clear_slot(slot:int):
	var slot_ref = get_slot(slot)
	
	# Check to ensure it exists
	if slot_ref:
		# Forward clear to slot
		slot_ref.clear()
		
	_refresh_slot(slot)
		
func _refresh_slot(slot:int):
	# Nothing to refresh
	if not display:
		return
	
	var slot_ref = get_slot(slot)
	
	# Update displayed slot match
	var slot_display = display.get_child(slot)
	
	if slot_ref:
		# Set slot image of item
		var item_image = slot_display.get_node("Image")
		item_image.texture = slot_ref.item.image
		
		# Set slot color
		if slot_ref.item.color:
			# Change item
			item_image.material.set_shader_parameter("color", slot_ref.item.color)
			
			# Change background
			var colorRange:ProgressBar = slot_display.get_node("Paint Color")
			colorRange.value = 100
			colorRange.get_theme_stylebox("fill").bg_color = slot_ref.item.color
			colorRange.get_theme_stylebox("fill").bg_color.a = .5
		
	else:
		# Clear slot
		slot_display.get_node("Image").teture = null
		
		# Clear color
		slot_display.get_node("Paint Color").value = 0
		
	# Refresh selected slot
	current_slot = current_slot
		
func _set_item_slot(new_slot):
	if new_slot >= max_slots:
		return
	
	if holder:
		holder.item_held = slots[new_slot].item
		
	if display:
		display.get_child(current_slot).get_node("Selection").visible = false
		display.get_child(new_slot).get_node("Selection").visible = true
		
		if get_slot(new_slot).item:
			label.text = get_slot(new_slot).item.name
		
		else:
			label.text = ""
	
	current_slot = new_slot


class Slot:
	var item:ItemStats
	var count:int
	
	func add_item(change:int) -> int:
		# Make sure item is stackable
		if not item or not item is ConsumableStats:
			return change
		
		# Make sure it does not go over the limit
		if count + change > item.max_stack:
			var overflow = count + change - item.max_stack
			
			count = item.max_stack
			
			return overflow
			
		# Account for item clear
		if count + change <= 0:
			var overflow = count + change
			
			clear()
			
			return overflow
		
		# Add to item
		count += change
		return 0
	
	func clear():
		item = null
		count = 0
