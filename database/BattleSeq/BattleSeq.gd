extends Resource
class_name BattleSequence

@export var Enemies: Array[Actor]
@export var BattleBack: Texture
@export var Transition: bool = true
@export var Detransition:bool = false
@export var EscPosition:Vector2
@export var PositionSameAsPlayer := false
@export var ScenePosition: Vector2 = Vector2.ZERO
@export var CanEscape := true
#@export var Defeated = false
