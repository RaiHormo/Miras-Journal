extends Resource
class_name SaveFile

@export var Name: String="Autosave"
@export var Datetime: Dictionary
@export var Party: Array[StringName] = [&"Mira", &"", &"", &""]
@export var RoomPath: String
@export var RoomName: String = "???"
@export var Position:Vector2
@export var Camera: int = 0
@export var Z: int = 1
@export var Members: Array[Dictionary]
@export var Defeated: Array
@export var StartTime: float
@export var SavedTime: float
@export var PlayTime: float
@export_group("Items")
@export var Inventory: Array[String]
@export var Flags: Array[StringName]
@export var Day: int
@export var TimeOfDay: int
@export var version = 0
@export var checksum: String

func preview() -> Texture:
	match Party:
		["Mira", "Alcine"]:
			return preload("res://art/Previews/2.png")
		_:
			return preload("res://art/Previews/1.png")
