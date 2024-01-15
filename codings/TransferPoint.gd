extends Area2D
@export var Direction:Vector2
@export var Position:Vector2 =Vector2.ZERO
@export var Room:String
@export var ToCamera:int =0

func _on_entered(body):
	if body == Global.Player:
		await Event.take_control()
		body.move_dir(Direction*5)
		await Loader.travel_to(Room, Position, ToCamera)


func _on_preview_exited(body):
	if body  == Global.Player: $Cursor.hide()

func _on_preview_entered(body):
	if body == Global.Player: $Cursor.hide()
