extends Control
#class_name Global.PartyUI

#@export var Global.Party: Global.PartyData = Global.Party
@export var Expanded: bool = false
@export var CursorPosition: Array[Vector2]
signal expand(i)
signal shrink
var held = false
var focus : int = 0
#t : Tween
var UIvisible = false
var Tempvis = true
var visibly=false
@onready var t :Tween
@onready var MainMenu = preload("res://UI/MainMenu/MainMenu.tscn")
var WasPaused = false
var MemberChoosing = false
@onready var Partybox = %Partybox
var disabled = true
var LevelupChain: Array[Actor] = []
var submenu_opened := false
var line_to_be_used: String

func _ready():
	$CanvasLayer.hide()
	$CanvasLayer/Fade.hide()
	await Event.wait()
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
			if UIvisible:
				show_all()
			else: hide_all()
		visibly = UIvisible
		if not Global.Controllable:
			$CanvasLayer/VirtualJoystick.hide()

func show_all():
	if disabled: return
	UIvisible = true
	visibly = true
	$CanvasLayer.show()
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	t.tween_property(Partybox.get_node("Leader"), "position:x", 0, 0.2)
	for i in range(1, 4):
		t.tween_property(Partybox.get_child(i), "position:x", -70, 0.2).set_delay(0.05)

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
	else:
		for i in range(0, 4):
			Partybox.get_child(i).position.x = -300

func _check_party():
	if Global.Party == null: return
	if Global.Party.Leader == null: Global.Party.Leader = Global.find_member(&"Mira")
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
	if (Input.is_action_just_pressed("Options") and Global.Player.get_node_or_null("%Base") != null
	and "Idle" in Global.Player.used_sprite.animation):
		Global.options()
	if Input.is_action_just_pressed(Global.cancel()):
		back()
	if Input.is_action_just_pressed("ui_accept") and MemberChoosing:
		_on_item_preview_pressed()

	##Debug shortcuts
	if Global.Settings.DebugMode:
		if Input.is_action_just_pressed("Debug"):
			Loader.travel_to("Debug", Vector2.ZERO, 0, -1, "")
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
	#print(open_ui)
	t.kill()
	Global.check_party.emit()
	UIvisible = true
	$CanvasLayer/Cursor.position=CursorPosition[0]
	if open_ui == 0: WasPaused = false
	else: WasPaused = get_tree().paused
	get_tree().paused = true
	Global.Controllable=false
	$CanvasLayer/Cursor/ItemPreview.hide()
	%Pages.show()
	#Pages
	for page in %Pages.get_children():
		page.rotation_degrees = randf_range(-2, 2)
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
		t = create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_BACK)
		t.set_parallel()
		t.tween_property($CanvasLayer/Back, "position:x", 20, 0.4)
		t.tween_property($CanvasLayer/Cursor/MemberOptions,
		"size:x", $CanvasLayer/Cursor/MemberOptions.size.x, 0.3).from(0)
		t.tween_property(Partybox, "scale", Vector2(1.5, 1.5), 0.4)
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
	#if mem != 0:
		#t.tween_property(Pan, "position:y", CursorPosition[mem].y - 60, 0.4)

func _on_shrink():
	t.kill()
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
	darken(false)
	if !UIvisible or disabled: hide_all(); return
	shrink_panel(Partybox.get_node("Leader"), 0)
	for i in range(1, 4):
		shrink_panel(Partybox.get_node("Member"+str(i)), i)
	Expanded = false
	await t.finished
	if not MemberChoosing: Global.Controllable= true
	MemberChoosing = false
	$CanvasLayer/Back.hide()
	%Pages.hide()

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
	"modulate", Color(1,1,1,0.5), 0.5)
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
			t.tween_property(Partybox.get_child(i), "position:x", 0 if i==0 else -60, 0.3)
		else: Partybox.get_child(i).hide()

func _on_battle_ui_root():
	battle_state()

func only_current():
	t = create_tween()
	t.set_parallel(true)
	for i in range(0, 4):
		if Global.Party.array()[i] == Global.Bt.CurrentChar:
			t.tween_property(Partybox.get_child(i), "position:x", 0 if i == 0 else -70, 0.2)
		else:
			t.tween_property(Partybox.get_child(i), "position:x", -400, 0.2)

func check_member(mem:Actor, node:Panel, ind):
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	node.get_node("Name").text = mem.FirstName
	var character_label = mem.FirstName
	get_node("%Pages/Page"+str(ind)+"/Label").add_theme_color_override("font_color", mem.MainColor)
	get_node("%Pages/Page"+str(ind)+"/Label").text = mem.FirstName + " " + mem.LastName
	if get_node("%Pages/Page"+str(ind)+"/Render").texture != mem.RenderArtwork:
		get_node("%Pages/Page"+str(ind)+"/Render").texture = mem.RenderArtwork
		var shadow = make_shadow(mem.RenderShadow)
		get_node("%Pages/Page"+str(ind)+"/Render/Shadow").texture = shadow
	get_node("%Pages/Page"+str(ind)+"/AuraDoodle").texture = mem.PartyPage
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
	check_for_levelups(mem, node)

func check_for_levelups(mem:Actor, node:Panel):
	if mem.SkillPointsFor.size() - 1 == mem.SkillLevel: return
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	if mem.SkillPoints < mem.SkillPointsFor[mem.SkillLevel]:
		t.tween_property(node.get_node("Level/ExpBar"), "value", mem.SkillPoints, 1)
	else:
		t.tween_property(node.get_node("Level/ExpBar"), "value", mem.SkillPointsFor[mem.SkillLevel], 1)
		await t.finished
		mem.SkillPoints -= mem.SkillPointsFor[mem.SkillLevel]
		t = create_tween()
		t.tween_property(node.get_node("Level/ExpBar"), "value", 0, 0.3)
		await t.finished
		LevelupChain.append(mem)
		mem.SkillLevel += 1
		node.get_node("Level/Number").text = str(mem.SkillLevel)
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
	node.get_node("Health/HpText").add_theme_color_override("font_color", mem.MainColor)
	node.get_node("Aura/ApText").add_theme_color_override("font_color", mem.SecondaryColor)
	var hbox:StyleBoxFlat = node.get_node("Health").get_theme_stylebox("fill")
	hbox.bg_color = mem.MainColor
	node.get_node("Health").add_theme_stylebox_override("fill", hbox.duplicate())
	var abox = node.get_node("Aura").get_theme_stylebox("fill")
	abox.bg_color = mem.SecondaryColor
	node.get_node("Aura").add_theme_stylebox_override("fill", abox.duplicate())
	var bord1:StyleBoxFlat = node.get_node("Border1").get_theme_stylebox("panel")
	bord1.border_color = mem.BoxProfile.Bord1
	node.get_node("Border1").add_theme_stylebox_override("panel", bord1.duplicate())
	var bord2:StyleBoxFlat = node.get_node("Border1/Border2").get_theme_stylebox("panel")
	bord2.border_color = mem.BoxProfile.Bord2
	node.get_node("Border1/Border2").add_theme_stylebox_override("panel", bord2.duplicate())
	var bord3:StyleBoxFlat = node.get_node("Border1/Border2/Border3").get_theme_stylebox("panel")
	bord3.border_color = mem.BoxProfile.Bord3
	node.get_node("Border1/Border2/Border3").add_theme_stylebox_override("panel", bord3.duplicate())

func choose_member():
	if Item.get_node("ItemEffect").item == null: return
	_on_expand(1)
	UIvisible = true
	t = create_tween()
	$CanvasLayer/Fade.show()
	$CanvasLayer/Cursor/ItemPreview.grab_focus()
	$CanvasLayer/Cursor/ItemPreview.show()
	$CanvasLayer/Back.show()
	$CanvasLayer/Cursor/ItemPreview.text = (Item.get_node("ItemEffect").item.Name + " x"
	+ str(Item.get_node("ItemEffect").item.Quantity))
	$CanvasLayer/Back.icon = Global.get_controller().CancelIcon
	t.tween_property($CanvasLayer/Back, "position:x", 20, 0.3)
	t.tween_property($CanvasLayer/Cursor, "modulate", Color(1,1,1,1), 0.4)
	t.tween_property($CanvasLayer/Fade/Blur.material, "shader_parameter/lod", 3, 0.4)
	t.tween_property($CanvasLayer/Fade, "color", Color(0, 0, 0, 0.5), 0.4)
	await Event.wait(0.3, false)
	MemberChoosing = true
	$/root/MainMenu.stage = "choose_member"

func _on_item_preview_pressed():
	if (Item.get_node("ItemEffect").item.Quantity != 0 and
	Global.Party.get_member(focus).Health != Global.Party.get_member(focus).MaxHP):
		Item.emit_signal("return_member", (Global.Party.get_member(focus)))
	else:
		if Item.get_node("ItemEffect").item.Quantity != 0: Global.toast("HP is already maxed out")
		Global.buzzer_sound()
	$CanvasLayer/Cursor/ItemPreview.text = (Item.get_node("ItemEffect").item.Name + " x"
	+ str(Item.get_node("ItemEffect").item.Quantity))

func confirm_time_passage(title: String, description: String, to_time: int, action_id: String):
	$CanvasLayer/CalendarBase.confirm_time_passage(title, description, to_time, action_id)

func cmd():
	if not $CanvasLayer/TextEdit.visible:
		print(Event.Flags)
		$CanvasLayer/TextEdit.show()
		$CanvasLayer/TextEdit.text = ""
		$CanvasLayer/TextEdit.grab_focus()
		Global.Controllable = false
	else:
		if "/day " in $CanvasLayer/TextEdit.text:
			$CanvasLayer/TextEdit.text.replace("/day ", "")
			Event.Day = int($CanvasLayer/TextEdit.text)
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
		Global.Controllable=false
		get_tree().paused = true
		get_tree().root.add_child(MainMenu.instantiate())

func cycle_states(chara: Actor, rect: TextureRect):
	if rect.texture != null and rect.visible: return
	var index:= 0
	rect.show()
	while not chara.States.is_empty():
		rect.texture = chara.States[index].icon
		await $StateTimer.timeout
		index += 1
		if index == chara.States.size(): index = 0
	rect.texture = null

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
	if dialog == null: Global.buzzer_sound(); return
	var key = "d"+str(Event.Day)+"_"+str(Event.flag_int(Global.Party.array()[focus].codename+"Talk"))
	if not key in dialog.get_titles(): key = "error"
	line_to_be_used = (await dialog.get_next_dialogue_line(key)).text
	submenu_opened = true
	await Global.textbox(Global.Party.array()[focus].codename.to_lower()+"_talk", "options", true)
	close_submenu()
