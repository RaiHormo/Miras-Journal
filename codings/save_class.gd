extends Resource
class_name SaveFile

@export var Name:String="Autosave"
@export var Datetime:Dictionary
@export var Party:PartyData
@export var Room:PackedScene
@export var Position:Vector2
@export var Camera:int = 0
@export var Members: Array[Actor]
@export var Defeated: Array
@export var StartTime: float
@export var PlayTime: float
@export var Preview: Texture = preload("res://art/Previews/1.png")
@export_group("Items")
@export var KeyInv: Array[ItemData]
@export var ConInv: Array[ItemData]
@export var BatInv: Array[ItemData]
@export var MatInv: Array[ItemData]
@export var Flags: Array[String]
@export var Day: int
var version = 2
