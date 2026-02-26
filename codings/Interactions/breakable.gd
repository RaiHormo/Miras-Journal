@tool
extends StaticBody2D
@export var default_anim: String = "default"
@export var break_anim: String = "break"
@export var broken_anim: String = "break"
@export_enum("Con", "Mat", "Bti", "Key") var item_type := "Con":
	set(x):
		item_type = x
		given_item = ""
		notify_property_list_changed()
@export_enum("Failed to Load") var given_item := ""
@export var decrease_z:= true

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if get_node_or_null("Sprite") == null: return
	$Sprite.play(default_anim)
	if Event.f(name): set_break()

func _on_area_break_area_entered(area: Area2D) -> void:
	if Engine.is_editor_hint(): return
	set_break()
	Event.f(name, true)
	if given_item != "":
		if broken_anim != "":
			$Sprite.play(break_anim)
			Global.rumble(1, 0.3, 0.2)
		Item.add_item(given_item, item_type, true, false)

func set_break():
	$Sprite.play(broken_anim)
	$CollisionShape2D.set_deferred("disabled", true)
	$AreaBreak.queue_free()
	if decrease_z: z_index -= 1

func _validate_property(property: Dictionary) -> void:
	if property.name == "given_item" and Engine.is_editor_hint():
		var type: String
		match item_type:
			"Con": type = "Consumables"
			"Bti": type = "BattleItems"
			"Mat": type = "Materials"
			"Key": type = "KeyItems"
		var files = DirAccess.get_files_at("res://database/Items/"+type)
		var items: Array[String]
		for i in files:
			items.append(i.replace(".tres", ""))
		property.hint_string = ",".join(items)
		if get(property.name) != "" and get(property.name) not in items:
			item_type = ["Con", "Mat", "Bti", "Key"].pick_random()
			notify_property_list_changed()
