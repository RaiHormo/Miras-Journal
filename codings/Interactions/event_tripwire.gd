extends Area2D
class_name EventTripwire

@export var EventName: String
@export var TextFile: String
@export var TextNode: String
@export var Passive: bool = false
@export var Flag: String
@export var FlagIsName: bool = true
@export var FlagShouldBe: bool
@export var AddFlag: bool = false
@export var TakeControl: bool = true
@export var ReturnControl: bool = true
@export var KickDirection: Vector2

func _on_body_entered(body):
	if Flag == "" and FlagIsName: Flag = name
	if (Event.f(Flag) == FlagShouldBe or Flag == "") and body == Global.Player:
		print("Tripwire: ", name)
		if AddFlag: Event.add_flag(Flag)
		if TakeControl: await Event.take_control(false, true)
		if KickDirection != Vector2.ZERO:
			kick()
		if EventName != "": Event.sequence(EventName)
		else:
			if Passive:
				await Global.passive(TextFile, TextNode)
			else:
				await Global.textbox(TextFile, TextNode)
		if ReturnControl: Event.give_control(true)

func kick():
	Global.Player.look_to(KickDirection)
	while Global.Player in get_overlapping_bodies():
		await Global.Player.move_dir(KickDirection)
