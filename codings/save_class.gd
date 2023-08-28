extends Resource
class_name SaveFile

@export var Name:String="Autosave"
@export var Datetime:Dictionary
@export var Party:PartyData
@export var Room:PackedScene
@export var Position:Vector2
@export var Camera:int = 0
@export var Members: Array[Actor]
@export var StartTime: int
@export var PlayTime: int
@export_group("Items")
@export var KeyInv: Array[ItemData]
@export var KeyItems: Array[ItemData]
@export var ConInv: Array[ItemData]
@export var Consumables: Array[ItemData]
@export var BatInv: Array[ItemData]
@export var BattleItems: Array[ItemData]
@export var MatInv: Array[ItemData]
@export var Materials: Array[ItemData]
@export var Preview: Texture = preload("res://art/Previews/1.png")
