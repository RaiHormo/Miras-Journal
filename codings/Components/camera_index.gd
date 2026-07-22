@tool
extends ReferenceRect
class_name CameraIndex

## Specific settings for the camera while the camera index is equal 
## to X in the name CameraIndexX

## Overwrite location title when in this camera index
@export var title := ""

## Multiplier for the camera zoom,.Vector(X, X)
@export var zoom: float = 4.0

## Whether the player should spawn in this index
@export var spawn_player := true

## Where the player should spawn by default
@export var spawn_position := Vector2i.ZERO:
	set(x):
		spawn_position = x

		if Engine.is_editor_hint():
			if spawn_pos_marker == null:
				spawn_pos_marker = get_node("SpawnPos")

			if x != null:
				spawn_pos_marker.global_position = x as Vector2

			spawn_pos_marker.visible = not x == Vector2i.ZERO

@export_flags_2d_physics var layers := 1

## Overwrite the player's Z index
@export var z := 0

## Mira should hold a flame in this index
@export_enum("Keep:0", "Activate:1", "Deactivate:-1") var flame := 0

@export_group("Camera Limits")

@export var left: int:
	get():
		return position.x as int

	set(x):
		left = x
		position.x = x

@export var up: int:
	get():
		return position.y as int

	set(x):
		up = x
		position.y = x

@export var right: int:
	get():
		return position.x + size.x as int

	set(x):
		right = x
		size.x = x - position.x

@export var down: int:
	get():
		return position.y + size.y as int

	set(x):
		down = x
		size.y = x - position.y

var index: int:
	get():
		return name.to_int()

@onready var spawn_pos_marker: Marker2D = $SpawnPos


func _ready() -> void:
	if Engine.is_editor_hint():
		spawn_pos_marker.global_position = spawn_position
