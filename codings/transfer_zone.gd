extends Area2D
@export var Direction: Vector2
@export var Position:= Vector2.ZERO
@export var room: String
@export var ToCamera: int = 0
@export var Flag: StringName = &""
@export var FlagShouldBe: bool = false
@export var ToCameraIfFlag: int = -1

func _on_entered(body):
	if body == Global.Player:
		proceed()

func proceed() -> void:
	await Event.take_control()
	Global.Player.collision(false)
	Global.Player.move_dir(Direction*5)
	if Flag != &"" and (Event.f(Flag) != FlagShouldBe):
		if ToCameraIfFlag > -1:
			await Loader.travel_to(room, Position, ToCameraIfFlag)
		else: return
	else:
		print(name, " to ", room, " with camera index ", ToCamera)
		await Loader.travel_to(room, Position, ToCamera)

func _on_preview_exited(body):
	if body  == Global.Player: $Cursor.hide()

func _on_preview_entered(body):
	if body == Global.Player: $Cursor.hide()


func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player and Global.get_direction(to_local(body.position)) == Direction:
		body.position = position - Direction*48
		_on_entered(body)
