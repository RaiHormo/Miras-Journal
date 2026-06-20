@tool
@icon("res://art/Icons/Editor/transfer.png")
class_name TransferZone
extends Area2D

@export var trigger_size := Vector2i(80, 80):
	set(x):
		trigger_size = x

		for coll in get_children():
			if coll is CollisionShape2D:
				coll.shape = coll.shape.duplicate()
				coll.shape.size = x

@export var direction: Vector2
@export var lock_camera := true

@export_category("Transfer To")
@export_enum("Debug") var room: String
@export var subroom: String
@export var ToCamera: int = 0

@export_group("Use Exact Position")
## Use an exact position. Alternatively, specify a subroom
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var UseExactPosition := false
@export var Position := Vector2.ZERO


func _validate_property(property: Dictionary) -> void:
	if not Engine.is_editor_hint(): return

	match property.name:
		"room":
			var files := DirAccess.get_files_at("res://rooms")
			var files_filtered: Array[String]
			for i in files:
				if i.ends_with(".tscn"):
					files_filtered.append(i.replace(".tscn", ""))
			property.hint_string = ",".join(files_filtered)


func _on_entered(body: Node2D) -> void:
	if body == Global.Player:
		if Global.Controllable or Global.Player.dashing or Global.Player.attacking:
			proceed()


func proceed() -> void:
	var frame := Global.Player.sprite.frame
	Global.Player.camera_follow(false)
	await Event.take_control(true, true)
	Global.Player.collision(false)
	Global.Player.move_dir(direction * 48, false)
	Global.Player.sprite.frame = frame
	#print(name, " to ", room, " with camera index ", ToCamera)

	var room_string: String = room + ";" + subroom

	await Loader.travel_to(room_string, Position, ToCamera)


func _on_preview_exited(body: Node2D) -> void:
	if body == Global.Player: $Cursor.hide()


func _on_preview_entered(body: Node2D) -> void:
	if body == Global.Player: $Cursor.hide()


func _on_body_exited(body: Node2D) -> void:
	if body == Global.Player and Direction.snap_vector(to_local(body.position)) == direction:
		body.position = position - direction * 48
		_on_entered(body)
