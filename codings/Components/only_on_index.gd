extends CanvasItem

## Free parent when the camera index is not equal to this
@export var index: int = 0


func _ready() -> void:
	if index != Global.CameraInd:
		get_parent().queue_free()
