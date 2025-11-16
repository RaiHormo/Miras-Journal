extends Area2D
class_name EventTripwire

@export var EventName: String
@export var TextFile: String
@export var TextNode: String
@export var BattleSeq: BattleSequence
@export var Passive: bool = false
@export var Flag: String
@export var FlagIsName: bool = true
@export var FlagShouldBe: bool
@export var AddFlag: bool = false
@export var TakeControl: bool = true
@export var ReturnControl: bool = true
@export var SlowDown: bool = false
@export var KickDirection: Vector2

func _on_body_entered(body):
	if Flag == "" and FlagIsName: Flag = name
	if (Event.f(Flag) == FlagShouldBe or Flag == "") and body == Global.Player:
		print("Tripwire: ", name)
		if AddFlag: Event.add_flag(Flag)
		if SlowDown:
			await Event.take_control()
			Event.give_control(true)
			Global.Player.can_dash = false
			Global.Player.speed = 50
		if TakeControl: await Event.take_control(false, true, true)
		if KickDirection != Vector2.ZERO:
			kick()
		if EventName != "": Event.sequence(EventName)
		elif TextFile != "":
			if Passive:
				await Global.passive(TextFile, TextNode)
			else:
				await Global.textbox(TextFile, TextNode)
		elif BattleSeq != null: Loader.start_battle(BattleSeq)
		if SlowDown: 
			Global.Player.speed = Global.Player.walk_speed
			Global.Player.can_dash = true
		if ReturnControl: Event.give_control(true)

func kick():
	print("kick!")
	Global.Player.look_to(KickDirection)
	while Global.Player in get_overlapping_bodies():
		await Global.Player.move_dir(KickDirection)
