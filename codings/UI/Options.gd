extends CanvasLayer
var t: Tween
var stage = "inactive"
var focus:Control
var mainIndex = 0

func _ready():
	if not ResourceLoader.exists("user://Autosave.tres"): await Loader.save()
	get_viewport().connect("gui_focus_changed", _on_focus_changed)
	$Silhouette.position = Vector2(-1000, -39)
	$MainButtons/SaveManagment.grab_focus()
	$Confirm.icon = Global.get_controller().ConfirmIcon
	$Back.icon = Global.get_controller().CancelIcon
	siilhouette()
	t=create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_OUT)
	t.set_parallel()
	t.tween_property($Background, "position", Vector2(560, 0), 0.5).from(Vector2(900, -2384))
	t.tween_property($Fader.material, "shader_parameter/lod", 5.0, 1).from(0.0)
	t.tween_property($Fader, "modulate", Color(0,0,0,0.4), 1).from(Color(0,0,0,0))
	t.tween_property($Timer, "position", Vector2(27, 27), 0.5).from(Vector2(-300, 27))
	for button in $MainButtons.get_children():
		button.size.x=0
		button.z_index = 0
		t=create_tween()
		t.set_trans(Tween.TRANS_QUART)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(button, "position:x", -700, 0.3).as_relative()
		await get_tree().create_timer(0.1).timeout
	await t.finished
	stage = "main"

func siilhouette():
	$Silhouette.texture = Loader.Preview
	var ts=create_tween()
	ts.set_trans(Tween.TRANS_QUART)
	ts.set_ease(Tween.EASE_OUT)
	ts.tween_property($Silhouette, "position", Vector2(0, -39), 1).from(Vector2(-1000, -39))

func _physics_process(delta):
	var playtime:Dictionary = Time.get_time_dict_from_unix_time(Global.get_playtime())
	$Timer/HSplitContainer/Label.text = str(playtime.hour)+":"+str(playtime.minute)+":"+str(playtime.second)

func _input(event):
	if Global.LastInput==Global.ProcessFrame: return
	$Confirm.icon = Global.get_controller().ConfirmIcon
	$Back.icon = Global.get_controller().CancelIcon
#	if Input.is_action_just_pressed("ui_cancel"):
#		_on_back_pressed()


func _on_back_pressed():
	if stage=="main":
		close()
	if stage=="game_settings":
		main()

func close():
	if Global.Player != null:
		if Global.Player.get_node("MainMenu").visible:
			Global.Player.get_node("MainMenu")._on_back_button_down()
		else:
			get_tree().paused = false
			Global.Controllable = true
			Global.cancel_sound()
	t=create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_IN)
	t.set_parallel()
	t.tween_property($Timer, "position", Vector2(-300, 27), 0.5)
	t.tween_property($Background, "position", Vector2(900, -2384), 0.5)
	t.tween_property($Silhouette, "position", Vector2(-1000, -39), 0.5)
	t.tween_property($Fader.material, "shader_parameter/lod", 0.0, 0.5)
	t.tween_property($Fader, "modulate", Color(0,0,0,0), 0.5)
	for button in $MainButtons.get_children():
		t.tween_property(button, "position:x", 700, 0.3).as_relative()
	await t.finished
	queue_free()

func main():
	stage = "main"
	t=create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_parallel()
	$MainButtons/GameSettings.toggle_mode=false
	$MainButtons.get_child(mainIndex).grab_focus()
	t.tween_property($Background, "position", Vector2(560, 0), 0.5)
	t.tween_property($MainButtons/GameSettings, "position:x", 729, 0.5)
	t.tween_property($Fader.material, "shader_parameter/lod", 5.0, 1)
	t.tween_property($Fader, "modulate", Color(0,0,0,0.4), 1)
	t.tween_property($Timer, "position", Vector2(27, 27), 0.5)
	t.tween_property($Silhouette, "position", Vector2(0, -39), 0.5)
	t.tween_property($SidePanel, "position", Vector2(1335, -62), 0.5)

func game_settings():
	load_settings()
	$MainButtons/GameSettings.toggle_mode=true
	$MainButtons/GameSettings.button_pressed=true
	stage="game_settings"
	t=create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_OUT)
	t.set_parallel()
	$MainButtons/GameSettings.z_index = 1
	t.tween_property($MainButtons/GameSettings, "position", Vector2(25, 196), 0.5)
	t.tween_property($SidePanel, "position", Vector2(407, -62), 0.5)
	t.tween_property($Silhouette, "position", Vector2(-700, -39), 0.5)
	t.tween_property($Background, "position", Vector2(0, 0), 0.5)
	$SidePanel/ScrollContainer/VBoxContainer/ControlScheme/MenuBar.grab_focus()
	Global.confirm_sound()
	
func _on_focus_changed(control:Control):
	Global.cursor_sound()
	focus = control
	if stage=="main":
		mainIndex = focus.get_index()

func load_settings():
	$SidePanel/ScrollContainer/VBoxContainer/ControlScheme/MenuBar.selected = Global.Settings.ControlSchemeEnum
	$SidePanel/ScrollContainer/VBoxContainer/Fullscreen/CheckButton.button_pressed = Global.Settings.Fullscreen
	$SidePanel/ScrollContainer/VBoxContainer/Master/Slider.value = Global.Settings.MasterVolume*10
	$SidePanel/ScrollContainer/VBoxContainer/Brightness/Slider.value = World.environment.adjustment_brightness
	$SidePanel/ScrollContainer/VBoxContainer/Contrast/Slider.value = World.environment.adjustment_contrast
	$SidePanel/ScrollContainer/VBoxContainer/Saturation/Slider.value = World.environment.adjustment_saturation

func _on_control_scheme(index):
	Global.confirm_sound()
	Global.Settings.ControlSchemeAuto = false
	Global.Settings.ControlSchemeEnum = $SidePanel/ScrollContainer/VBoxContainer/ControlScheme/MenuBar.get_selected_id()
	match Global.Settings.ControlSchemeEnum:
		0:
			Global.Settings.ControlSchemeAuto = true
		7:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/Keyboard.tres")
		2:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/Nintendo.tres")
		3:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/Xbox.tres")
		1:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/Generic.tres")
		4:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/PlayStation.tres")
		6:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/PlayStationOld.tres")
		5:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/SteamDeck.tres")
	Global.save_settings()

func _on_fullscreen():
	Global.fullscreen()
	Global.confirm_sound()
	await get_tree().create_timer(0.5).timeout
	load_settings()


func _on_quit():
	Global.quit()


func _on_master_volume(value:float):
	Global.Settings.MasterVolume = value/10
	if Global.Settings.MasterVolume == -30:
		Global.Settings.MasterVolume = -80
	AudioServer.set_bus_volume_db(0, Global.Settings.MasterVolume)
	Global.cursor_sound()
	Global.save_settings()

func _on_volume_reset():
	Global.Settings.MasterVolume = 0
	AudioServer.set_bus_volume_db(0, Global.Settings.MasterVolume)
	Global.save_settings()
	load_settings()
	Global.confirm_sound()

func confirm():
	Global.confirm_sound()

func cursor(i):
	Global.cursor_sound()

func _on_brightness(value):
	World.environment.adjustment_brightness = max(value, 0.3)


func _on_contrast(value):
	World.environment.adjustment_contrast = max(value, 0.3)


func _on_saturation(value):
	World.environment.adjustment_saturation = value

