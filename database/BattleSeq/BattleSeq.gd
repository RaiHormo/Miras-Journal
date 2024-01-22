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
@export var DeleteAttacker := true
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

func reset_events():
	for i in Events:
		if i.repeatable:
			i.ran_this_turn = false
