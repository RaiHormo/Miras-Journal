extends Resource
class_name BattleSequence

@export var Enemies: Array[Actor]
@export var AdditionalItems: Array[ItemData]
@export var BattleBack: Texture
@export var Transition: bool = true
@export var Detransition:bool = false
@export var ReturnControl: bool = true
@export var EscPosition: Vector2i
@export var PositionSameAsPlayer:= false
@export var ScenePosition: Vector2 = Vector2.ZERO
@export var CanEscape:= true
@export var DeleteAttacker:= true
@export var EntranceSequence:= ""
@export var EntranceBanter:= ""
@export var EntranceBanterIsPassive:= true
@export var VictorySequence:= ""
@export var VictoryBanter:= ""
@export var VictoryText:= "Victory"
@export var DefeatSequence:= ""
@export var PartyOverride: PackedStringArray = []
@export var Events: Array[BattleEvent] = []

func call_events():
	for i in Events:
		if i.check():
			await i.run()

func check_events() -> bool:
	var rtn = false
	for i in Events:
		if i.check(): return true
	return false

func reset_events(force:= false):
	for i in Events:
		if i.repeatable or force:
			i.ran_this_turn = false
