extends CanvasLayer
var t: Tween
var stage = "inactive"
var focus:Control
var mainIndex = 0
signal loaded
var was_controllable: bool
var was_paused: bool

func _ready():
	if $/root.get_node_or_null("MainMenu") != null and $/root/MainMenu.stage != "options":
		$/root/MainMenu._on_back_button_down()
		queue_free()
		return
	if $/root.get_node_or_null("Options") != null and $/root/Options != self:
		$/root/Options._on_back_pressed()
		queue_free()
		return
	if Loader.InBattle:
		if ($/root.get_node_or_null("Battle/BattleUI") == null or $/root/Battle/BattleUI.stage != "root" or not $/root/Battle/BattleUI.active):
			queue_free()
			return
		$/root/Battle/BattleUI.active = false
		$/root/Battle/BattleUI.stage = "options"
	if not Global.Controllable and $/root.get_node_or_null("MainMenu") == null:
		$MainButtons/SaveManagment.disabled = true
		$MainButtons/GameSettings.grab_focus()
	else:
		if not ResourceLoader.exists("user://Autosave.tres"): await Loader.save()
		$MainButtons/SaveManagment.grab_focus()
	get_viewport().connect("gui_focus_changed", _on_focus_changed)
	was_controllable = Global.Controllable
	Global.Controllable=false
	was_paused = get_tree().paused
	get_tree().paused = true
	$Silhouette.position = Vector2(-1000, -39)
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
		#button.size.x=0
		button.z_index = 0
		t=create_tween()
		t.set_trans(Tween.TRANS_QUART)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(button, "position:x", -700, 0.3).as_relative()
		await get_tree().create_timer(0.1).timeout
	await t.finished
	stage = "main"
	loaded.emit()
	load_save_files()

func siilhouette():
	$Silhouette.texture = Loader.Preview
	var ts=create_tween()
	ts.set_trans(Tween.TRANS_QUART)
	ts.set_ease(Tween.EASE_OUT)
	ts.tween_property($Silhouette, "position", Vector2(0, -39), 1).from(Vector2(-1000, -39))

func _physics_process(delta):
	var playtime:Dictionary = Time.get_time_dict_from_unix_time(Global.get_playtime())
	$Timer/HSplitContainer/Label.text = "%02d:%02d:%02d" % [playtime.hour, playtime.minute, playtime.second]

func _input(event):
	if Global.LastInput==Global.ProcessFrame: return
	$Confirm.icon = Global.get_controller().ConfirmIcon
	$Back.icon = Global.get_controller().CancelIcon
#	if Input.is_action_just_pressed("ui_cancel"):
#		_on_back_pressed()


func _on_back_pressed():
	match stage:
		"main":
			close()
		"game_settings":
			main()
		"save_managment":
			main()

func close():
	if Global.Player != null:
		if $/root.get_node_or_null("MainMenu") != null:
			$/root.get_node("MainMenu")._on_back_button_down()
		else:
			get_tree().paused = was_paused
			Global.Controllable = was_controllable
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
	if Loader.InBattle:
		$/root/Battle/BattleUI.active = true
		$/root/Battle/BattleUI.stage = "root"
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
	$MainButtons.get_child(mainIndex).grab_focus()
	t.tween_property($Background, "position", Vector2(560, 0), 0.5)
	t.tween_property($MainButtons/GameSettings, "position:x", 729, 0.5)
	t.tween_property($MainButtons/SaveManagment, "position", Vector2(663, 52), 0.5)
	t.tween_property($Fader.material, "shader_parameter/lod", 5.0, 1)
	t.tween_property($Fader, "modulate", Color(0,0,0,0.4), 1)
	t.tween_property($Timer, "position", Vector2(27, 27), 0.5)
	t.tween_property($Silhouette, "position", Vector2(0, -39), 0.5)
	t.tween_property($SidePanel, "position", Vector2(1335, -62), 0.5)
	t.tween_property($SavePanel, "position", Vector2(1335, -62), 0.5)
	await Event.wait(0.2)
	for i in $MainButtons.get_children():
		i.z_index = 0
		i.toggle_mode=false
	$Confirm.show()

func game_settings():
	if stage == "game_settings": return
	if stage != "main": await loaded
	load_settings()
	$MainButtons/GameSettings.toggle_mode=true
	$MainButtons/GameSettings.button_pressed=true
	stage="game_settings"
	t=create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_OUT)
	t.set_parallel()
	$SidePanel/ScrollContainer.scroll_horizontal = 0
	$MainButtons/GameSettings.z_index = 1
	t.tween_property($MainButtons/GameSettings, "position", Vector2(25, 196), 0.5)
	t.tween_property($SidePanel, "position", Vector2(407, -62), 0.5)
	t.tween_property($Silhouette, "position", Vector2(-700, -39), 0.5)
	t.tween_property($Background, "position", Vector2(0, 0), 0.5)
	%SettingsVbox/ControlScheme/MenuBar.grab_focus()
	Global.confirm_sound()
	$SidePanel.show()

func save_managment() -> void:
	if stage == "save_managment": return
	if stage != "main": await await loaded
	$SavePanel.show()
	$Confirm.hide()
	$MainButtons/SaveManagment.toggle_mode=true
	$MainButtons/SaveManagment.button_pressed=true
	$SavePanel/Buttons/Load.icon = Global.get_controller().ConfirmIcon
	$SavePanel/Buttons/Overwrite.icon = Global.get_controller().ItemIcon
	$SavePanel/Buttons/Delete.icon = Global.get_controller().CommandIcon
	stage="save_managment"
	t=create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_OUT)
	t.set_parallel()
	$MainButtons/SaveManagment.z_index = 1
	t.tween_property($MainButtons/SaveManagment, "position", Vector2(50, 52), 0.5)
	t.tween_property($Timer, "position:x", -300, 0.5)
	t.tween_property($SavePanel, "position", Vector2(710, -62), 0.5)
	t.tween_property($Silhouette, "position", Vector2(-50, -39), 0.5)
	t.tween_property($Background, "position", Vector2(350, 0), 0.5)
	%Files/File0/Button.grab_focus()
	Global.confirm_sound()
	$SavePanel/Buttons/Load.button_pressed = false

func _on_focus_changed(control:Control):
	Global.cursor_sound()
	focus = control
	if stage=="main":
		mainIndex = focus.get_index()
	if stage=="save_managment":
		if control.get_parent().get_parent().name == "New":
			$Confirm.show()
			$SavePanel/Buttons/Overwrite.disabled = true
			$SavePanel/Buttons/Delete.disabled = true
			$SavePanel/Buttons/Load.disabled = true
		else:
			$Confirm.hide()
			$SavePanel/Buttons/Load.disabled = false
			if control.get_parent().name == "File0":
				$SavePanel/Buttons/Overwrite.disabled = true
				$SavePanel/Buttons/Delete.disabled = true
			else:
				$SavePanel/Buttons/Overwrite.disabled = false
				$SavePanel/Buttons/Delete.disabled = false

func load_settings():
	%SettingsVbox/ControlScheme/MenuBar.selected = Global.Settings.ControlSchemeEnum
	%SettingsVbox/Fullscreen/CheckButton.button_pressed = Global.Settings.Fullscreen
	%SettingsVbox/Master/Slider.value = Global.Settings.MasterVolume*10
	%SettingsVbox/EnvSFX/Slider.value = Global.Settings.EnvSFXVolume*10
	%SettingsVbox/BtSFX/Slider.value = Global.Settings.BtSFXVolume*10
	%SettingsVbox/Music/Slider.value = Global.Settings.MusicVolume*10
	%SettingsVbox/UI/Slider.value = Global.Settings.UIVolume*10
	%SettingsVbox/Voices/Slider.value = Global.Settings.VoicesVolume*10
	%SettingsVbox/BCSadjust/BrtSlider.value = World.environment.adjustment_brightness
	%SettingsVbox/BCSadjust/ConSlider.value = World.environment.adjustment_contrast
	%SettingsVbox/BCSadjust/SatSlider.value = World.environment.adjustment_saturation

func load_save_files():
	for i in %Files.get_children():
		if i.name != "File0" and i.name != "New": i.set_meta(&"Unprocessed", true)
	draw_file(await Loader.load_res("user://Autosave.tres"), %Files/File0)
	for i in DirAccess.get_files_at("user://"):
		if ".tres" in i and not "Autosave" in i and await Loader.load_res("user://"+i) is SaveFile:
			var newpanel:PanelContainer = null
			for j in %Files.get_children():
				if j.name in i:
					newpanel = j
					j.set_meta(&"Unprocessed", false)
			if newpanel == null:
				newpanel = %Files/File0.duplicate()
				newpanel.name = i.replace(".tres", "")
				%Files.add_child(newpanel)
			draw_file(await Loader.load_res("user://" + i), newpanel)
	for j in %Files.get_children():
		if j.name != "File0" and j.name != "New": if j.get_meta(&"Unprocessed"): j.queue_free()
	await Event.wait()

func draw_file(file: SaveFile, node: Control):
	var panel = node.get_child(0)
	if file == null:
		node.get_node("Info/FileName").text = "Corrupt data"
		panel.get_node("Date/Month").text = "Please"
		panel.get_node("Date/Day").text = "Delete"
		return
	node.get_node("Info/FileName").text = file.Name
	panel.get_node("Date/Day").text = str(file.Day)
	if file.Day <= 30 and file.Day > 0:
		panel.get_node("Date/Month").text = "November"
	else:
		panel.get_node("Date/Month").text = "Beyond"
		panel.get_node("Date/Day").text = "Time"
	panel.get_node("Party/Icon0").texture = file.Party.Leader
	for i in range(0,4):
		if file.Party.check_member(i): panel.get_node("Party/Icon"+str(i)).texture = file.Party.get_member(i).PartyIcon
		else: panel.get_node("Party/Icon"+str(i)).texture = null
	var playtime: Dictionary = Time.get_datetime_dict_from_unix_time(int(file.PlayTime))
	panel.get_node("Time/Playtime").text = "%02d:%02d:%02d" % [playtime.hour, playtime.minute, playtime.second]
	panel.get_node("Location").text = file.RoomName
	var savedtime: Dictionary = Time.get_datetime_dict_from_unix_time(int(file.SavedTime))
	var starttime: Dictionary = Time.get_datetime_dict_from_unix_time(int(file.StartTime))
	panel.get_node("SavedDate/Text").text = "Saved: %02d %s %d %d:%d\nStarted: %02d %s %d" % [savedtime.day, Global.get_mmm(savedtime.month),
	savedtime.year, savedtime.hour, savedtime.minute, starttime.day, Global.get_mmm(starttime.month), starttime.year]

func hold_down():
	if $SavePanel/Toast.modulate != Color.TRANSPARENT: return
	t= create_tween()
	t.tween_property($SavePanel/Toast, "modulate:a", 1, 0.3)
	await Event.wait(2)
	var t2= create_tween()
	t2.tween_property($SavePanel/Toast, "modulate:a", 0, 1)

func _on_save_delete() -> void:
	var panel = focus.get_parent()
	var index = focus.get_index()
	panel.get_node("ProgressBar").value = 8
	while (Input.is_action_pressed("BtCommand") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and panel.get_node("ProgressBar").value != 100:
		panel.get_node("ProgressBar").value += 2
		await Event.wait()
	$SavePanel/Buttons/Delete.button_pressed = false
	if panel.get_node("ProgressBar").value == 100:
		Global.confirm_sound()
		print("Deleting user://"+panel.name+".tres")
		DirAccess.remove_absolute("user://"+panel.name+".tres")
		var t2= create_tween()
		t2.tween_property(panel, "modulate:a", 0, 0.5)
		await t2.finished
		await load_save_files()
		if %Files.get_child_count() <= index:
			%Files/File0/Button.grab_focus()
		else:
			%Files.get_child(index).get_node("Button").grab_focus()
	else:
		Global.buzzer_sound()
		hold_down()
		t = create_tween()
		t.set_trans(Tween.TRANS_CUBIC)
		t.set_parallel()
		t.tween_property(panel.get_node("ProgressBar"), "modulate:a", 0, 0.3)
		t.tween_property(panel.get_node("ProgressBar"), "value", 8, 0.3)
		await t.finished
		panel.get_node("ProgressBar").value = 0
		panel.get_node("ProgressBar").modulate.a = 1


func _on_save_overwrite() -> void:
	var panel = focus.get_parent()
	var index = focus.get_index()
	panel.get_node("ProgressBar").value = 8
	while (Input.is_action_pressed("BtItem") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and panel.get_node("ProgressBar").value != 100:
		panel.get_node("ProgressBar").value += 4
		await Event.wait()
		if Input.is_action_pressed("BtCommand"): OS.alert("stop", "no"); return
	$SavePanel/Buttons/Overwrite.button_pressed = false
	if panel.get_node("ProgressBar").value == 100:
		Loader.gray_out()
		Global.confirm_sound()
		print("Overwriting user://"+panel.name+".tres")
		Loader.save(panel.name)
		await load_save_files()
		t = create_tween()
		t.set_trans(Tween.TRANS_CUBIC)
		t.tween_property(panel.get_node("ProgressBar"), "modulate:a", 0, 1)
		#%Files.get_child(%Files.get_child_count() -1).get_node("Button").grab_focus()
		await t.finished
		Loader.ungray.emit()
	else:
		Global.buzzer_sound()
		hold_down()
		t = create_tween()
		t.set_trans(Tween.TRANS_CUBIC)
		t.set_parallel()
		t.tween_property(panel.get_node("ProgressBar"), "modulate:a", 0, 0.3)
		t.tween_property(panel.get_node("ProgressBar"), "value", 8, 0.3)
		await t.finished
	panel.get_node("ProgressBar").value = 0
	panel.get_node("ProgressBar").modulate.a = 1

func _on_save_load() -> void:
	if focus == null: return
	var panel = focus.get_parent()
	if not "File" in panel.name: return
	var index = focus.get_index()
	panel.get_node("ProgressBar").value = 8
	while (Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and panel.get_node("ProgressBar").value != 100:
		panel.get_node("ProgressBar").value += 6
		await Event.wait()
		if Input.is_action_pressed("BtCommand"): OS.alert("stop", "no"); return
	if panel.get_node("ProgressBar").value == 100:
		await Loader.load_game(panel.name)
	else:
		Global.buzzer_sound()
		hold_down()
		t = create_tween()
		t.set_trans(Tween.TRANS_CUBIC)
		t.set_parallel()
		t.tween_property(panel.get_node("ProgressBar"), "modulate:a", 0, 0.3)
		t.tween_property(panel.get_node("ProgressBar"), "value", 8, 0.3)
		await t.finished
	panel.get_node("ProgressBar").value = 0
	panel.get_node("ProgressBar").modulate.a = 1
	$SavePanel/Buttons/Load.button_pressed = false

func _new_file() -> void:
	Global.confirm_sound()
	Loader.gray_out()
	%Files/New/NewFile.hide()
	%Files/New/NewFile.show()
	Loader.icon_save()
	await Loader.save("File"+str(%Files.get_child_count()-1), false)
	await load_save_files()
	if Loader.get_node("Can/Icon").is_playing():
		await Loader.get_node("Can/Icon").animation_finished
	Loader.ungray.emit()
	%Files.get_child(%Files.get_child_count() -1).get_node("Button").grab_focus()


func _on_control_scheme(index):
	Global.confirm_sound()
	Global.Settings.ControlSchemeAuto = false
	Global.Settings.ControlSchemeEnum = %SettingsVbox/ControlScheme/MenuBar.get_selected_id()
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
		10:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/None.tres")
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
	$AudioTester.bus = "Master"
	$AudioTester.play()
	Global.save_settings()

func _on_EnvSFX_volume(value: float) -> void:
	Global.Settings.EnvSFXVolume = value/10
	if Global.Settings.EnvSFXVolume == -30:
		Global.Settings.EnvSFXVolume = -80
	AudioServer.set_bus_volume_db(2, Global.Settings.EnvSFXVolume)
	$AudioTester.bus = "EnvSFX"
	$AudioTester.play()
	Global.save_settings()

func _on_volume_reset():
	Global.Settings.MasterVolume = 0
	AudioServer.set_bus_volume_db(0, Global.Settings.MasterVolume)
	Global.Settings.EnvSFXVolume = 0
	AudioServer.set_bus_volume_db(2, Global.Settings.MasterVolume)
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


func _on_auto_hide_hud(index: int) -> void:
	Global.Settings.AutoHideHUD = index


func _show_image_test() -> void:
	#$ImageTester.show()
	$Fader.hide()
	%SettingsVbox/BCSadjust.show()

func _hide_image_test() -> void:
	$ImageTester.hide()
	$Fader.show()
	Event.wait(0.1)
	%SettingsVbox/AdjustImage.button_pressed = false
	_on_adjust_image(false)


func _on_adjust_image(toggle:bool) -> void:
	if toggle:
		%SettingsVbox/BCSadjust.show()
		%SettingsVbox/BCSadjust/BrtSlider.grab_focus()
		await Event.wait()
		Global.confirm_sound()
	else: %SettingsVbox/BCSadjust.hide()
