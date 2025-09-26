extends CanvasLayer
var t: Tween
var stage = "inactive"
var focus:Control
var mainIndex = 0
signal loaded
var was_controllable: bool
var was_paused: bool
var cant_save:= false
var save_files_loaded:= false
var no_main:= false

@export_multiline var Tutorials: Array[String]

func _ready():
	hide()
	if $/root.get_node_or_null("MainMenu") and $/root/MainMenu.stage != "options":
		$/root/MainMenu._on_back_button_down()
		queue_free()
		return
	if $/root.get_node_or_null("Options") and $/root/Options != self:
		$/root/Options._on_back_pressed()
		queue_free()
		return
	if Loader.InBattle:
		if !get_tree().root.get_node_or_null("Battle/BattleUI") or $/root/Battle/BattleUI.stage != "root" or not $/root/Battle/BattleUI.active:
			queue_free()
			return
		$/root/Battle/BattleUI.active = false
		$/root/Battle/BattleUI.stage = "options"
	if Loader.InBattle:
		$MainButtons/SaveManagment.disabled = true
		$MainButtons/GameSettings.grab_focus()
	else:
		$MainButtons/SaveManagment.grab_focus()
	if not ResourceLoader.exists("user://Autosave.tres") or not is_instance_valid(Global.Area): 
		cant_save = true
	Loader.detransition("")
	show()
	get_viewport().connect("gui_focus_changed", _on_focus_changed)
	was_controllable = Global.Controllable
	Global.Controllable = false
	was_paused = get_tree().paused
	get_tree().paused = true
	$Timer.position =  Vector2(-300, 27)
	$Silhouette.position = Vector2(-1000, -39)
	$Confirm.icon = Global.get_controller().ConfirmIcon
	$Back.icon = Global.get_controller().CancelIcon
	$Background/Version.text += ProjectSettings.get_setting("application/config/version")
	t=create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_OUT)
	t.set_parallel()
	t.tween_property($Fader.material, "shader_parameter/lod", int(Global.Settings.BlurEffect)*3.0, 1).from(0.0)
	t.tween_property($Fader, "modulate", Color(0,0,0,0.4), 1).from(Color(0,0,0,0))
	if no_main: return
	t.tween_property($Background, "position", Vector2(560, 0), 0.5).from(Vector2(900, -2384))
	t.tween_property($Timer, "position", Vector2(27, 27), 0.5).from(Vector2(-300, 27))
	siilhouette()
	Global.confirm_sound()
	for button in $MainButtons.get_children():
		#button.size.x=0
		button.z_index = 0
		t=create_tween()
		t.set_trans(Tween.TRANS_QUART)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(button, "position:x", -700, 0.3).as_relative()
		await get_tree().create_timer(0.05).timeout
	await t.finished
	stage = "main"
	loaded.emit()

func set_no_main():
	no_main = true
	for i in $MainButtons.get_children():
		i.hide()
	await ready
	#await Event.wait(0.3, false)
	stage = "main"
	loaded.emit()
	#$Background.hide()

func siilhouette():
	$Silhouette.texture = Loader.Preview
	var ts=create_tween()
	ts.set_trans(Tween.TRANS_QUART)
	ts.set_ease(Tween.EASE_OUT)
	ts.tween_property($Silhouette, "position", Vector2(0, -39), 1).from(Vector2(-1000, -39))
	load_settings()
	await ts.finished
	#load_save_files()

func _physics_process(delta):
	var playtime:Dictionary = Time.get_time_dict_from_unix_time(Global.get_playtime())
	$Timer/HSplitContainer/Label.text = "%02d:%02d:%02d" % [playtime.hour, playtime.minute, playtime.second]

func _input(event):
	if Global.LastInput==Global.ProcessFrame: return
	$Confirm.icon = Global.get_controller().ConfirmIcon
	$Back.icon = Global.get_controller().CancelIcon
	#if stage == "game_settings": load_settings()
#	if Input.is_action_just_pressed("ui_cancel"):
#		_on_back_pressed()

func _on_back_pressed():
	Global.cancel_sound()
	match stage:
		"main":
			close()
		"game_settings", "save_managment", "gallery", "manual":
			main()
		"manual_text":
			stage = "manual"
			Global.cancel_sound()

func close(force = false):
	Global.check_party.emit()
	if force:
		queue_free()
		return
	if stage == "closing": return
	if is_instance_valid(Global.Player):
		if $/root.get_node_or_null("MainMenu"):
			$/root.get_node("MainMenu")._on_back_button_down()
		else:
			Global.cancel_sound()
	if is_instance_valid(t): t.kill()
	t = create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_IN)
	t.set_parallel()
	for button in $MainButtons.get_children():
		print(stage)
		if stage == "main":
			t.tween_property(button, "position:x", 700, 0.3).as_relative()
		else:
			t.tween_property(button, "position:x", 1400, 0.5)
	t.tween_property($Timer, "position", Vector2(-300, 27), 0.5)
	t.tween_property($Background, "position", Vector2(900, -2384), 0.5)
	t.tween_property($Silhouette, "position", Vector2(-1000, -39), 0.5)
	t.tween_property($Fader.material, "shader_parameter/lod", 0.0, 0.5)
	t.tween_property($Fader, "modulate", Color(0,0,0,0), 0.5)
	t.tween_property($SidePanel, "position", Vector2(1335, -62), 0.5)
	t.tween_property($SavePanel, "position", Vector2(1335, -62), 0.5)
	t.tween_property($ManualPanel, "position", Vector2(1335, -62), 0.5)
	t.tween_property($GalleryPanel, "position", Vector2(1335, -62), 0.5)
	if Loader.InBattle:
		$/root/Battle/BattleUI.active = true
		$/root/Battle/BattleUI.stage = "root"
		
	stage="closing"
	await t.finished
	get_tree().paused = was_paused
	Global.Controllable = was_controllable
	if !is_instance_valid(Global.Area):
		if not get_tree().root.has_node("Initializer"):
			Global.title_screen()
	queue_free()

func main():
	if stage == "closing": return
	if no_main:
		close()
		return
	stage = "main"
	t=create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_parallel()
	$MainButtons.get_child(mainIndex).grab_focus()
	t.tween_property($Background, "position", Vector2(560, 0), 0.5)
	t.tween_property($MainButtons/GameSettings, "position:x", 729, 0.5)
	t.tween_property($MainButtons/SaveManagment, "position", Vector2(663, 52), 0.5)
	t.tween_property($MainButtons/Gallery, "position", Vector2(887, 491), 0.5)
	t.tween_property($MainButtons/Manual, "position", Vector2(846, 343), 0.5)
	t.tween_property($MainButtons/Quit, "position", Vector2(932, 633), 0.5)
	t.tween_property($MainButtons/Manual, "rotation_degrees", 0, 0.5)
	t.tween_property($Fader.material, "shader_parameter/lod", int(Global.Settings.BlurEffect)*3.0, 1)
	t.tween_property($Fader, "modulate", Color(0,0,0,0.4), 1)
	t.tween_property($Timer, "position", Vector2(27, 27), 0.5)
	t.tween_property($Silhouette, "position", Vector2(0, -39), 0.5)
	t.tween_property($SidePanel, "position", Vector2(1335, -62), 0.5)
	t.tween_property($SavePanel, "position", Vector2(1335, -62), 0.5)
	t.tween_property($ManualPanel, "position", Vector2(1335, -62), 0.5)
	t.tween_property($GalleryPanel, "position", Vector2(1335, -62), 0.5)
	t.tween_property($Back, "position:x", 207.0, 0.5)
	t.tween_property($Confirm, "position:x", 26, 0.5)
	await Event.wait(0.2, false)
	for i in $MainButtons.get_children():
		i.z_index = 0
		i.toggle_mode=false
	$Confirm.show()
	Loader.ungray.emit()
	await t.finished
	if stage == "main":
		$SavePanel.hide()
		$SidePanel.hide()
		$GalleryPanel.hide()
		$MainButtons.get_child(mainIndex).grab_focus()

func game_settings():
	if stage == "game_settings": return
	if stage != "main": await loaded
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
	await t.finished
	load_settings()

func save_managment() -> void:
	if stage == "save_managment": return
	if stage != "main": await await loaded
	if not save_files_loaded and not no_main:
		Loader.icon_load()
		#Loader.gray_out()
	else:
		if %Files/File0.visible:
			%Files/File0/Button.grab_focus()
		else: %Files/New/NewGame.grab_focus()
	$SavePanel.show()
	$MainButtons/SaveManagment.show()
	$MainButtons/SaveManagment.toggle_mode=true
	$MainButtons/SaveManagment.button_pressed=true
	$SavePanel/Buttons/Load.icon = Global.get_controller().ConfirmIcon
	$SavePanel/Buttons/Overwrite.icon = Global.get_controller().ItemIcon
	$SavePanel/Buttons/Delete.icon = Global.get_controller().CommandIcon
	$SavePanel/Buttons/Overwrite.disabled = true
	$SavePanel/Buttons/Delete.disabled = true
	stage="save_managment"
	t=create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_OUT)
	t.set_parallel()
	$MainButtons/SaveManagment.z_index = 1
	t.tween_property($MainButtons/SaveManagment, "position", Vector2(50, 52), 0.5)
	t.tween_property($Timer, "position:x", -300, 0.5)
	t.tween_property($SavePanel, "position", Vector2(684, -62), 0.5)
	t.tween_property($Silhouette, "position", Vector2(-50, -39), 0.5)
	t.tween_property($Background, "position", Vector2(350, 0), 0.5)
	t.tween_property($Back, "position:x", 26, 0.5)
	t.tween_property($Confirm, "position:x", -200, 0.5)
	Global.confirm_sound()
	$SavePanel/Buttons/Load.button_pressed = false
	await t.finished
	if not save_files_loaded:
		await load_save_files()
		if stage != "save_managment": return
		if %Files/File0.visible:
			%Files/File0/Button.grab_focus()
		else: %Files/New/NewGame.grab_focus()
	stage="save_managment"

func manual() -> void:
	if stage == "manual": return
	if stage != "main": await loaded
	$MainButtons/Manual.show()
	$MainButtons/Manual.toggle_mode=true
	$MainButtons/Manual.button_pressed=true
	stage = "manual"
	t=create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT).set_parallel()
	$ManualPanel/ScrollContainer.scroll_horizontal = 0
	$MainButtons/Manual.z_index = 1
	t.tween_property($MainButtons/Manual, "position", Vector2(40, 280), 0.5)
	t.tween_property($MainButtons/Manual, "rotation_degrees", -90, 0.5)
	for i in $MainButtons.get_children():
		if i != $MainButtons/Manual: t.tween_property(i, "position:x", 850, 0.5)
	t.tween_property($ManualPanel, "position", Vector2(100, -92), 0.5)
	t.tween_property($Silhouette, "position", Vector2(-100, -39), 0.5)
	t.tween_property($Background, "position", Vector2(-200, 0), 0.5)
	t.tween_property($Back, "position:x", 26, 0.5)
	t.tween_property($Confirm, "position:x", -200, 0.5)
	$ManualPanel/ScrollContainer/VBoxContainer.get_child(0).grab_focus()
	_manual_entry_pressed()
	t.tween_property($Silhouette, "position", Vector2(-700, -39), 0.5)
	t.tween_property($Timer, "position", Vector2(-700, -39), 0.5)
	Global.confirm_sound()
	$ManualPanel.show()
	await t.finished
	stage = "manual"

func gallery():
	if stage == "gallery": return
	if stage != "main": await loaded
	$MainButtons/Gallery.toggle_mode=true
	$MainButtons/Gallery.button_pressed=true
	stage="gallery"
	t=create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_OUT)
	t.set_parallel()
	$GalleryPanel/ScrollContainer.scroll_horizontal = 0
	$MainButtons/Gallery.z_index = 1
	t.tween_property($MainButtons/Gallery, "position", Vector2(570, 491), 0.5)
	for i in $MainButtons.get_children():
		if i != $MainButtons/Gallery: t.tween_property(i, "position:x", 850, 0.5)
	t.tween_property($GalleryPanel, "position", Vector2(800, -62), 0.5)
	t.tween_property($Silhouette, "position", Vector2(-100, -39), 0.5)
	t.tween_property($Background, "position", Vector2(400, 0), 0.5)
	$GalleryPanel/ScrollContainer/VBoxContainer/Credits.grab_focus()
	Global.confirm_sound()
	$GalleryPanel.show()

func _on_focus_changed(control:Control):
	Global.cursor_sound(true)
	focus = control
	if stage=="main" and control.get_parent() == $MainButtons:
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
				$Silhouette.texture = Loader.Preview
			else:
				$SavePanel/Buttons/Overwrite.disabled = false
				$SavePanel/Buttons/Delete.disabled = false
	if cant_save:
		$SavePanel/Buttons/Overwrite.disabled = true
		$SavePanel/ScrollContainer/Files/New/NewFile.disabled = true

func load_settings():
	Global.save_settings()
	Global.apply_settings()
	%SettingsVbox/AutoHideHUD/MenuBar.selected = Global.Settings.AutoHideHUD
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
	%SettingsVbox/DebugMode.button_pressed = Global.Settings.DebugMode
	%SettingsVbox/Vsync/CheckButton.button_pressed = Global.Settings.VSync
	%SettingsVbox/GlowEffect/CheckButton.button_pressed = Global.Settings.GlowEffect
	%SettingsVbox/HighResTextures/CheckButton.button_pressed = Global.Settings.HighResTextures
	%SettingsVbox/TextSpeed/MenuBar.selected = Global.Settings.TextSpeed
	%SettingsVbox/UpscaledResolution/CheckButton.button_pressed = Global.Settings.UpscaledRes
	%SettingsVbox/ControllerVibration/CheckButton.button_pressed = Global.Settings.ControllerVibration
	%SettingsVbox/BlurEffect/CheckButton.button_pressed = Global.Settings.BlurEffect
	match Global.Settings.FPS:
		0: %SettingsVbox/FPS/MenuBar.selected = 0
		30: %SettingsVbox/FPS/MenuBar.selected = 1
		60: %SettingsVbox/FPS/MenuBar.selected = 2
		144: %SettingsVbox/FPS/MenuBar.selected = 3

	%SettingsVbox/ControlPreview/A.set_deferred("texture", Global.get_controller().AbilityIcon)
	%SettingsVbox/ControlPreview/B.set_deferred("texture", Global.get_controller().AttackIcon)
	%SettingsVbox/ControlPreview/Y.set_deferred("texture", Global.get_controller().ItemIcon)
	%SettingsVbox/ControlPreview/X.set_deferred("texture", Global.get_controller().CommandIcon)
	%SettingsVbox/ControlPreview/R.set_deferred("texture", Global.get_controller().R)
	%SettingsVbox/ControlPreview/L.set_deferred("texture", Global.get_controller().L)
	%SettingsVbox/ControlPreview/LZ.set_deferred("texture", Global.get_controller().LZ)
	%SettingsVbox/ControlPreview/RZ.set_deferred("texture", Global.get_controller().RZ)
	%SettingsVbox/ControlPreview/Start.set_deferred("texture", Global.get_controller().Start)
	%SettingsVbox/ControlPreview/Select.set_deferred("texture", Global.get_controller().Select)
	%SettingsVbox/ControlPreview/ConfirmB.set_deferred("texture", Global.get_controller().ConfirmIcon)
	%SettingsVbox/ControlPreview/CancelB.set_deferred("texture", Global.get_controller().CancelIcon)
	%SettingsVbox/ControlPreview/MenuB.set_deferred("texture", Global.get_controller().Menu)
	%SettingsVbox/ControlPreview/DashB.set_deferred("texture", Global.get_controller().Dash)
	var setting = await Loader.load_res("user://Settings.res")


func load_save_files():
	for i in %Files.get_children():
		if i.name != "File0" and i.name != "New": i.set_meta(&"Unprocessed", true)
	if ResourceLoader.exists("user://Autosave.tres"):
		draw_file(await Loader.load_res("user://Autosave.tres"), %Files/File0)
	else:
		%Files/File0.hide()
		Global.toast("There is nothing saved, you can start a new game.")
	Loader.SaveFiles.clear()
	for i in DirAccess.get_files_at("user://"):
		if ".tres" in i and not "Autosave" in i:
			var data = await Loader.load_res("user://"+i)
			if data is SaveFile:
				Loader.SaveFiles.append(data)
				var newpanel:PanelContainer = null
				for j in %Files.get_children():
					if j.name in i:
						newpanel = j
						j.set_meta(&"Unprocessed", false)
				if !newpanel:
					newpanel = %Files/File0.duplicate()
					newpanel.name = i.replace(".tres", "")
					%Files.add_child(newpanel)
				draw_file(data, newpanel)
	for j in %Files.get_children():
		if j.name != "File0" and j.name != "New": if j.get_meta(&"Unprocessed"): j.queue_free()
	await Event.wait()
	if not save_files_loaded:
		Loader.ungray.emit()
	save_files_loaded = true


func draw_file(file: SaveFile, node: Control):
	var panel = node.get_child(0)
	if file == null or file.version != Loader.SaveVersion:
		node.get_node("Info/FileName").text = "Unloadable data"
		panel.get_node("Date/Month").text = "Please"
		panel.get_node("Date/Day").text = "Delete"
		panel.get_node("Location").text = "Now"
		return
	node.get_node("Info/FileName").text = file.Name
	panel.get_node("Date/Day").text = str(file.Day)
	if file.Day <= 30 and file.Day > 0:
		panel.get_node("Date/Month").text = "November"
	elif file.Day == 0:
		panel.get_node("Date/Month").text = "Date"
		panel.get_node("Date/Day").text = "Unknown"
	else:
		panel.get_node("Date/Month").text = "Beyond"
		panel.get_node("Date/Day").text = "Time"
	panel.get_node("Party/Icon0").texture = Global.find_member(file.Party[0]).PartyIcon
	for i in range(0,4):
		if file.Party[i] != &"": panel.get_node("Party/Icon"+str(i)).texture =  Global.find_member(file.Party[i]).PartyIcon
		else: panel.get_node("Party/Icon"+str(i)).texture = null
	var playtime: Dictionary = Time.get_datetime_dict_from_unix_time(int(file.PlayTime))
	panel.get_node("Time/Playtime").text = "%02d:%02d:%02d" % [playtime.hour, playtime.minute, playtime.second]
	panel.get_node("Location").text = file.RoomName
	var savedtime: Dictionary = Time.get_datetime_dict_from_unix_time(int(file.SavedTime))
	var starttime: Dictionary = Time.get_datetime_dict_from_unix_time(int(file.StartTime))
	panel.get_node("SavedDate").text = "Saved: %02d %s %d %d:%d\nStarted: %02d %s %d" % [savedtime.day, Global.get_mmm(savedtime.month),
	savedtime.year, savedtime.hour, savedtime.minute, starttime.day, Global.get_mmm(starttime.month), starttime.year]

func hold_down():
	if $SavePanel/Toast.modulate != Color.TRANSPARENT: return
	t= create_tween()
	t.tween_property($SavePanel/Toast, "modulate:a", 1, 0.3)
	await Event.wait(2, false)
	var t2= create_tween()
	t2.tween_property($SavePanel/Toast, "modulate:a", 0, 1)

func _on_save_delete() -> void:
	if stage != "save_managment": return
	var panel = focus.get_parent()
	var index = focus.get_index()
	panel.get_node("ProgressBar").value = 8
	while (Input.is_action_pressed("BtCommand") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and panel.get_node("ProgressBar").value != 100:
		panel.get_node("ProgressBar").value += 2
		await Event.wait(0.01, false)
	$SavePanel/Buttons/Delete.button_pressed = false
	if panel.get_node("ProgressBar").value == 100:
		Global.confirm_sound()
		if panel.name == "File0":
			if cant_save:
				Global.toast("Press F1 to delete the file manually.")
			else:
				print("Deleting user://Autosave.tres")
				DirAccess.remove_absolute("user://Autosave.tres")
				Loader.save()
				panel.set_meta(&"Unprocessed", true)
		else:
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
	if stage != "save_managment": return
	var panel = focus.get_parent()
	var index = focus.get_index()
	panel.get_node("ProgressBar").value = 8
	while (Input.is_action_pressed("BtItem") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and panel.get_node("ProgressBar").value != 100:
		panel.get_node("ProgressBar").value += 4
		await Event.wait(0.01, false)
		if not is_instance_valid(panel): return
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
	if stage != "save_managment" or not is_instance_valid(focus): return
	var panel = focus.get_parent()
	if "New" in panel.name: return
	var filename = panel.name
	if panel.name == "File0": filename = "Autosave"
	if not panel is PanelContainer:
		$SavePanel/ScrollContainer/Files/File0/Button.grab_focus()
		return
	var index = focus.get_index()
	panel.get_node("ProgressBar").value = 8
	while (Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and panel.get_node("ProgressBar").value != 100:
		panel.get_node("ProgressBar").value += 5
		await Event.wait(0.01, false)
		if Input.is_action_pressed("BtCommand"): OS.alert("stop", "no"); return
	if panel.get_node("ProgressBar").value == 100:
		if not FileAccess.file_exists("user://"+filename+".tres"): return
		await Loader.load_game(filename)
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
	var i = 0
	while %Files.get_child_count() > i:
		i += 1
		var found = false
		for file in %Files.get_children():
			if file.name == "File"+str(i): 
				found = true
		if not found:
			break
	await Loader.save("File"+str(i), false)
	await load_save_files()
	Loader.ungray.emit()
	%Files.get_child(%Files.get_child_count() -1).get_node("Button").grab_focus()
	if Loader.get_node("Can/Icon").is_playing():
		await Loader.get_node("Can/Icon").animation_finished


func _on_control_scheme(index):
	Global.confirm_sound()
	Global.Settings.ControlSchemeAuto = false
	Global.Settings.ControlSchemeEnum = %SettingsVbox/ControlScheme/MenuBar.get_selected_id()
	match Global.Settings.ControlSchemeEnum:
		0:
			Global.Settings.ControlSchemeAuto = true
		1:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/Keyboard.tres")
		2:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/Nintendo.tres")
		3:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/Xbox.tres")
		4:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/Generic.tres")
		5:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/PlayStation.tres")
		6:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/PlayStationOld.tres")
		7:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/SteamDeck.tres")
		8:
			Global.Settings.ControlSchemeOverride = preload("res://UI/Input/None.tres")
	Global.save_settings()
	load_settings()

func _on_fullscreen(tog: bool):
	if tog != Global.Settings.Fullscreen:
		Global.fullscreen(tog)
		Global.confirm_sound()
		await get_tree().create_timer(0.5).timeout
		load_settings()

func _on_quit():
	stage = "quit"
	var text: String
	if is_instance_valid(Global.Area):
		text = "Quit the game?\nYour progress will be saved."
		if cant_save:
			text = "Quit the game?\nYour progress cannot be saved right now, so it might be lost."
	else: text = "Quit the game?"
	var awnser = await Global.warning(text, "QUIT", ["Cancel", "Title Screen", "Quit Game"], Color.hex(0xe3936eff))
	match awnser:
		2:
			if not cant_save and is_instance_valid(Global.Area): 
				await Loader.save()
			Global.quit()
		1:
			if is_instance_valid(Global.Area): 
				Global.Area.queue_free()
				if not cant_save: await Loader.save()
			if get_tree().root.has_node("MainMenu"):
				get_tree().root.get_node("MainMenu").queue_free()
			if get_tree().root.has_node("Battle"):
				get_tree().root.get_node("Battle").queue_free()
			PartyUI.hide_all()
			close()
		0:
			main()
			$MainButtons/Quit.grab_focus()

func _on_master_volume(value:float):
	Global.Settings.MasterVolume = value/10
	if Global.Settings.MasterVolume == -30:
		Global.Settings.MasterVolume = -80
	AudioServer.set_bus_volume_db(0, Global.Settings.MasterVolume)
	$AudioTester.bus = "Master"
	if stage == "game_settings": $AudioTester.play()
	Global.save_settings()

func _on_EnvSFX_volume(value: float) -> void:
	Global.Settings.EnvSFXVolume = value/10
	if Global.Settings.EnvSFXVolume == -30:
		Global.Settings.EnvSFXVolume = -80
	AudioServer.set_bus_volume_db(2, Global.Settings.EnvSFXVolume)
	$AudioTester.bus = "EnvSFX"
	if stage == "game_settings": $AudioTester.play()
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
	if stage == "game_settings":
		Global.confirm_sound()

func cursor(i):
	if stage == "game_settings":
		Global.cursor_sound()
		load_settings()

func _on_brightness(value):
	World.environment.adjustment_brightness = max(value, 0.3)


func _on_contrast(value):
	World.environment.adjustment_contrast = max(value, 0.3)


func _on_saturation(value):
	World.environment.adjustment_saturation = value


func _on_auto_hide_hud(index: int) -> void:
	Global.Settings.AutoHideHUD = index
	Global.confirm_sound()

func _on_text_speed(index: int) -> void:
	Global.Settings.TextSpeed = index
	Global.confirm_sound()

func _show_image_test() -> void:
	#$ImageTester.show()
	$Fader.hide()
	%SettingsVbox/BCSadjust.show()

func _hide_image_test() -> void:
	$ImageTester.hide()
	$Fader.show()
	Event.wait(0.1, false)
	%SettingsVbox/AdjustImage.button_pressed = false
	_on_adjust_image(false)

func _on_adjust_image(toggle:bool) -> void:
	if toggle:
		%SettingsVbox/BCSadjust.show()
		%SettingsVbox/BCSadjust/BrtSlider.grab_focus()
		await Event.wait()
		Global.confirm_sound()
	else: %SettingsVbox/BCSadjust.hide()

func _debug_mode(toggled_on: bool) -> void:
	Global.Settings.DebugMode = toggled_on
	confirm()

func _fps(index: int) -> void:
	Global.Settings.FPS = %SettingsVbox/FPS/MenuBar.get_selected_id()
	confirm()

func _vsync(toggle: bool) -> void:
	Global.Settings.VSync = toggle
	Global.apply_settings()
	confirm()
	load_settings()

func _gloweffect(toggle: bool) -> void:
	Global.Settings.GlowEffect = toggle
	Global.apply_settings()
	confirm()
	load_settings()

func _new_game() -> void:
	was_controllable = false
	close(true)
	Global.new_game()

func _arena_mode() -> void:
	await Loader.save()
	Loader.load_game("ArenaMode", true, true)
	close()

func _on_credits() -> void:
	Global.confirm_sound()
	$GalleryPanel/Credits.grab_focus()
	$GalleryPanel/Credits.scroll_vertical = 0
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	t.tween_property($GalleryPanel,"position:x", 330, 0.3)
	t.tween_property($MainButtons/Gallery, "position:x", 74, 0.3)


func _on_highres_textures(toggle: bool) -> void:
	Global.Settings.HighResTextures = toggle
	Global.apply_settings()
	confirm()
	load_settings()


func _on_website() -> void:
	Global.confirm()
	OS.shell_open("https://raidev.eu")
	Global.toast("\"raidev.eu\" was opened in your web browser.")


func _manual_entry_pressed() -> void:
	stage = "manual"
	Global.confirm_sound()

func _manual_entry_select() -> void:
	if not is_instance_valid(focus): return
	var entry: String = focus.name
	var text: String = ""
	for i in Tutorials:
		if i.begins_with("#"+entry):
			text = i
			break
	if text == "":
		Global.toast("Entry not found")
		return
	text = text.replace("#"+entry, "[b]"+focus.text+"[/b]")
	$ManualPanel/Text/RichTextLabel.text = text


func _on_upscaledres(toggled_on: bool) -> void:
	Global.Settings.UpscaledRes = toggled_on
	confirm()
	load_settings()
	
func _on_reset() -> void:
	stage = "inactive"
	Global.confirm()
	if await Global.warning("This will erase autosave save data, and restore settings!
The game will then close.
You can backup this data by pressing F1 and copying the files.\nProceed?"):
		var dir:= DirAccess.open("user://")
		for file in dir.get_files():
			if not "File" in file:
				dir.remove(file)
		for file in dir.get_directories():
			DirAccess.remove_absolute("user://"+file)
		get_tree().quit(9)
	else:
		$GalleryPanel/ScrollContainer/VBoxContainer/ResetGame.grab_focus()
		stage = "gallery"
	
func _on_credit_scroll(event: InputEvent) -> void:
	if event.is_action("ui_up"):
		$GalleryPanel/Credits.scroll_vertical -= 1000
	if event.is_action("ui_down"):
		$GalleryPanel/Credits.scroll_vertical += 1000
	if event.is_action("ui_cancel") or event.is_action("ui_left"):
		$GalleryPanel/ScrollContainer/VBoxContainer/Credits.grab_focus()


func _on_controller_vibration(toggled_on: bool) -> void:
	Global.Settings.ControllerVibration = toggled_on
	confirm()
	load_settings()


func _blur_effect(toggled_on: bool) -> void:
	Global.Settings.BlurEffect = toggled_on
	confirm()
	load_settings()
