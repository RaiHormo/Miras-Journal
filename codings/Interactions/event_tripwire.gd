extends Area2D
class_name EventTripwire

@export var EventName: String
@export var TextFile: String
@export var TextNode: String
@export var Flag: String
@export var FlagShouldBe: bool
@export var TakeControl: bool
@export var ReturnControl: bool
@export var KickDirection: Vector2

func _on_body_entered(body):
	if Event.f(Flag) == FlagShouldBe and body == Global.Player:
		if TakeControl: await Event.take_control(true, true)
		if KickDirection != Vector2.ZERO:
			Global.Player.look_to(KickDirection)
			while Global.Player in get_overlapping_bodies():
				await Global.Player.move_dir(KickDirection)
		if EventName != "": Event.call(EventName)
		else:
			await Global.textbox(TextFile, TextNode)
		if ReturnControl: Event.give_control()
