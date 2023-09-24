extends Control
#class_name PartyUI

@export var Party: PartyData = Global.Party
@export var Expanded: bool = false
@export var CursorPosition: Array[Vector2]
signal expand
signal shrink
var held = false
var focus : int = 0
#t : Tween
var UIvisible = true
var Tempvis = true
var visibly=false
@onready var t :Tween
@onready var MainMenu = preload("res://UI/MainMenu/MainMenu.tscn")
var WasPaused = false
var MemberChoosing = false

func _ready():
	$CanvasLayer.hide()
	$CanvasLayer/Fade.hide()
	_check_party()
	await get_tree().create_timer(0.00001).timeout
	if not Loader.InBattle:
		_on_shrink()
		UIvisible = true
#	else:
#		battle_state()


func _process(delta):
	#print(Loader.InBattle)
	if Expanded:
		handle_ui()
#	if Loader.InBattle and get_parent() is Control:
#		if get_parent().Action:
#			_check_party()
#	pass
	if not Loader.InBattle:
#		if Expanded and $CanvasLayer/Leader.scale.x==1:
#			_on_expand()
#		elif (not Expanded) and $CanvasLayer/Leader.scale.x==1.5:
#			_on_shrink()
		if UIvisible and $CanvasLayer.visible==false:
			$CanvasLayer.show()
			_check_party()
			t = create_tween()
			t.set_parallel(true)
			if Expanded:
				t.tween_property($CanvasLayer/Leader, "position:x", 0, 0.2)
				t.tween_property($CanvasLayer/Member1, "position:x", 0, 0.2)
			else:
				t.tween_property($CanvasLayer/Leader, "position", Vector2(0,$CanvasLayer/Leader.position.y), 0.2)
				t.tween_property($CanvasLayer/Member1, "position", Vector2(-70,$CanvasLayer/Member1.position.y), 0.2)
			visibly=true
		elif  UIvisible==false and visibly:
			visibly=false
			t = create_tween()
			t.set_parallel(true)
			t.tween_property($CanvasLayer/Leader, "position", Vector2(-300,$CanvasLayer/Leader.position.y), 0.2)
			t.tween_property($CanvasLayer/Member1, "position", Vector2(-300,$CanvasLayer/Member1.position.y), 0.2)
			await t.finished
			$CanvasLayer.hide()

func _check_party():
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	#Leader
	check_member(Party.Leader, $CanvasLayer/Leader, 0)
	#Member 1
	if Party.check_member(1):
		check_member(Party.Member1, $CanvasLayer/Member1, 1)
	else:
		$CanvasLayer/Member1.hide()

func _input(ev):
	if Input.is_action_just_pressed("MainMenu") and not Loader.InBattle and Global.Controllable and not Global.Player.dashing:
		Global.Controllable=false
		get_tree().paused = true
#		Loader.load_text("res://UI/MainMenu/MainMenu.tscn")
#		await Loader.text_loaded
#		get_parent().get_node("Body").add_child((ResourceLoader.load_threaded_get("res://UI/MainMenu/MainMenu.tscn").instantiate()))
		Global.Player.add_child(MainMenu.instantiate())
	if Input.is_action_just_pressed("Debug"):
		Loader.travel_to("Debug")
	if Input.is_action_just_pressed("DebugT"):
		DialogueManager.passive("testbush", "greetings")
	if Input.is_action_just_pressed("DebugP"):
		Global.Controllable = Global.toggle(Global.Controllable)
	if Input.is_action_just_pressed("DebugI"):
		Item.add_consumable("SmallPotion")
	if Input.is_action_just_pressed("PartyMenu") and Loader.InBattle == false and not Global.Player.dashing and not MemberChoosing:
			if Expanded == true:
				Tempvis=true
				$Audio.stream = preload("res://sound/SFX/UI/shrink.ogg")
				$Audio.play()
				_on_shrink()
				Global.cancel_sound()
			elif Global.Controllable:
				_on_expand()
				$Audio.stream = preload("res://sound/SFX/UI/expand.ogg")
				$Audio.play()
				Global.confirm_sound()
	if Input.is_action_pressed(Global.cancel()) and Expanded:
		$Audio.stream = preload("res://sound/SFX/UI/shrink.ogg")
		$Audio.play()
		_on_shrink()
		Global.cancel_sound()
	if Input.is_action_pressed("ui_accept") and MemberChoosing:
		_on_item_preview_pressed()

func _on_expand(open_ui=0):
	print(open_ui)
	t.kill()
	_check_party()
	if open_ui == 0: WasPaused = false
	else: WasPaused = get_tree().paused
	get_tree().paused = true
	Global.Controllable=false
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	$CanvasLayer/Cursor/ItemPreview.hide()
	#Pages
	if open_ui == 0:
		$CanvasLayer/Page1.show()
		if Party.check_member(1):
			$CanvasLayer/Page2.show()
		else:
			$CanvasLayer/Page2.hide()
		if Party.check_member(2):
			$CanvasLayer/Page3.show()
		else:
			$CanvasLayer/Page3.hide()
		if Party.check_member(3):
			$CanvasLayer/Page4.show()
		else:
			$CanvasLayer/Page4.hide()
		$CanvasLayer/Fade.show()
	else:
		$CanvasLayer/Page1.hide()
		$CanvasLayer/Page2.hide()
		$CanvasLayer/Page3.hide()
		$CanvasLayer/Page4.hide()
	if open_ui < 2:
		t.tween_property($CanvasLayer/Cursor, "modulate", Color(1,1,1,1), 0.4)
		t.tween_property($CanvasLayer/Fade/Blur.material, "shader_parameter/lod", 3, 0.4)
		t.tween_property($CanvasLayer/Fade, "color", Color(0, 0, 0, 0.5), 0.4)
	#Leader
	t.tween_property($CanvasLayer/Leader, "scale", Vector2(1.5,1.5), 0.4)
	t.tween_property($CanvasLayer/Leader/Icon, "scale", Vector2(0.044,0.044), 0.4)
	t.tween_property($CanvasLayer/Leader/Icon, "position", Vector2(37,45), 0.4)
	$CanvasLayer/Leader/Health.size = Vector2(110,20)
	t.tween_property($CanvasLayer/Leader/Health, "position", Vector2(75,31), 0.4)
	$CanvasLayer/Leader/Aura.size = Vector2(110,27)
	t.tween_property($CanvasLayer/Leader/Aura, "position", Vector2(75,37), 0.4)
	$CanvasLayer/Leader/Name.show()
	$CanvasLayer/Leader/Level.show()
	$CanvasLayer/Member1/ExpBar.show()
	t.tween_property($CanvasLayer/Leader/Health/HpText, "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property($CanvasLayer/Leader/ExpBar, "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property($CanvasLayer/Leader/Name, "modulate", Color(1, 1, 1, 1), 0.4)
	$CanvasLayer/Member1/Name.position = Vector2(81,14)
	t.tween_property($CanvasLayer/Leader/Aura/AruaText, "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property($CanvasLayer/Leader/Level, "position", Vector2(140,70), 0.4)
	
	#Member1
	t.tween_property($CanvasLayer/Member1, "position", Vector2(0,189), 0.4)
	t.tween_property($CanvasLayer/Member1, "scale", Vector2(1.5,1.5), 0.4)
	t.tween_property($CanvasLayer/Member1/Icon, "scale", Vector2(0.044,0.044), 0.4)
	t.tween_property($CanvasLayer/Member1/Icon, "position", Vector2(37,50), 0.4)
	t.tween_property($CanvasLayer/Member1/Health, "size", Vector2(110,20), 0.4)
	t.tween_property($CanvasLayer/Member1/Health, "position", Vector2(75,41), 0.4)
	t.tween_property($CanvasLayer/Member1/Aura, "size", Vector2(110,27), 0.4)
	t.tween_property($CanvasLayer/Member1/Aura, "position", Vector2(75,46), 0.4)
	$CanvasLayer/Member1/Name.show()
	$CanvasLayer/Member1/Level.show()
	$CanvasLayer/Member1/Health/HpText.show()
	$CanvasLayer/Member1/Aura/AruaText.show()
	t.tween_property($CanvasLayer/Member1/Health/HpText, "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property($CanvasLayer/Member1/Health/HpText, "position", Vector2(117,0), 0.4)
	t.tween_property($CanvasLayer/Member1/Aura/AruaText, "position", Vector2(117,10), 0.4)
	t.tween_property($CanvasLayer/Member1/ExpBar, "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property($CanvasLayer/Member1/Name, "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property($CanvasLayer/Member1/Aura/AruaText, "modulate", Color(1, 1, 1, 1), 0.4)
	t.tween_property($CanvasLayer/Member1/Level, "position", Vector2(140,80), 0.4)
	
	#Menu
	#if open_ui == 0: 
	Expanded = true
	await t.finished
	$CanvasLayer/Cursor.show()
	if open_ui == 0:
		focus_now()

func _on_shrink():
	t.kill()
	_check_party()
	t = create_tween()
	t.set_parallel(true)
	get_tree().paused = WasPaused
	MemberChoosing = false
	Global.Controllable= true
	t.set_ease(Tween.EASE_OUT)
	focus=0
	t.set_trans(Tween.TRANS_BACK)
	#Pages
	$CanvasLayer/Cursor.position=CursorPosition[0]
	t.tween_property($CanvasLayer/Page1, "position", Vector2(1300,44), 0.3)
	t.tween_property($CanvasLayer/Page2, "position", Vector2(1300,44), 0.3)
	t.tween_property($CanvasLayer/Page3, "position", Vector2(1366,44), 0.3)
	t.tween_property($CanvasLayer/Page4, "position", Vector2(1366,44), 0.3)
	t.tween_property($CanvasLayer/Page1/Render, "position", Vector2(179,44), 0.6)
	
	#Leader
	
	t.tween_property($CanvasLayer/Cursor, "modulate", Color(0,0,0,0), 0.4)
	t.tween_property($CanvasLayer/Fade, "color", Color(0,0,0,0), 0.4)
	t.tween_property($CanvasLayer/Fade/Blur.material, "shader_parameter/lod", 0, 0.4)
	t.tween_property($CanvasLayer/Leader, "scale", Vector2(1,1), 0.4)
	t.tween_property($CanvasLayer/Leader/Icon, "scale", Vector2(0.05,0.05), 0.4)
	t.tween_property($CanvasLayer/Leader/Icon, "position", Vector2(44,44), 0.4)
	$CanvasLayer/Leader/Health.size = Vector2(124,22)
	t.tween_property($CanvasLayer/Leader/Health, "position", Vector2(89,16), 0.4)
	$CanvasLayer/Leader/Aura.size = Vector2(124,26)
	t.tween_property($CanvasLayer/Leader/Aura, "position", Vector2(89,26), 0.4)
	t.tween_property($CanvasLayer/Leader/Name, "modulate", Color.TRANSPARENT, 0.4)
	t.tween_property($CanvasLayer/Leader/ExpBar, "modulate", Color.TRANSPARENT, 0.4)
	t.tween_property($CanvasLayer/Leader/Level, "position", Vector2(90,64), 0.4)
	t.tween_property($CanvasLayer/Leader/Health/HpText, "modulate", Color.TRANSPARENT, 0.4)
	t.tween_property($CanvasLayer/Leader/Aura/AruaText, "modulate", Color.TRANSPARENT, 0.4)
	
	#Member1
	t.tween_property($CanvasLayer/Member1, "scale", Vector2(1,1), 0.4)
	t.tween_property($CanvasLayer/Member1/Icon, "scale", Vector2(0.05,0.05), 0.4)
	t.tween_property($CanvasLayer/Member1/Icon, "position", Vector2(114,54), 0.4)
	t.tween_property($CanvasLayer/Member1, "position", Vector2(-70,130), 0.4)
	t.tween_property($CanvasLayer/Member1/Health, "size", Vector2(54,22), 0.4)
	t.tween_property($CanvasLayer/Member1/Aura, "size", Vector2(54,22), 0.4)
	t.tween_property($CanvasLayer/Member1/Health, "position", Vector2(159,30), 0.4)
	#$CanvasLayer/Member1/Aura.size = Vector2(124,26)
	t.tween_property($CanvasLayer/Member1/Aura, "position", Vector2(159,43), 0.4)
	t.tween_property($CanvasLayer/Member1/Name, "modulate", Color.TRANSPARENT, 0.4)
	t.tween_property($CanvasLayer/Member1/ExpBar, "modulate", Color.TRANSPARENT, 0.4)
	t.tween_property($CanvasLayer/Member1/Level, "position", Vector2(160,76), 0.4)
	t.tween_property($CanvasLayer/Member1/Health/HpText, "modulate", Color.TRANSPARENT, 0.4)
	t.tween_property($CanvasLayer/Member1/Aura/AruaText, "modulate", Color.TRANSPARENT, 0.4)
	
	t.tween_property($CanvasLayer/Leader, "position", Vector2(0,$CanvasLayer/Leader.position.y), 0.2)
	Expanded = false
	await t.finished
	$CanvasLayer/Page1.hide()
	$CanvasLayer/Page2.hide()
	$CanvasLayer/Page3.hide()
	$CanvasLayer/Page4.hide()

func handle_ui():
	if Input.is_action_just_pressed("ui_down"):
		if Party.check_member(focus+1):
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
	if focus == 0:
		t.tween_property($CanvasLayer/Page1,"position", Vector2(634, 44), 0.5)#.from(Vector2(1200,44))
		t.tween_property($CanvasLayer/Page2,"position", Vector2(634, 44), 0.4)
		t.tween_property($CanvasLayer/Page3,"position", Vector2(634, 44), 0.3)
		t.tween_property($CanvasLayer/Page4,"position", Vector2(634, 44), 0.2)
		t.tween_property($CanvasLayer/Page1/Render,"position", Vector2(150, 130), 0.5)#.from(Vector2(-15, 198))
		t.tween_property($CanvasLayer/Page2/Render,"position", Vector2(-15, 150), 0.3)
		t.tween_property($CanvasLayer/Page1/Render/Shadow, "modulate", Color(1,1,1,0.5), 0.5)
		t.tween_property($CanvasLayer/Page2/Render/Shadow, "modulate", Color.TRANSPARENT, 0.5)
		t.tween_property($CanvasLayer/Page1/Render/Shadow,"position", Vector2(-35,143), 0.5,)#.from(Vector2(120,80))
		t.tween_property($CanvasLayer/Page2/Render/Shadow,"position", Vector2(100,0), 0.5,)
	if focus == 1:
		t.tween_property($CanvasLayer/Page1,"position", Vector2(1300, 44), 0.3)
		t.tween_property($CanvasLayer/Page3,"position", Vector2(634, 44), 0.3)
		t.tween_property($CanvasLayer/Page4,"position", Vector2(634, 44), 0.3)
		t.tween_property($CanvasLayer/Page1/Render/Shadow, "modulate", Color.TRANSPARENT, 0.3)
		t.tween_property($CanvasLayer/Page2/Render/Shadow, "modulate", Color(1,1,1, 0.5), 0.5)
		t.tween_property($CanvasLayer/Page2/Render/Shadow,"position", Vector2(-35,143), 0.5)
		t.tween_property($CanvasLayer/Page1/Render,"position", Vector2(-15, 150), 0.3)
		t.tween_property($CanvasLayer/Page2,"position", Vector2(634, 44), 0.3)
		t.tween_property($CanvasLayer/Page2/Render,"position", Vector2(280, 187), 0.5)
		t.tween_property($CanvasLayer/Page1/Render/Shadow,"position", Vector2(0,0), 0.3)
		
	
func battle_state():
	if Loader.InBattle:
		$CanvasLayer.show()
		$CanvasLayer/Cursor.hide()
		t.kill()
		t = create_tween()
		t.set_parallel(true)
		t.tween_property($CanvasLayer/Leader, "position", Vector2(0,0), 0.2)
		t.tween_property($CanvasLayer/Member1, "position", Vector2(-70,160), 0.2)
		visibly=true
		$CanvasLayer/Leader/Name.show()
		$CanvasLayer/Leader/Level.show()
		$CanvasLayer/Leader/Icon.scale= Vector2(0.044,0.044)
		$CanvasLayer/Leader/Icon.position= Vector2(37,45)
		$CanvasLayer/Leader/Health.size = Vector2(110,20)
		$CanvasLayer/Leader/Health.position = Vector2(75,31)
		$CanvasLayer/Leader/Aura.size = Vector2(110,27)
		$CanvasLayer/Leader/Aura.position= Vector2(75,37)
		$CanvasLayer/Leader/Health/HpText.modulate = Color(1, 1, 1, 1)
		$CanvasLayer/Leader/ExpBar.modulate = Color(1, 1, 1, 1)
		$CanvasLayer/Leader/Name.modulate = Color(1, 1, 1, 1)
		$CanvasLayer/Leader/Aura/AruaText.modulate= Color(1, 1, 1, 1)
		$CanvasLayer/Leader/Level.position= Vector2(140,71)
		#$CanvasLayer/Member1.position= Vector2(0,189)
		$CanvasLayer/Member1/Icon.scale= Vector2(0.044,0.044)
		$CanvasLayer/Member1/Name.show()
		$CanvasLayer/Member1/Level.show()
		$CanvasLayer/Member1/Health/HpText.modulate= Color(1, 1, 1, 1)
		$CanvasLayer/Member1/ExpBar.modulate= Color(1, 1, 1, 1)
		$CanvasLayer/Member1/Name.modulate= Color(1, 1, 1, 1)
		$CanvasLayer/Member1/Aura/AruaText.modulate= Color(1, 1, 1, 1)
		$CanvasLayer/Member1/Level.position= Vector2(140,81)
		
		$CanvasLayer/Leader.scale = Vector2(1.25, 1.25)
		$CanvasLayer/Member1.scale = Vector2(1.25, 1.25)
		$CanvasLayer/Member1/ExpBar.hide()
		$CanvasLayer/Member1/Name.position = Vector2(140,13)
		$CanvasLayer/Member1/Health.size = Vector2(65,20)
		$CanvasLayer/Member1/Aura.size = Vector2(65,27)
		$CanvasLayer/Member1/Health.position = Vector2(130,40)
		$CanvasLayer/Member1/Aura.position = Vector2(130,46)
		$CanvasLayer/Member1/Health/HpText.position.x = 70
		$CanvasLayer/Member1/Aura/AruaText.position.x = 70
		$CanvasLayer/Member1/Icon.position.x = 93
	else:
		$CanvasLayer.hide()

func _on_battle_ui_root():
	battle_state()


func _on_battle_ui_ability():
	t = create_tween()
	t.set_parallel(true)
	if Global.Bt.CurrentChar == Party.Leader:
		t.tween_property($CanvasLayer/Member1, "position", Vector2(-400,$CanvasLayer/Member1.position.y), 0.2)
	elif Global.Bt.CurrentChar == Party.Member1:
		t.tween_property($CanvasLayer/Member1, "position", Vector2(-70,20), 0.2)
		t.tween_property($CanvasLayer/Leader, "position", Vector2(-400,$CanvasLayer/Leader.position.y), 0.2)

func check_member(mem:Actor, node:Panel, ind):
	node.get_node("Name").text = mem.FirstName
	var character_label = mem.FirstName
	get_node("CanvasLayer/Page"+str(ind+1)+"/Label").label_settings.font_color = mem.MainColor
	get_node("CanvasLayer/Page"+str(ind+1)+"/Label").text = mem.FirstName + " " + mem.LastName
	if get_node("CanvasLayer/Page"+str(ind+1)+"/Render").texture != mem.RenderArtwork:
		get_node("CanvasLayer/Page"+str(ind+1)+"/Render").texture = mem.RenderArtwork
		var shadow = make_shadow(mem.RenderShadow)
		get_node("CanvasLayer/Page"+str(ind+1)+"/Render/Shadow").texture = shadow
	t.tween_property(node.get_node("Health"), "value", mem.Health, 1)
	node.get_node("Health").max_value = mem.MaxHP
	draw_bar(mem, node)
	node.get_node("Aura").max_value = mem.MaxAura
	node.get_node("ExpBar").max_value = mem.SkillPointsFor[mem.SkillLevel]
	t.tween_property(node.get_node("ExpBar"), "value", mem.SkillPoints, 1)
	t.tween_property(node.get_node("Aura"), "value", mem.Aura, 1)
	node.get_node("Icon").texture = mem.PartyIcon
	node.get_node("Health/HpText").text = str(mem.Health)
	node.get_node("Aura/AruaText").text = str(mem.Aura)
	node.get_node("Level/Number").text = str(mem.SkillLevel)

func make_shadow(texture: Texture2D) -> Texture2D:
	var old_image := texture.get_image() #// Gets the image from the old texture.
	var old_size := old_image.get_size() #// Gets the size of the image as a Vector2i
	var image = old_image.duplicate()
	#// Gets a new image, identical to the old one.
	image.resize(old_size.x / 20, old_size.y / 20) #// Resizes the image, to one fifth of the original. Tweak this a lot depending on use, obviously.
	var new_texture = ImageTexture.create_from_image(image) #// We make a new ImageTexture (similar to any other StandardTexture2D) from our image and...
	return new_texture #// Set it as out texture.


func draw_bar(mem:Actor, node: Panel):
	node.get_node("Health/HpText").add_theme_color_override("font_color", mem.MainColor)
	node.get_node("Aura/AruaText").add_theme_color_override("font_color", mem.SecondaryColor)
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
	_on_expand(1)
	UIvisible = true
	t = create_tween()
	$CanvasLayer/Fade.show()
	MemberChoosing = true
	$CanvasLayer/Cursor/ItemPreview.grab_focus()
	$CanvasLayer/Cursor/ItemPreview.show()
	$CanvasLayer/Cursor/ItemPreview.text = Item.get_node("ItemEffect").item.Name + " x" + str(Item.get_node("ItemEffect").item.Quantity)
	t.tween_property($CanvasLayer/Cursor, "modulate", Color(1,1,1,1), 0.4)
	t.tween_property($CanvasLayer/Fade/Blur.material, "shader_parameter/lod", 3, 0.4)
	t.tween_property($CanvasLayer/Fade, "color", Color(0, 0, 0, 0.5), 0.4)


func _on_item_preview_pressed():
	if Item.get_node("ItemEffect").item.Quantity != 0:
		Item.emit_signal("return_member", (Party.get_member(focus)))
	else: Global.buzzer_sound()
	$CanvasLayer/Cursor/ItemPreview.text = Item.get_node("ItemEffect").item.Name + " x" + str(Item.get_node("ItemEffect").item.Quantity)
