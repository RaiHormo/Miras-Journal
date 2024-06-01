extends StaticBody2D
@export var default_anim: String = "default"
@export var break_anim: String = "break"
@export var broken_anim: String = "break"
@export var given_item: String = ""
@export var item_type: StringName = &"Mat"

func _ready() -> void:
	$Sprite.play(default_anim)
	if Event.f(name): set_break()

func _on_area_break_area_entered(area: Area2D) -> void:
	set_break()
	Event.f(name, true)
	if given_item != "":
		if broken_anim != "":
			$Sprite.play(break_anim)
		Item.add_item(given_item, item_type, true, false)

func set_break():
	$Sprite.play(broken_anim)
	$CollisionShape2D.set_deferred("disabled", true)
	$AreaBreak.queue_free()
	z_index -= 1
