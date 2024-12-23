extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	show()
	modulate = Color.WHITE
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$HideTiles.show()

func _on_body_entered(body: Node2D):
	if body == Global.Player:
		var t = create_tween()
		t.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)

func _on_body_exited(body: Node2D):
	if body == Global.Player:
		var t = create_tween()
		t.tween_property(self, "modulate", Color.WHITE, 0.5)
