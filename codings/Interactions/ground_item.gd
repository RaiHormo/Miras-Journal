extends Node2D

@export var item_type := &"Con"
@export var item_name := ""

func _ready() -> void:
	$Interactable.item = item_name
	$Interactable.itemtype = item_type
	$Interactable.hide_on_flag = name
