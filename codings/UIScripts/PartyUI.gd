extends Control
#class_name Global.PartyUI

#@export var Global.Party: Global.PartyData = Global.Party
@export var Expanded: bool = false
@export var CursorPosition: Array[Vector2]
signal expand(i)
signal shrink
var held = false
var focus : int = 0
var UIvisible = false
var Tempvis = true
var visibly=false
@onready var t :Tween
var WasPaused = false
var MemberChoosing = false
@onready var Partybox = %Partybox
var disabled = true
var LevelupChain: Array[Actor] = []
var submenu_opened := false
var line_to_be_used: String
var nametag_to_be_used: String
var was_controllable = false
var def_pos_partybox:Array[Vector2] = [Vector2.ONE, Vector2.ONE, Vector2.ONE, Vector2.ONE]

func _ready():
	$CanvasLayer.hide()
	$CanvasLayer/Fade.hide()
	$CanvasLayer/Cursor.hide()
	for i in range(1, 4):
		var page = %Pages/Page0.duplicate()
		page.name = "Page"+str(i)
		page.z_index = 3 - i
		%Pages.add_child(page)
	for i in range(2, 4):
		var box = %Partybox/Member1.duplicate()
		box.name = "Member"+str(i)
		Partybox.add_child(box)
	if not Loader.InBattle:
		UIvisible = true
		disabled = false
		shrink.emit()
	Global.check_party.connect(_check_party)
	Global.check_party.emit()

func _process(delta):
	if disabled: UIvisible = false
	if Expanded and not submenu_opened:
		handle_ui()
	if not Loader.InBattle:
		if UIvisible != visibly:
			if UIvisible and not Event.f("DisableMenus") and not disabled:
				show_all()
			else: hide_all()
		visibly = UIvisible
		if not Global.Controllable:
			$CanvasLayer/VirtualJoystick.hide()

		if is_instance_valid(Global.Player) and Global.Controllable and Global.Player.move_frames != 0:
			if Global.Settings.AutoHideHUD == 0:
				if $IdleTimer.time_left == 0:
					show_all()
				$IdleTimer.start(5)
			if Global.Settings.AutoHideHUD == 1:
				hide_all()
				$IdleTimer.start(3)

func show_all():
	if disabled: return
	UIvisible = true
	visibly = true
	#Partybox.queue_sort()
	$CanvasLayer.show()
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	t.tween_property(Partybox.get_node("Leader"), "position:x", 0, 0.2)
	if not Loader.InBattle:
		t.tween_property($CanvasLayer/CalendarBase, "position:y", 0, 0.3)
		$IdleTimer.start(5)
	for i in range(0, 4):
		if i != 0: t.tween_property(Partybox.get_child(i), "position:x", -70, 0.2).set_delay(0.05)
		if Loader.InBattle and def_pos_partybox[i] != Vector2.ONE:
			t.tween_property(Partybox.get_child(i), "position:y", def_pos_partybox[i].y, 0.2)

func hide_all(animate = true):
	UIvisible = false
	visibly = false
	if animate:
		t = create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUART)
		t.set_parallel()
		for i in range(0, 4):
			t.tween_property(Partybox.get_child(i), "position:x", -300, 0.3)
		t.tween_property($CanvasLayer/CalendarBase, "position:y", -150, 0.3)
	else:
		for i in range(0, 4):
			Partybox.get_child(i).position.x = -300

func _check_party():
	if not Global.Party: return
	if not Global.Party.Leader: Global.Party.Leader = Global.find_member(&"Mira")
	if Event.f("DisableMenus"): disabled = true
	Global.Party = Global.Party
	check_member(Global.Party.Leader, Partybox.get_node("Leader"), 0)
	for i in range(1, 4):
		if Global.Party.check_member(i):
			check_member(Global.Party.array()[i], Partybox.get_node("Member"+str(i)), i)
			Partybox.get_node("Member"+str(i)).show()
		else:
			Partybox.get_node("Member"+str(i)).hide()

func _input(ev):
	if Input.is_action_just_pressed("MainMenu"):
		main_menu()
	if (Input.is_action_just_pressed("Options") and (is_instance_valid(Global.Player) and Global.Player.get_node_or_null("%Base"))
	and "Idle" in Global.Player.used_sprite.animation):
		Global.options()
	if Input.is_action_just_pressed(Global.cancel()):
		back()
	#if Input.is_action_just_pressed("ui_accept") and MemberChoosing:
		#_on_item_preview_pressed()

	##Debug shortcuts
	if Global.Settings.DebugMode:
		if Input.is_action_just_pressed("Debug"):
			Loader.travel_to("Debug", Vector2.ZERO, 0, -1, "")
			Event.remove_flag("FlameActive")
		if Input.is_action_just_pressed("DebugT"):
			Global.passive("testbush", "greetings")
		if Input.is_action_just_pressed("DebugP"):
			Global.toast("Controllable set to " + str(!Global.Controllable))
			if Global.Controllable == true:
				Event.take_control()
			else: Event.give_control()
		if Input.is_action_just_pressed("DebugI"):
			Item.add_item("SmallPotion", "Con")
		if Input.is_action_just_pressed("DebugA"):
			Global.textbox("testbush", "add_to_party")
		if Input.is_action_just_pressed("DebugFlag"):
			cmd()
		if Input.is_action_just_pressed("Debug0"):
			if Engine.time_scale == 0.1: Engine.time_scale = 1
			else: Engine.time_scale = 0.1
		Global.check_party.emit()

func darken(toggle := true):
	t = create_tween()
	t.set_parallel()
	if toggle:
		$CanvasLayer/Fade.show()
		t.tween_property($CanvasLayer/Fade/Blur.material, "shader_parameter/lod", 3, 0.3)
		t.tween_property($CanvasLayer/Fade, "color", Color(0, 0, 0, 0.5), 0.3)
		await t.finished
	else:
		t.tween_property($CanvasLayer/Fade, "color", Color(0,0,0,0), 0.3)
		t.tween_property($CanvasLayer/Fade/Blur.material, "shader_parameter/lod", 0, 0.3)
		await t.finished
		if $CanvasLayer/Fade.color == Color.TRANSPARENT: $CanvasLayer/Fade.hide()

func _on_expand(open_ui=0):
	Global.check_party.emit()
	await Event.wait()
	if disabled: Global.buzzer_sound(); return
	t.kill()
	UIvisible = true
	$CanvasLayer/Cursor.position=CursorPosition[0]
	if open_ui == 0: WasPaused = false
	else: WasPaused = get_tree().paused
	was_controllable = Global.Controllable
	get_tree().paused = true
	Global.Controllable=false
	$CanvasLayer/Cursor/ItemPreview.hide()
	%Pages.show()
	#Pages
	for page in %Pages.get_children():
		page.rotation_degrees = randf_range(-2, 2)
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	t.set_parallel()
	t.tween_property(Partybox, "scale", Vector2(1.5, 1.5), 0.4)
	t.tween_property($CanvasLayer/CalendarBase, "position:y", -150, 0.3)
	if open_ui == 0:
		for i in range(0,4):
			if Global.check_member(i): get_node("%Pages/Page"+str(i)).show()
			else: get_node("%Pages/Page"+str(i)).hide()
		$CanvasLayer/Cursor/MemberOptions.show()
		$CanvasLayer/Cursor/MemberOptions/VBox/Details.icon = Global.get_controller().CommandIcon
		$CanvasLayer/Cursor/MemberOptions/VBox/Talk.icon = Global.get_controller().ConfirmIcon
		$CanvasLayer/Cursor/MemberOptions/VBox/Talk.hide()
		$CanvasLayer/Cursor/MemberOptions.size.y = 1
		$CanvasLayer/Fade.show()
		$CanvasLayer/Back.show()
		t.tween_property($CanvasLayer/Back, "position:x", 20, 0.4)
		t.tween_property($CanvasLayer/Cursor/MemberOptions,
		"size:x", $CanvasLayer/Cursor/MemberOptions.size.x, 0.3).from(0)
		$CanvasLayer/Back.icon = Global.get_controller().CancelIcon
	else:
		$CanvasLayer/Cursor/MemberOptions.hide()
		%Pages.hide()
	if open_ui < 2:
		t = create_tween()
		t.tween_property($CanvasLayer/Cursor, "modulate", Color(1,1,1,1), 0.2)
		darken()
	expand_panel(Partybox.get_node("Leader"))
	for i in range(1, 4):
		expand_panel(Partybox.get_node("Member"+str(i)), i)

	#Menu
	#if open_ui == 0:
	await t.finished
	Expanded = true
	Global.check_party.emit()
	if open_ui != 2: $CanvasLayer/Cursor.show()
	if open_ui == 0:
		focus_now()

func expand_panel(Pan:Panel, mem := 0):
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	#values if not leader
	var icon_pos = Vector2(37,50)
	var lv_pos = Vector2(140,80)
	var hp_pos = Vector2(75,41)
	var au_pos = Vector2(75,46)
	var nam_pos = Vector2(81, 14)
	#values if leader
	if mem == 0:
		icon_pos = Vector2(37,45)
		lv_pos = Vector2(140,70)
		hp_pos = Vector2(75,31)
		au_pos = Vector2(75,37)
		nam_pos = Vector2(82, 3)
	t.tween_property(Pan.get_node("Icon"), "scale", Vector2(0.09,0.09), 0.4)
	t.tween_property(Pan.get_node("Icon"), "position", icon_pos, 0.4)
	t.tween_property(Pan.get_node("Health"), "size", Vector2(110,20), 0.4)
	t.tween_property(Pan.get_node("Aura"), "size", Vector2(110,27), 0.4)
	Pan.get_node("Name").show()
	Pan.get_node("Level").show()
	Pan.get_node("Health/HpText").show()
	Pan.get_node("Aura/ApText").show()
	Pan.get_node("Level/ExpBar").show()
	t.tween_property(Pan.get_node("Level/ExpBar"), "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property(Pan.get_node("Name"), "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property(Pan.get_node("Name"), "position", nam_pos, 0.4)
	t.tween_property(Pan.get_node("Level"), "position", lv_pos, 0.4)
	t.tween_property(Pan.get_node("Health"), "position", hp_pos, 0.4)
	t.tween_property(Pan.get_node("Aura"), "position", au_pos, 0.4)
	t.tween_property(Pan.get_node("Health/HpText"), "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property(Pan.get_node("Aura/ApText"), "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property(Pan.get_node("Health/HpText"), "position", Vector2(115, 1), 0.4)
	t.tween_property(Pan.get_node("Aura/ApText"), "position", Vector2(115, 12), 0.4)
	t.tween_property(Pan, "position:x", 0, 0.4)
	await t.finished
	Partybox.queue_sort()
	#if mem != 0:
		#t.tween_property(Pan, "position:y", CursorPosition[mem].y - 60, 0.4)

func _on_shrink():
	Partybox.show()
	Global.check_party.emit()
	t = create_tween()
	t.set_parallel(true)
	get_tree().paused = WasPaused
	t.set_ease(Tween.EASE_OUT)
	focus=0
	t.set_trans(Tween.TRANS_BACK)
	#Pages
	#$CanvasLayer/Cursor.position=CursorPosition[0]
	for i in %Pages.get_children():
		t.tween_property(i, "position", Vector2(1300,44), 0.3)
	t.tween_property(%Pages/Page0/Render, "position", Vector2(179,44), 0.6)
	t.tween_property($CanvasLayer/Back, "position:x", -150, 0.3)
	t.tween_property($CanvasLayer/Cursor, "modulate", Color(0,0,0,0), 0.4)
	t.tween_property(Partybox, "scale", Vector2(1,1), 0.4)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property($CanvasLayer/CalendarBase, "position:y", 0, 0.3)
	darken(false)
	if !UIvisible or disabled: hide_all(); return
	shrink_panel(Partybox.get_node("Leader"), 0)
	for i in range(1, 4):
		shrink_panel(Partybox.get_node("Member"+str(i)), i)
	for i in %Pages.get_children():
		i.get_node("Render").texture = null
	Expanded = false
	await t.finished
	MemberChoosing = false
	$CanvasLayer/Back.hide()
	%Pages.hide()
	$IdleTimer.start(5)

func shrink_panel(Pan:Panel, mem = 0,):
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	#values if not leader
	var icon_pos = Vector2(114,54)
	var lv_pos = Vector2(160,76)
	var hp_pos = Vector2(159,30)
	var au_pos = Vector2(159,43)
	var bar_size = Vector2(54,22)
	var nam_pos = Vector2(150, 14)
	#values if leader
	if mem == 0:
		icon_pos = Vector2(44,44)
		lv_pos = Vector2(90,64)
		hp_pos = Vector2(86,16)
		au_pos = Vector2(86,30)
		bar_size = Vector2(124,22)
		nam_pos = Vector2(82, 3)
	t.tween_property(Pan.get_node("Icon"), "scale", Vector2(0.09,0.09), 0.4)
	t.tween_property(Pan.get_node("Icon"), "position", icon_pos, 0.4)
	t.tween_property(Pan.get_node("Health"), "size", bar_size, 0.4)
	t.tween_property(Pan.get_node("Aura"), "size", bar_size, 0.4)
	Pan.get_node("Name").show()
	Pan.get_node("Level").show()
	Pan.get_node("Health/HpText").show()
	Pan.get_node("Aura/ApText").show()
	t.tween_property(Pan.get_node("Level/ExpBar"), "modulate", Color.TRANSPARENT, 0.4)
	t.tween_property(Pan.get_node("Name"), "modulate", Color.TRANSPARENT, 0.4)
	t.tween_property(Pan.get_node("Name"), "position", nam_pos, 0.4)
	t.tween_property(Pan.get_node("Level"), "position", lv_pos, 0.4)
	t.tween_property(Pan.get_node("Health"), "position", hp_pos, 0.4)
	t.tween_property(Pan.get_node("Aura"), "position", au_pos, 0.4)
	t.tween_property(Pan.get_node("Health/HpText"), "modulate", Color.TRANSPARENT, 0.4)
	t.tween_property(Pan.get_node("Aura/ApText"), "modulate", Color.TRANSPARENT, 0.4)
	if mem != 0 and UIvisible:
		t.tween_property(Pan, "position:x", -70, 0.4)
		#t.tween_property(Pan, "position:y", CursorPosition[mem].y - 120, 0.4)

func handle_ui():
	if disabled or !UIvisible: Expanded = false; return
	if Input.is_action_just_pressed("ui_down"):
		if Global.Party.check_member(focus+1):
			focus += 1
			Global.cursor_sound()
			focus_now()
			if not MemberChoosing:
				$Audio.stream = preload("res://sound/SFX/UI/page.ogg")
			$Audio.play()
		else:
			Global.buzzer_sound()
	if Input.is_action_just_pressed("ui_up"):
		if focus-1 != -1:
			focus -= 1
			Global.cursor_sound()
			focus_now()
			if not MemberChoosing:
				$Audio.stream = preload("res://sound/SFX/UI/Page2.ogg")
			$Audio.play()
		else:
			Global.buzzer_sound()

func focus_now():
	t.kill()
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property($CanvasLayer/Cursor, "position", CursorPosition[focus], 0.1)
	#await get_tree().create_timer(0.3).timeout
	if MemberChoosing: return
	if focus == 0: $CanvasLayer/Cursor/MemberOptions/VBox/Talk.hide()
	else: $CanvasLayer/Cursor/MemberOptions/VBox/Talk.show()
	$CanvasLayer/Cursor/MemberOptions.size.y = 1
	for i in range(0, focus):
		t.tween_property(get_node("%Pages/Page"+str(i)),
		"position", Vector2(1300, 44), 0.4+i/10)
		t.tween_property(get_node("%Pages/Page"+str(i)+"/Render/Shadow"),
		"modulate", Color.TRANSPARENT, 0.5)
		t.tween_property(get_node("%Pages/Page"+str(i)+"/Render"),
		"position", Vector2(-15, 0), 0.3)
		t.tween_property(get_node("%Pages/Page"+str(i)+"/Render/Shadow"),
		"position", Vector2(100,0), 0.5)
	t.tween_property(get_node("%Pages/Page"+str(focus)),
	"position", Vector2(634, 44), 0.5)
	t.tween_property(get_node("%Pages/Page"+str(focus)+"/Render"),
	"position", Vector2(150, 130), 0.5)
	t.tween_property(get_node("%Pages/Page"+str(focus)+"/Render/Shadow"),
	"modulate", Color(1,1,1,0.8), 0.5)
	t.tween_property(get_node("%Pages/Page"+str(focus)+"/Render/Shadow"),
	"position", Vector2(-35,143), 0.5)
	for i in range(focus+1, 4):
		t.tween_property(get_node("%Pages/Page"+str(i)),
		"position", Vector2(634, 44), 0.3+i/10)
		t.tween_property(get_node("%Pages/Page"+str(i)+"/Render"),
		"position", Vector2(-15, 0), 0.3)
		t.tween_property(get_node("%Pages/Page"+str(i)+"/Render/Shadow"),
		"modulate", Color.TRANSPARENT, 0.5)
		t.tween_property(get_node("%Pages/Page"+str(i)+"/Render/Shadow"),
		"position", Vector2(100,0), 0.5)

func battle_state(from:= false):
	if not Loader.InBattle: $CanvasLayer.hide(); return
	$CanvasLayer/Cursor.hide()
	visibly=true
	Partybox.scale = Vector2(1.25, 1.25)
	if from: hide_all()
	for i in range(0, 4):
		if Global.check_member(i):
			Partybox.get_child(i).get_node("Name").show()
			Partybox.get_child(i).get_node("Level").show()
			Partybox.get_child(i).get_node("Icon").scale = Vector2(0.09, 0.09)
			Partybox.get_child(i).get_node("Icon").position = Vector2(37,45) if i==0 else Vector2(97,52)
			Partybox.get_child(i).get_node("Health").size = Vector2(110 if i==0 else 60,20)
			Partybox.get_child(i).get_node("Health").position = Vector2(75,31) if i==0 else Vector2(135,40)
			Partybox.get_child(i).get_node("Aura").size = Vector2(110 if i==0 else 60,27)
			Partybox.get_child(i).get_node("Aura").position = Vector2(75,37) if i==0 else Vector2(135,43)
			Partybox.get_child(i).get_node("Health/HpText").modulate = Color.WHITE
			Partybox.get_child(i).get_node("Level/ExpBar").modulate = Color.WHITE if i==0 else Color.TRANSPARENT
			Partybox.get_child(i).get_node("Name").modulate = Color.WHITE
			Partybox.get_child(i).get_node("Aura/ApText").modulate = Color.WHITE
			Partybox.get_child(i).get_node("Level").position = Vector2(140,70) if i==0 else Vector2(140,78)
			if i != 0:
				Partybox.get_child(i).size.y = 100
				Partybox.get_child(i).get_node("Name").position.x = 140
				Partybox.get_child(i).get_node("Health/HpText").position.x = 64
				Partybox.get_child(i).get_node("Aura/ApText").position.x = 64
			t = create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUART)
			t.set_parallel()
			t.tween_property(Partybox.get_child(i), "position:x", 0 if i==0 else -60, 0.3)
		else: Partybox.get_child(i).hide()
	for i in range(0, 4):
		if def_pos_partybox[i] != Vector2.ONE:
			t.tween_property(Partybox.get_child(i), "position:y", def_pos_partybox[i].y, 0.2)

func save_box_positions():
	for i in range(1, 4): def_pos_partybox[i] = Partybox.get_child(i).position

func _on_battle_ui_root():
	battle_state()

func only_current():
	t = create_tween()
	t.set_parallel(true)
	for i in range(0, 4):
		if Global.Party.array()[i] == Global.Bt.CurrentChar:
			t.tween_property(Partybox.get_child(i), "position:x", 0 if i == 0 else -70, 0.2)
			if Global.Bt.CurrentChar != Global.Party.Leader:
				t.tween_property(Partybox.get_child(i), "position:y", 20, 0.2)
		else:
			t.tween_property(Partybox.get_child(i), "position:x", -400, 0.2)

func check_member(mem:Actor, node:Panel, ind):
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	node.get_node("Name").text = mem.FirstName
	var character_label = mem.FirstName
	var txt_color = mem.MainColor
	txt_color.v = min(txt_color.v, 0.75)
	get_node("%Pages/Page"+str(ind)+"/Label").add_theme_color_override("font_color", txt_color)
	get_node("%Pages/Page"+str(ind)+"/Label").text = mem.FirstName + " " + mem.LastName
	t.tween_property(node.get_node("Health"), "value", mem.Health, 1)
	node.get_node("Health").max_value = mem.MaxHP
	draw_bar(mem, node)
	node.get_node("Aura").max_value = mem.MaxAura
	node.get_node("Level/ExpBar").max_value = mem.SkillPointsFor[mem.SkillLevel]
	t.tween_property(node.get_node("Aura"), "value", mem.Aura, 1)
	node.get_node("Icon").texture = mem.PartyIcon
	cycle_states(mem, node.get_node("Icon/State"))
	node.get_node("Health/HpText").text = str(mem.Health)
	node.get_node("Aura/ApText").text = str(mem.Aura)
	node.get_node("Level/Number").text = str(mem.SkillLevel)
	if Expanded:
		if get_node("%Pages/Page"+str(ind)+"/Render").texture == null:
			get_node("%Pages/Page"+str(ind)+"/Render").texture = await mem.RenderArtwork()
		if get_node("%Pages/Page"+str(ind)+"/Render/Shadow").texture == null:
			get_node("%Pages/Page"+str(ind)+"/Render/Shadow").texture = await mem.RenderShadow()
		if get_node("%Pages/Page"+str(ind)+"/AuraDoodle").texture == null:
			get_node("%Pages/Page"+str(ind)+"/AuraDoodle").texture = await mem.PartyPage()
	await check_for_levelups(mem, node)

func check_for_levelups(mem:Actor, node:Panel):
	if mem.SkillPointsFor.size() - 1 == mem.SkillLevel: return
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	if mem.SkillLevel < mem.SkillPointsFor.size() and mem.SkillPoints < mem.SkillPointsFor[mem.SkillLevel]:
		t.tween_property(node.get_node("Level/ExpBar"), "value", mem.SkillPoints, 1)
	else:
		t.tween_property(node.get_node("Level/ExpBar"), "value", mem.SkillPointsFor[mem.SkillLevel], 1)
		LevelupChain.append(mem)
		await t.finished
		mem.SkillPoints -= mem.SkillPointsFor[mem.SkillLevel]
		mem.SkillPoints = max(mem.SkillPoints, 0)
		t = create_tween()
		t.tween_property(node.get_node("Level/ExpBar"), "value", 0, 0.3)
		await t.finished
		mem.SkillLevel += 1
		print(mem.FirstName + " grows to level ", mem.SkillLevel, ", ", mem.SkillPoints, "SP remain")
		node.get_node("Level/Number").text = str(mem.SkillLevel)
		if mem.SkillLevel < mem.SkillPointsFor.size():
			node.get_node("Level/ExpBar").max_value = mem.SkillPointsFor[mem.SkillLevel]
		check_for_levelups(mem, node)

func make_shadow(texture: Texture2D) -> Texture2D:
	var old_image := texture.get_image() #// Gets the image from the old texture.
	var old_size := old_image.get_size() #// Gets the size of the image as a Vector2i
	var image = old_image.duplicate()
	#// Gets a new image, identical to the old one.
	#// Resizes the image, to one fifth of the original. Tweak this a lot depending on use, obviously.
	image.resize(old_size.x / 20, old_size.y / 20)
	#// We make a new ImageTexture (similar to any other StandardTexture2D) from our image and...
	var new_texture = ImageTexture.create_from_image(image)
	return new_texture #// Set it as out texture.


func draw_bar(mem:Actor, node: Panel):
	node.get_node("Health/HpText").add_theme_color_override("font_color", mem.AuraDefault if mem.has_state("AuraOverwrite") else mem.MainColor )
	node.get_node("Aura/ApText").add_theme_color_override("font_color", mem.SecondaryColor)
	var hbox:StyleBoxFlat = node.get_node("Health").get_theme_stylebox("fill")
	hbox.bg_color = mem.AuraDefault if mem.has_state("AuraOverwrite") else mem.MainColor
	node.get_node("Health").add_theme_stylebox_override("fill", hbox.duplicate())
	var abox = node.get_node("Aura").get_theme_stylebox("fill")
	abox.bg_color = mem.SecondaryColor
	node.get_node("Aura").add_theme_stylebox_override("fill", abox.duplicate())
	var bord1:StyleBoxFlat = node.get_node("Border1").get_theme_stylebox("panel")
	bord1.border_color = mem.MainColor
	node.get_node("Border1").add_theme_stylebox_override("panel", bord1.duplicate())
	var bord2:StyleBoxFlat = node.get_node("Border1/Border2").get_theme_stylebox("panel")
	bord2.border_color = mem.BoxProfile.Bord2
	node.get_node("Border1/Border2").add_theme_stylebox_override("panel", bord2.duplicate())
	var bord3:StyleBoxFlat = node.get_node("Border1/Border2/Border3").get_theme_stylebox("panel")
	bord3.border_color = mem.BoxProfile.Bord3
	node.get_node("Border1/Border2/Border3").add_theme_stylebox_override("panel", bord3.duplicate())

func choose_member():
	if not Item.get_node("ItemEffect").item: return
	_on_expand(1)
	UIvisible = true
	t = create_tween()
	$CanvasLayer/Fade.show()
	$CanvasLayer/Back.show()
	$CanvasLayer/Cursor/ItemPreview.text = (Item.get_node("ItemEffect").item.Name
	+ " x" + str(Item.get_node("ItemEffect").item.Quantity))
	$CanvasLayer/Cursor/ItemPreview.icon = Item.get_node("ItemEffect").item.Icon
	$CanvasLayer/Back.icon = Global.get_controller().CancelIcon
	t.tween_property($CanvasLayer/Back, "position:x", 20, 0.3)
	t.tween_property($CanvasLayer/Cursor, "modulate", Color(1,1,1,1), 0.4)
	t.tween_property($CanvasLayer/Fade/Blur.material, "shader_parameter/lod", 3, 0.4)
	t.tween_property($CanvasLayer/Fade, "color", Color(0, 0, 0, 0.5), 0.4)
	await Event.wait(0.3, false)
	MemberChoosing = true
	$/root/MainMenu.stage = "choose_member"
	$CanvasLayer/Cursor/ItemPreview.show()
	$CanvasLayer/Cursor/ItemPreview.grab_focus()

func _on_item_preview_pressed():
	if (Item.get_node("ItemEffect").item.Quantity != 0 and
	Global.Party.get_member(focus).Health != Global.Party.get_member(focus).MaxHP):
		Item.emit_signal("return_member", (Global.Party.get_member(focus)))
	else:
		if Item.get_node("ItemEffect").item.Quantity != 0: Global.toast("HP is already maxed out")
		Global.buzzer_sound()
	$CanvasLayer/Cursor/ItemPreview.text = (Item.get_node("ItemEffect").item.Name + " x"
	+ str(Item.get_node("ItemEffect").item.Quantity))

func confirm_time_passage(title: String, description: String, to_time: Event.TOD = Event.ToTime) -> bool:
	return await $CanvasLayer/CalendarBase.confirm_time_passage(title, description, to_time)

func cmd():
	Event.f("DisableMenus", false)
	PartyUI.disabled = false
	show_all()
	if not $CanvasLayer/TextEdit.visible:
		print(Event.Flags)
		$CanvasLayer/TextEdit.show()
		$CanvasLayer/TextEdit.text = ""
		$CanvasLayer/TextEdit.grab_focus()
		Global.Controllable = false
	else:
		if "/clear" in $CanvasLayer/TextEdit.text:
			Event.Flags.clear()
			Loader.Defeated.clear()
		elif "/cam" in $CanvasLayer/TextEdit.text:
			Global.Player.camera_follow()
		elif "/day " in $CanvasLayer/TextEdit.text:
			$CanvasLayer/TextEdit.text.replace("/day ", "")
			Event.Day = int($CanvasLayer/TextEdit.text)
		elif "/time " in $CanvasLayer/TextEdit.text:
			$CanvasLayer/TextEdit.text.replace("/time ", "")
			Event.TimeOfDay = $CanvasLayer/TextEdit.text as Event.TOD
		elif "/enrestore" in $CanvasLayer/TextEdit.text:
			Loader.Defeated.clear()
		elif $CanvasLayer/TextEdit.text != "":
			$CanvasLayer/TextEdit.text.replace("/", "")
			Event.f($CanvasLayer/TextEdit.text, Global.toggle(Event.f($CanvasLayer/TextEdit.text)))
			Global.toast("Flag \"" + $CanvasLayer/TextEdit.text + "\" set to "
			+ str(Event.f($CanvasLayer/TextEdit.text)))
		$CanvasLayer/TextEdit.hide()
		Global.Controllable = true

func party_menu():
	if Loader.InBattle == false and not Global.Player.dashing and not MemberChoosing and Global.Controllable:
		if disabled:
			Global.buzzer_sound()
			return
		if Expanded == true:
			Tempvis=true
			$Audio.stream = preload("res://sound/SFX/UI/shrink.ogg")
			$Audio.play()
			shrink.emit()
			Global.cancel_sound()
		elif Global.Controllable:
			expand.emit()
			$Audio.stream = preload("res://sound/SFX/UI/expand.ogg")
			$Audio.play()
			Global.confirm_sound()

func main_menu():
	if not Loader.InBattle and Global.Controllable and not Global.Player.dashing:
		Global.Controllable = false
		get_tree().paused = true
		Global.Player.bag_anim()
		Global.ui_sound("Menu")
		get_tree().root.add_child((await Loader.load_res("res://UI/MainMenu/MainMenu.tscn")).instantiate())

func cycle_states(chara: Actor, rect: TextureRect, reclude:= true):
	if chara.States.is_empty(): rect.texture = null
	elif chara.States.size() == 1: rect.texture = chara.States[0].icon
	else:
		var index:= wrapi($StateTimer.time_left, 0,  chara.States.size())
		rect.texture = chara.States[index].icon
		while chara.States.size() > 1 and reclude:
			cycle_states(chara, rect, false)
			await Event.wait(0.3, false)
	rect.show()

func details():
	if Expanded and not submenu_opened:
		Global.member_details(Global.Party.array()[focus])
		submenu_opened = true
		await Event.wait(0.3, false)
		%Pages.hide()
		$CanvasLayer/Cursor.hide()
		$CanvasLayer/Back.hide()
		Partybox.hide()

func back():
	if not MemberChoosing and Expanded:
		if not submenu_opened:
			$Audio.stream = preload("res://sound/SFX/UI/shrink.ogg")
			$Audio.play()
			shrink.emit()
			Global.cancel_sound()
			await Event.wait(0.1)
			Global.Controllable= was_controllable

func close_submenu():
	Partybox.show()
	$CanvasLayer/Back.show()
	%Pages.show()
	$CanvasLayer/Cursor.show()
	submenu_opened = false

func talk() -> void:
	if submenu_opened or not Expanded: return
	var dialog: DialogueResource
	dialog = load("res://database/Text/" + Global.Party.array()[focus].codename.to_lower()+"_talk.dialogue")
	if not dialog: Global.buzzer_sound(); return
	var key = "d"+str(Event.Day)+"_"+str(Event.flag_int(Global.Party.array()[focus].codename+"Talk"))
	if not key in dialog.get_titles(): key = "error"
	line_to_be_used = (await dialog.get_next_dialogue_line(key)).text
	nametag_to_be_used = (await dialog.get_next_dialogue_line(key)).character
	submenu_opened = true
	await Global.textbox(Global.Party.array()[focus].codename.to_lower()+"_talk", "options", true)
	close_submenu()

func preform_levelups():
	var scene = (await Loader.load_res("res://UI/LevelUp/Levelup.tscn")).instantiate()
	await Event.wait()
	get_tree().root.add_child(scene)
	for i in LevelupChain:
		if Global.Bt: Loader.hide_victory_stuff()
		scene.get_node("Levelup").levelup(i)
		await scene.get_node("Levelup").closed
	LevelupChain.clear()
	t.kill()
	scene.queue_free()

func _on_idle_timer_timeout() -> void:
	if Global.Controllable:
		if Global.Settings.AutoHideHUD == 0:
			hide_all()
		if Global.Settings.AutoHideHUD == 1:
			show_all()

func hit_partybox(x: int, am: int, rep: int):
	print(am, " ",rep)
	Global.node_shake(%Partybox.get_child(x), am, rep)
