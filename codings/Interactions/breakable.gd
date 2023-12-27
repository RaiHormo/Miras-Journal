extends StaticBody2D

func _ready() -> void:
	$Sprite.play("default")
	if Event.f(&"VineBroken0"): set_break()

func _on_area_break_area_entered(area: Area2D) -> void:
	set_break()
	Event.f(&"VineBroken0", true)

func set_break():
	$Sprite.play("broken")
	$CollisionShape2D.set_deferred("disabled", true)
	$AreaBreak.queue_free()
