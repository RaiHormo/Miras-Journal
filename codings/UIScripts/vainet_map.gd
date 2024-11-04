extends Control

var here: String = "Gate"

func _ready() -> void:
	show()
	get_viewport().gui_focus_changed.connect(focus_change)

func focus_place(place: String):
	$Container/Scroller/LocationList.get_node(place).grab_focus()
	if $Map.get_node_or_null(place) != null and place != here:
		$Marker.position = $Map.get_node(place).global_position
		$Marker.show()
	else: $Marker.hide()
	if $Map.get_node_or_null(here) != null:
		$Here.position = $Map.get_node(here).global_position

func focus_change(node: Control):
	for i in $Container/Scroller/LocationList.get_children(): 
		if i is Button: i.icon = preload("res://UI/MenuTextures/dot.png")
	if node.get_parent() == $Container/Scroller/LocationList:
		focus_place(node.name)
		node.icon = preload("res://UI/Map/marker.png")
	for i in $Container/Scroller/LocationList.get_children(): 
		if i is Button and i.name == here: i.icon = preload("res://UI/Map/here.png")
