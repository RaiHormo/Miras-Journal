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
@export_enum("Failed to Load") var given_item := "":
	set(x):
		given_item = x
		notify_property_list_changed()
@export var decrease_z:= true
@export var broken:= false

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if get_node_or_null("Sprite") == null: return
	$Sprite.play(default_anim)
	if Event.f(name): set_break()
	if has_node("Pack"): $Pack.hide()

func _on_area_break_area_entered(area: Area2D) -> void:
	if Engine.is_editor_hint(): return
	set_break()
	Event.add_flag(name, true)
	if given_item != "":
		if broken_anim != "":
			$Sprite.play(break_anim)
			Global.rumble(1, 0.3, 0.2)
		Item.add_item(given_item, item_type, true, false)

func set_break():
	disappear()
	broken = true
	$Sprite.play(broken_anim)
	collision_layer = 0
	collision_mask = 0
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
		var sprite: AnimatedSprite2D = get_node_or_null("Sprite")
		if "Fragment" in given_item and sprite != null:
			var color = given_item.replace("Fragment", "")
			if sprite.sprite_frames.has_animation(color):
				get_node("Sprite").animation = color
				default_anim = color
		property.hint_string = ",".join(items)
		if get(property.name) != "" and get(property.name) not in items:
			item_type = ["Con", "Mat", "Bti", "Key"].pick_random()
			notify_property_list_changed()

func _on_area_prompt_area_entered(area: Area2D) -> void:
	if broken: return
	if Loader.InBattle or not Global.Controllable or not is_instance_valid(Global.Player): return
	if area == Global.Player.get_node_or_null("DirectionMarker/Finder"):
		appear()

func _on_area_prompt_area_exited(area: Area2D) -> void:
	if broken: return
	if area == Global.Player.get_node_or_null("DirectionMarker/Finder"):
		disappear()

func appear():
	if broken: return
	$Pack/Button/Icon.texture = Global.get_controller().OVAttack
	if to_local(Global.Player.position).x <= 0:
		$Pack/Button.scale.x = 1
		$Pack/Button/Label.scale.x = 1
		$Pack/Button/Icon.scale.x = 1
	else:
		$Pack/Button.scale.x = -1
		$Pack/Button/Icon.scale.x = -1
		$Pack/Button/Label.scale.x = -1
	$Pack.show()
	$Pack/AnimationPlayer.play("Appear")
	await Event.wait(0.2)
	if not Global.Player.get_node_or_null("DirectionMarker/Finder") in $AreaPrompt.get_overlapping_areas():
		disappear()
		return
	$Pack/AnimationPlayer.play("Idle")

func disappear():
	if broken: return
	$Pack/AnimationPlayer.play("Disappear")

func _on_button_pressed() -> void:
	disappear()
	Input.action_press("OVAttack")
	Input.action_release("OVAttack")
