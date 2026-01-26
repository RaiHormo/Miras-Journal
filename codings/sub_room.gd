extends Node2D
class_name SubRoom

@export var Title: String
@export var lock_cam:= true
@export var cam_pos: Vector2
@export var cam_zoom: float = 4
@export var cant_dash_inside = true
var Layers: Array[TileMapLayer]
var t

func _ready() -> void:
	modulate = Color.TRANSPARENT
	hide()
	for i in get_children():
		if i is TileMapLayer:
			Layers.append(i)
			i.collision_enabled = false

func transition():
	Global.Area.CurSubRoom = self
	show()
	if is_instance_valid(t): t.kill()
	t = create_tween()
	t.set_parallel()
	t.tween_property(self, "modulate", Color.WHITE,0.3)
	Global.Area.fade()
	Global.Player.z_index = z_index
	Event.teleport_followers()
	if cant_dash_inside: Global.Player.can_dash = false
	if lock_cam:
		Global.Player.camera_follow(false)
		Global.get_cam().position  = cam_pos
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(Global.get_cam(), "zoom", Vector2(cam_zoom, cam_zoom), 0.2)
	for i in get_children(): if i is TileMapLayer: i.collision_enabled = true
	await t.finished
	for i in Layers:
		i.material = preload("res://codings/Shaders/Pixelart.tres")
		i.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func detransition():
	Global.Area.CurSubRoom = null
	Global.Area.unfade()
	Global.Area.setup_params(true)
	if cant_dash_inside: Global.Player.can_dash = true
	Global.Player.camera_follow(true)
	await fade_out()
	hide()
	for i in get_children(): if i is TileMapLayer: i.collision_enabled = false
	Event.teleport_followers()
	Global.Player.z_index = Global.Area.z_index
	if Global.Area.CurSubRoom == self:
		Event.take_control(true, true)
		await transition()
		Event.give_control(false)

func fade_out():
	if is_instance_valid(t): t.kill()
	t = create_tween()
	t.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
	for i in Layers:
		i.material = null
		i.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	await t.finished
	hide()
	for i in get_children(): if i is TileMapLayer: i.collision_enabled = false
