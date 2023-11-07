extends Area2D
@export var Direction:Vector2
@export var Position:Vector2 =Vector2.ZERO
@export var Room:String
@export var ToCamera:int =0

func _on_area_entered(area):
	if Direction==Global.get_direction():
		if area.name == "Finder":
			Global.Controllable = false
			Event.move_dir(Direction*5)
			await Loader.travel_to(Room, Position, ToCamera)


func _on_preview_exited():
	$Cursor.hide()

func _on_preview_entered():
	$Cursor.show()
