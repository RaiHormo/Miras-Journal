extends Node2D

@export var item_type := &"Con"
@export var item_name := ""

func _ready() -> void:
	$Sprite.frame = randi_range(0, 13)
	$Interactable.item = item_name
	$Interactable.itemtype = item_type
	$Interactable.hide_on_flag = name
