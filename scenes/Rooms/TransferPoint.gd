extends Area2D
@export var Direction:Vector2
@export var Position:Vector2 =Vector2.ZERO
@export var Room:String
@export var ToCamera:int =0

func _on_area_entered(area):
	if Direction==Global.get_direction():
		if area.name == "Finder":
			Global.Controllable = false
			Event.walk(Direction, 20)
			await Loader.travel_to(Room, Position, ToCamera)
