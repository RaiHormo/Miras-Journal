extends Node2D
class_name SubRoom

@export var Title: String
@export var lock_cam:= true
@export var cam_pos: Vector2
@export var cam_zoom: float = 4
@export var cant_dash_inside = true

func _ready() -> void:
	modulate = Color.TRANSPARENT
	hide()
	for i in get_children(): if i is TileMapLayer: i.collision_enabled = false

func transition():
	$"..".CurSubRoom = self
	show()
	var t = create_tween()
	t.set_parallel()
	t.tween_property(self, "modulate", Color.WHITE,0.3)
	$"..".fade()
	if cant_dash_inside: Global.Player.can_dash = false
	if lock_cam:
		Global.Player.camera_follow(false)
		Global.get_cam().position  = cam_pos
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(Global.get_cam(), "zoom", Vector2(cam_zoom, cam_zoom), 0.3)
	for i in get_children(): if i is TileMapLayer: i.collision_enabled = true
	await t.finished

func detransition():
	$"..".CurSubRoom = null
	$"..".unfade()
	$"..".setup_params(true)
	var t = create_tween()
	t.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	if cant_dash_inside: Global.Player.can_dash = true
	Global.Player.camera_follow(true)
	await t.finished
	hide()
	for i in get_children(): if i is TileMapLayer: i.collision_enabled = false
