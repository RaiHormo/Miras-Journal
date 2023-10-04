extends Control
var TurnOrder: Array[Actor]
var CurrentChar: Actor
var Party: PartyData
var Troop: Array[Actor]
@onready var Cam = $"../Cam"
@onready var t= Tween
@onready var tr= Tween
var active: bool
var stage: String
signal root
signal ability
signal attack
signal command
signal item
signal ability_returned(ab :Ability, tar :Actor)
signal targeted
signal targetFoc(ind :Actor)
var target : Actor
var LastTarget : Actor
var TargetIndex: int
var tweendone = true
var MenuIndex = 0
var Abilities: Array[Ability]
var PrevStage= "root"
var TargetFaction
var foc:Control
@onready var Bt :Battle = get_parent()

func _ready():
	t = create_tween()
	t.tween_property(self, "position", position, 0)
	tr = create_tween()
	tr.tween_property(self, "position", position, 0)
	get_viewport().connect("gui_focus_changed", _on_focus_changed)
	#t = create_tween()
	hide()
	$AbilityUI.hide()
	$DescPaper.hide()
	$CommandMenu.hide()
	$"../Canvas/TurnOrderPop".hide()
	$"../Canvas/DottedBack".hide()

func _process(delta):
	#$BaseRing/Ring2.rotation += 0.001
	if stage=="target":
		$BaseRing/Ring2.rotation -= 0.002

func _on_battle_get_control():
	if Bt.CurrentChar.Health == 0: Bt.next_turn.emit()
	if Bt.Troop.is_empty():
		close()
		Bt.victory()
		return
	Global.ui_sound("GetControl")
	active = true
	t.kill()
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	Loader.battle_bars(1)
	PartyUI.battle_state()
	Bt.Action = false
	show()
	stage = "root"
	PrevStage= "root"
	$Attack.show()
	$Item.show()
	$Command.show()
	$Ability.show()
	$"../Canvas/AttackTitle".hide()
	Troop = Bt.Troop
	TurnOrder = Bt.TurnOrder
	CurrentChar = Bt.CurrentChar
	Party = Bt.Party
	position = CurrentChar.node.position
	if CurrentChar.FirstName == "Mira":
		$BaseRing/Ring1.texture = preload("res://UI/Battle/MiraRing1.png")
		#$BaseRing/Ring2.texture = preload("res://UI/Battle/MiraRing2.png")
	Abilities = CurrentChar.Abilities
	$Ability.icon = Global.get_controller().AbilityIcon
	$Attack.icon = Global.get_controller().AttackIcon
	$Item.icon = Global.get_controller().ItemIcon
	$Command.icon = Global.get_controller().CommandIcon
	var dub = $AbilityUI/Margin/Scroller/List/Item0.duplicate()
	for n in $AbilityUI/Margin/Scroller/List.get_children():
		$AbilityUI/Margin/Scroller/List.remove_child(n)
		n.queue_free()
	for i in Abilities:
		dub = dub.duplicate()
		$AbilityUI/Margin/Scroller/List.add_child(dub)
		dub.text = i.name
		dub.get_node("Icon").texture = i.Icon
		if i.AuraCost != 0:
			dub.get_child(0).text = str(i.AuraCost)
			dub.get_child(0).show()
		else:
			dub.get_child(0).hide()
		dub.name = "Item" + str(dub.get_index(true))
		dub.set_meta("Ability", i)
	
	t.tween_property(Cam, "position", Vector2(0,0), 0.5)
	t.tween_property(Cam, "zoom", Vector2(4,4), 0.5)
	t.tween_property($Ability, "modulate", Color(1,1,1,1), 0.5).from(Color.TRANSPARENT)
	t.tween_property($Item, "modulate", Color(1,1,1,1), 0.5).from(Color.TRANSPARENT)
	t.tween_property($Command, "modulate", Color(1,1,1,1), 0.5).from(Color.TRANSPARENT)
	t.tween_property($Attack, "modulate", Color(1,1,1,1), 0.5).from(Color.TRANSPARENT)
	t.tween_property($Ability, "size", Vector2(33,33), 0.5).from(Vector2(31,33))
	t.tween_property($Attack, "size", Vector2(33,33), 0.5).from(Vector2(31,33))
	t.tween_property($Item, "size", Vector2(33,33), 0.5).from(Vector2(31,33))
	t.tween_property($Command, "size", Vector2(33,33), 0.5).from(Vector2(31,33))
	t.tween_property(self, "rotation_degrees", -720, 0.5).from(360)
	t.tween_property(self, "scale", Vector2(1,1), 0.5).from(Vector2(0.25,0.25))
	$BaseRing.scale= Vector2(0.25,0.25)
	$BaseRing/Ring2.scale = Vector2(1,1)
#	$Ability.size = Vector2(33, 33)
#	$Item.size= Vector2(33, 33)
#	$Command.size = Vector2(33, 33)
#	$Attack.size = Vector2(33, 33)
	$Ability.position = Vector2(17,-15)
	$Item.position= Vector2(-56,-15)
	$Command.position = Vector2(-18,-51)
	$Attack.position = Vector2(-18,20)
	await t.finished
	root.emit()

func _on_root():
	if foc!=null:
		foc.hide()
		foc.show()
	t.kill()
	tr.kill()
	t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	stage = "root"
	PrevStage= "root"
	Bt.get_node("EnemyUI").all_enemy_ui()
	t.tween_property($DescPaper, "rotation_degrees", -75, 0.3)
	t.tween_property($DescPaper, "scale", Vector2(0.1,0.1), 0.3)
	t.tween_property($DescPaper, "modulate", Color(0,0,0,0), 0.2)
	t.tween_property($BaseRing, "position", Vector2(-200,-200), 0.3)
	$Ability.icon = Global.get_controller().AbilityIcon
	$Attack.icon = Global.get_controller().AttackIcon
	$Item.icon = Global.get_controller().ItemIcon
	$Command.icon = Global.get_controller().CommandIcon
	t.tween_property($Ability, "size", Vector2(115,33), 0.3)
	t.tween_property($Item, "size", Vector2(99,33), 0.3)
	t.tween_property($Ability, "modulate", Color(1,1,1,1), 0.5)
	t.tween_property($Item, "modulate", Color(1,1,1,1), 0.5)
	t.tween_property($Command, "modulate", Color(1,1,1,1), 0.5)
	t.tween_property($Attack, "modulate", Color(1,1,1,1), 0.5)
	t.tween_property($Command, "size", Vector2(138,33), 0.3)
	t.tween_property($Attack, "size", Vector2(115,33), 0.3)
	t.tween_property($AbilityUI, "modulate", Color(0,0,0,0), 0.3)
	t.tween_property($AbilityUI, "position", Vector2(12,-140), 0.3)
	t.tween_property($AbilityUI, "size", Vector2(100,5), 0.3)
	t.tween_property($Ability, "position", Vector2(6,-15), 0.3)
	t.tween_property($Attack, "position", Vector2(-30,20), 0.3)
	t.tween_property($Item, "position", Vector2(-66,-15), 0.3)
	t.tween_property($Command, "position", Vector2(-33,-51), 0.3)
	$Ability.add_theme_constant_override("icon_max_width", 0)
	t.tween_property($CommandMenu/Escape, "rotation_degrees", -180, 0.3)
	t.tween_property($CommandMenu, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($BaseRing/Ring2, "rotation_degrees", -600, 0.3).as_relative()
	t.tween_property(Cam, "position", Vector2(0,0), 0.5)
	t.tween_property(Cam, "zoom", Vector2(4,4), 0.5)
	t.tween_property($BaseRing/Ring2, "scale", Vector2(1,1), 0.3)
	t.tween_property($BaseRing/Ring2, "position", Vector2(0,0), 0.3)
	t.tween_property(self, "scale", Vector2(1,1), 0.3)
	t.tween_property(self, "position", CurrentChar.node.position, 0.3)
	t.tween_property(self, "rotation_degrees", -720, 0.5)
	t.tween_property($BaseRing, "scale", Vector2(0.25,0.25), 0.3)
	#t.tween_property($BaseRing/Ring2, "scale", Vector2(1,1), 0.3)
	t.tween_property($Arrow, "modulate", Color(0,0,0,0), 0.3)
	t.tween_property($"../Canvas/AttackTitle", "position", Vector2(1360, 550), 0.3)
	Bt.get_node("Canvas/TurnOrder").icon = Global.get_controller().Select
	Bt.get_node("Canvas/TurnOrder").show()
	t.tween_property(Bt.get_node("Canvas/TurnOrder"), "position", Vector2(31,742), 0.4)
	t.tween_property(Bt.get_node("Canvas/Confirm"), "position", Vector2(195,850), 0.4)
	t.tween_property(Bt.get_node("Canvas/Back"), "position", Vector2(31,850), 0.3)
	tweendone = false
	active = true
	$Attack.show()
	$Item.show()
	$Command.show()
	$Ability.show()
	await t.finished
	$DescPaper.hide()
	$CommandMenu.hide()

func _input(event):
	if Global.LastInput==Global.ProcessFrame: return
	if active:
		if stage == "root":
			if Input.is_action_just_pressed("BtAttack"):
				attack.emit()
			if Input.is_action_just_pressed("BtCommand"):
				command.emit()
			if Input.is_action_just_pressed("BtAbility"):
				while Input.is_action_pressed("ui_accept"):
					await Event.wait()
				ability.emit()
		elif stage == "target":
#			if Input.is_action_just_pressed(Global.confirm()):
#				_on_confirm_pressed()
			if Input.is_action_just_pressed(Global.cancel()):
#				if PrevStage != stage:
						Global.cancel_sound()
						emit_signal(PrevStage)
			if Input.is_action_just_pressed("ui_down") and active:
				if TargetFaction.size() == 1:
					Global.buzzer_sound()
					return
				if TargetIndex!=TargetFaction.size() -1:
					TargetIndex += 1
				else:
					TargetIndex = 0
				while TargetFaction[TargetIndex].has_state("Knocked Out"):
					if TargetIndex!=TargetFaction.size() -1:
						TargetIndex += 1
					else:
						TargetIndex = 0
				Global.cursor_sound()
				move_menu()
			if Input.is_action_just_pressed("ui_up") and active:
				if TargetFaction.size() == 1:
					Global.buzzer_sound()
					return
				if TargetIndex!=0:
					TargetIndex -= 1
				else:
					TargetIndex = TargetFaction.size() -1
				Global.cursor_sound()
				while TargetFaction[TargetIndex].has_state("Knocked Out"):
					if TargetIndex!=0:
						TargetIndex -= 1
					else:
						TargetIndex = TargetFaction.size() -1
				move_menu()
		elif stage == "ability":
			if Input.is_action_just_pressed(Global.cancel()):
				Bt.anim()
				Global.cancel_sound()
				root.emit()
			if Input.is_action_just_pressed("ui_up") and active:
				if $AbilityUI/Margin/Scroller/List.get_child_count() == 1:
					Global.buzzer_sound()
					return
				if MenuIndex!= 0:
					MenuIndex -= 1
				else:
					MenuIndex = $AbilityUI/Margin/Scroller/List.get_child_count() -1
				Global.cursor_sound()
				move_menu()
			if Input.is_action_just_pressed("ui_down") and active:
				if $AbilityUI/Margin/Scroller/List.get_child_count() == 1:
					Global.buzzer_sound()
					return
				if MenuIndex!=$AbilityUI/Margin/Scroller/List.get_child_count() -1:
					MenuIndex += 1
				else:
					MenuIndex = 0
				Global.cursor_sound()
				move_menu()
		elif stage == "command":
			if Input.is_action_just_pressed(Global.cancel()):
					Global.cancel_sound()
					emit_signal(PrevStage)

func _on_attack():
	Global.confirm_sound()
	stage="attack"
	PrevStage="root"
	CurrentChar.NextAction = "attack"
	active = false
	CurrentChar.NextMove = CurrentChar.StandardAttack
	get_target(Bt.get_oposing_faction())
	#await targeted
	

func _on_ability():
	active= false
	stage = "ability"
	PrevStage= "root"
	Bt.get_node("Canvas/Confirm").show()
	Bt.get_node("Canvas/Back").show()
	Bt.get_node("Canvas/Confirm").text = "Confirm"
	Bt.get_node("Canvas/Back").text = "Back"
	Bt.get_node("Canvas/Confirm").icon = Global.get_controller().ConfirmIcon
	Bt.get_node("Canvas/Back").icon = Global.get_controller().CancelIcon
	$DescPaper/ShowWheel.icon = Global.get_controller().CommandIcon
	CurrentChar.NextAction = "ability"
	t.kill()
	$DescPaper.show()
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	Global.confirm_sound()
	$AbilityUI.show()
	$Arrow.show()
	#t.tween_property($BaseRing/Ring2, "rotation", ($BaseRing/Ring2.rotation+10), 0.3)
	$Ability.add_theme_constant_override("icon_max_width", 1)
	$Ability.icon = null
	t.tween_property(self, "rotation_degrees", -720, 0.1)
	t.tween_property(self, "scale", Vector2(1,1), 0.3)
	t.tween_property(Bt.get_node("Canvas/TurnOrder"), "position", Vector2(31,850), 0.3)
	t.tween_property(Bt.get_node("Canvas/Confirm"), "position", Vector2(195,742), 0.4).from(Vector2(195,850))
	t.tween_property(Bt.get_node("Canvas/Back"), "position", Vector2(31,742), 0.3).from(Vector2(31,850))
	t.tween_property($Ability, "size", Vector2(115,33), 0.3)
	t.tween_property($Ability, "modulate", Color.WHITE, 0.3)
	t.tween_property(self, "position", CurrentChar.node.position, 0.3)
	t.tween_property($AbilityUI, "modulate", Color(1,1,1,1), 0.1)
	t.tween_property($"../Canvas/AttackTitle", "position", Vector2(1350, 550), 0.3)
	t.tween_property(Cam, "position", CurrentChar.node.position +Vector2(100,0), 0.3)
	t.tween_property(Cam, "zoom", Vector2(4.5,4.5), 0.5)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property($AbilityUI, "size", Vector2(300,444), 0.3)
	t.tween_property($BaseRing/Ring2, "scale", Vector2(1.1,1.1), 0.3)
	t.tween_property($BaseRing, "scale", Vector2(0.7,0.7), 0.3)
	t.tween_property($BaseRing, "position", Vector2(-220,-180), 0.3)
	t.tween_property($AbilityUI, "position", Vector2(20,-160), 0.3)
	t.tween_property($Ability, "position", Vector2(43,-59), 0.3)
	CurrentChar.NextAction = "ability"
	
	t.tween_property($DescPaper, "scale", Vector2(0.17,0.17), 0.4)
	t.tween_property($DescPaper, "rotation_degrees", 0, 0.4) 
	t.tween_property($DescPaper, "modulate", Color(1,1,1,1), 0.3)
	t.tween_property($Attack, "position", Vector2(-20,90), 0.3).as_relative()
	t.tween_property($Item, "position", Vector2(-90,10), 0.3).as_relative()
	t.tween_property($Command, "position", Vector2(-20,-60), 0.3).as_relative()
	t.tween_property($Arrow, "modulate", Color(0.9,0.9,0.9,1), 0.3)
	$Ability.focus_mode = 0
	if get_node_or_null("AbilityUI/Margin/Scroller/List/Item"+str(MenuIndex)) == null:
		MenuIndex = 0
	get_node("AbilityUI/Margin/Scroller/List/Item"+str(MenuIndex)).grab_focus()
	$AbilityUI/Margin/Scroller.scroll_vertical = 0
	$DescPaper/Desc.text = Abilities[0].description
	if Abilities[0].AuraCost != 0:
		$DescPaper/Cost.text = str("Cost ", str(Abilities[0].AuraCost))
		$DescPaper/Cost.show()
	else:
		$DescPaper/Cost.hide()
	$DescPaper/Title.text = Abilities[0].name
	CurrentChar.NextMove = CurrentChar.Abilities[0]
	await t.finished
	active = true
	

func _on_command():
	stage = "command"
	PrevStage= "root"
	Bt.get_node("Canvas/Back").show()
	Bt.get_node("Canvas/Back").text = "Back"
	Bt.get_node("Canvas/Back").icon = Global.get_controller().CancelIcon
	CurrentChar.NextAction = "command"
	t.kill()
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	Global.confirm_sound()
	$CommandMenu/Escape.icon = Global.get_controller().LZ
	$CommandMenu.modulate = Color.WHITE
	t.tween_property(Cam, "position", CurrentChar.node.position +Vector2(-30, 0), 0.3)
	t.tween_property(Cam, "zoom", Vector2(5.5,5.5), 0.3)
	t.tween_property(Bt.get_node("Canvas/TurnOrder"), "position", Vector2(31,850), 0.3)
	t.tween_property(Bt.get_node("Canvas/Back"), "position", Vector2(31,742), 0.3).from(Vector2(31,850))
	t.tween_property($Ability, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Item, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Command, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Attack, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Ability, "size", Vector2(33,-33), 0.2)
	t.tween_property($Attack, "size", Vector2(33,33), 0.2)
	t.tween_property($Item, "size", Vector2(33,33), 0.2)
	t.tween_property($Command, "size", Vector2(33,33), 0.2)
	t.tween_property(self, "rotation_degrees", -720, 0.1)
	t.tween_property(self, "scale", Vector2(1,1), 0.3)
	t.tween_property($BaseRing/Ring2, "scale", Vector2(1.4,1.4), 0.3)
	t.tween_property($BaseRing, "scale", Vector2(0.6,0.6), 0.3)
	t.tween_property($BaseRing, "position", Vector2(-160,-200), 0.3)
	t.tween_property($BaseRing/Ring2, "position", Vector2(50,-20), 0.3)
	t.tween_property($CommandMenu/Escape, "rotation_degrees", 0, 0.3).from(-180)
	t.tween_property($CommandMenu/CmdBack, "modulate", Color.WHITE, 0.3).from(Color.TRANSPARENT)
	t.tween_property($CommandMenu/CmdBack, "rotation_degrees", 12, 0.5).from(120)
	#t.tween_property($CommandMenu/CmdBack, "position", Vector2(-884, -768), 0.5).from(Vector2(-584, -868))
	$CommandMenu.show()

func close():
	active=false
	stage = "inactive"
	t.kill()
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property($Ability, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Item, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Command, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Attack, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Ability, "size", Vector2(33,33), 0.2)
	t.tween_property($Attack, "size", Vector2(33,33), 0.2)
	t.tween_property($Item, "size", Vector2(33,33), 0.2)
	t.tween_property($Command, "size", Vector2(33,33), 0.2)
	
	t.tween_property($BaseRing, "scale", Vector2(0.01,0.01), 0.3)
	t.tween_property($BaseRing/Ring2, "scale", Vector2(5,5), 0.4)
	t.tween_property($BaseRing/Ring2, "rotation_degrees", +600, 0.3).as_relative()
	t.tween_property($BaseRing, "position", Vector2(-200,-200), 0.3)
	t.tween_property($DescPaper, "rotation_degrees", -75, 0.3)
	t.tween_property($DescPaper, "scale", Vector2(0.1,0.1), 0.3)
	t.tween_property($DescPaper, "modulate", Color(0,0,0,0), 0.2)
	t.tween_property($AbilityUI, "modulate", Color(0,0,0,0), 0.3)
	t.tween_property($AbilityUI, "position", Vector2(12,-140), 0.3)
	t.tween_property($AbilityUI, "size", Vector2(100,5), 0.3)
	t.tween_property($Arrow, "modulate", Color(0,0,0,0), 0.2)
	t.tween_property($"../Canvas/AttackTitle", "position", Vector2(1350, 550), 0.5)
	t.tween_property(Bt.get_node("Canvas/Confirm"), "position", Vector2(195,850), 0.4)
	t.tween_property(Bt.get_node("Canvas/Back"), "position", Vector2(31,850), 0.3)
	PartyUI.battle_state()
	await t.finished
	hide()


func _on_ability_pressed():
	ability.emit()
func _on_attack_pressed():
	attack.emit()
func _on_item_pressed():
	item.emit()
func _on_command_pressed():
	command.emit()

func get_target(faction:Array[Actor]):
	if Bt.Action: return
	if foc!=null:
		foc.hide()
		foc.show()
	if Troop.is_empty():
		close()
		Bt.victory()
		return
	TargetFaction = faction
	Bt.get_node("Canvas/Confirm").show()
	Bt.get_node("Canvas/Back").show()
	Bt.get_node("Canvas/Confirm").text = "Target"
	Bt.get_node("Canvas/Back").text = "Cancel"
	Bt.get_node("Canvas/Confirm").icon = Global.get_controller().ConfirmIcon
	Bt.get_node("Canvas/Back").icon = Global.get_controller().CancelIcon
	$"../Canvas/AttackTitle/Wheel".show_atk_color(CurrentChar.NextMove.WheelColor)
	if CurrentChar.NextAction == "ability" and CurrentChar.NextMove.WheelColor.s > 0:
		$"../Canvas/AttackTitle/Wheel".show()
		$"../Canvas/AttackTitle/Wheel".show_atk_color(CurrentChar.NextMove.WheelColor)
	else:
		$"../Canvas/AttackTitle/Wheel".hide()
	t.kill()
	t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	t.tween_property($Ability, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Item, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Command, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Attack, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Ability, "size", Vector2(33,33), 0.2)
	t.tween_property($Attack, "size", Vector2(33,33), 0.2)
	t.tween_property($Item, "size", Vector2(33,33), 0.2)
	t.tween_property($Command, "size", Vector2(33,33), 0.2)
#	t.tween_property(self, "rotation_degrees", 360, 0.2)
	t.tween_property(Bt.get_node("Canvas/TurnOrder"), "position", Vector2(31,850), 0.3)
	t.tween_property(Bt.get_node("Canvas/Confirm"), "position", Vector2(195,742), 0.3).from(Vector2(195,850))
	t.tween_property(Bt.get_node("Canvas/Back"), "position", Vector2(31,742), 0.4).from(Vector2(31,850))
	
	t.tween_property(self, "scale", Vector2(0.7,0.7), 0.3)
	t.tween_property($BaseRing, "scale", Vector2(0.2,0.2), 0.3)
	t.tween_property($BaseRing/Ring2, "scale", Vector2(1.2,1.2), 0.4)
	t.tween_property($BaseRing/Ring2, "rotation_degrees", +600, 0.3).as_relative()
	t.tween_property($BaseRing, "position", Vector2(-200,-200), 0.3)
	t.tween_property($DescPaper, "rotation_degrees", -75, 0.3)
	t.tween_property($DescPaper, "scale", Vector2(0.1,0.1), 0.3)
	t.tween_property($DescPaper, "modulate", Color(0,0,0,0), 0.2)
	t.tween_property($AbilityUI, "modulate", Color(0,0,0,0), 0.3)
	t.tween_property($AbilityUI, "position", Vector2(12,-140), 0.3)
	t.tween_property($AbilityUI, "size", Vector2(100,5), 0.3)
	t.tween_property($Arrow, "modulate", Color(0,0,0,0), 0.2)
	
	t.tween_property($"../Canvas/AttackTitle", "position", Vector2(840, 550), 0.5)
	$"../Canvas/AttackTitle".show()
	$"../Canvas/AttackTitle/RichTextLabel".text = CurrentChar.NextMove.description
	$"../Canvas/AttackTitle".text = CurrentChar.NextMove.name
	$"../Canvas/AttackTitle".icon = CurrentChar.NextMove.Icon
	
	if not LastTarget in faction:
		LastTarget = faction[0]
		TargetIndex = 0
	target = LastTarget
	while faction[TargetIndex].has_state("Knocked Out") or faction[TargetIndex].node ==null:
		if TargetIndex!=faction.size() -1:
			TargetIndex += 1
		else:
			TargetIndex = 0
	target = faction[TargetIndex]
	t.tween_property(self, "position", target.node.position, 0.3)
	t.tween_property(Cam, "zoom", Vector2(4.5,4.5), 0.5)
	t.tween_property(Cam, "position", Vector2(target.node.position.x, target.node.position.y /4), 0.5)
	emit_signal('targetFoc', faction[TargetIndex])
	$"../Canvas/AttackTitle/Wheel".show_trg_color(target.MainColor)
	await t.finished
	active = true
	stage = "target"
	while stage == "target":
		tr = create_tween()
		tr.set_ease(Tween.EASE_IN_OUT)
		tr.set_trans(Tween.TRANS_SINE)
		tr.tween_property($BaseRing/Ring2, "scale", -Vector2(0.1,0.1), 0.7).as_relative()
		if stage != "target": return
		tr.tween_property($BaseRing/Ring2, "scale", Vector2(0.1,0.1), 0.7).as_relative()
		await tr.finished

func _on_ability_returned(ab:Ability, tar:Actor):
	print("Using ", ab.name, " on ", tar.FirstName)
	close()

func move_menu():
	active= false
	t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	if stage == "target":
		target= TargetFaction[TargetIndex]
		t.set_parallel()
		t.tween_property(Cam, "position", Vector2(target.node.position.x, target.node.position.y /4), 0.5)
		t.tween_property(self, "position", target.node.position, 0.3)
		LastTarget = target
		emit_signal('targetFoc', TargetFaction[TargetIndex])
		$"../Canvas/AttackTitle/Wheel".show_trg_color(target.MainColor)
		await get_tree().create_timer(0.2).timeout
	if stage == "ability":
		await get_tree().create_timer(0.001).timeout
		if not $AbilityUI/Margin/Scroller/List.get_child(MenuIndex).has_focus():
			$AbilityUI/Margin/Scroller/List.get_child(MenuIndex).grab_focus()
		if MenuIndex < 6:
			t.tween_property($AbilityUI/Margin/Scroller, "scroll_vertical", 0, 0.2)
		if MenuIndex >= 6:
			t.tween_property($AbilityUI/Margin/Scroller, "scroll_vertical", 80 + (MenuIndex-6) *70, 0.2)
		#print(MenuIndex)
		$DescPaper/Desc.text = Abilities[MenuIndex].description
		$DescPaper/Title.text = Abilities[MenuIndex].name
		CurrentChar.NextMove = foc.get_meta("Ability")
		if Abilities[MenuIndex].AuraCost != 0:
			$DescPaper/Cost.text = str("Cost ", str(Abilities[MenuIndex].AuraCost))
			$DescPaper/Cost.show()
		else:
			$DescPaper/Cost.hide()
		if CurrentChar.NextMove.WheelColor.s > 0:
			$DescPaper/ShowWheel.show()
			$DescPaper/ShowWheel/Wheel.show_atk_color(CurrentChar.NextMove.WheelColor)
		else:
			$DescPaper/ShowWheel.hide()
	active= true
	tweendone = true

func _on_battle_next_turn():
	if CurrentChar == null: return
	if not Bt.CurrentChar.Controllable:
		hide()
		active = false

func _on_targeted():
	if CurrentChar.NextMove == null: return
	emit_signal("ability_returned", CurrentChar.NextMove, target )

func _on_back_pressed():
	Global.cancel_sound()
	emit_signal(PrevStage)

func _on_focus_changed(control:Control):
	foc = control
	if control is Button:
		MenuIndex = control.get_index()
		move_menu()

func _on_ability_entry():
	if active:
		Global.confirm_sound()
		var ab = $AbilityUI/Margin/Scroller/List.get_child(MenuIndex).get_meta("Ability")
		if ab.Target == 1:
			PrevStage="ability"
			stage = "target"
			get_target(Bt.get_oposing_faction())
		if ab.Target == 3:
			PrevStage="ability"
			stage = "target"
			get_target(Bt.get_ally_faction())
		if ab.Target == 0:
			emit_signal("ability_returned", ab, CurrentChar)
			close()


func _on_confirm_pressed():
	if active:
		if stage == "target":
			Global.confirm_sound()
			targeted.emit()
			close()

func turn_order():
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	Bt.get_node("Canvas/TurnOrderPop").show()
	t.tween_property(Bt.get_node("Canvas/TurnOrderPop"), "modulate", Color.WHITE, 0.3)
	t.tween_property(Bt.get_node("Canvas/TurnOrderPop"), "position", Vector2(52, 40), 0.3)
	while (Input.is_action_pressed("PartyMenu") or Bt.get_node("Canvas/TurnOrder").button_pressed):
		Bt.turn_ui_check()
		await Event.wait()
	t = create_tween()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	t.tween_property(Bt.get_node("Canvas/TurnOrderPop"), "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property(Bt.get_node("Canvas/TurnOrderPop"), "position", Vector2(-468, 40), 0.3)



func _on_escape():
	Bt.escape()


func _on_show_wheel_pressed():
	Global.confirm_sound()
	t.kill()
	t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	if $DescPaper/ShowWheel/Wheel.visible:
		$DescPaper/ShowWheel.text = "Show wheel"
		t.tween_property($DescPaper/ShowWheel, "position:x", 140, 0.3)
		t.tween_property($DescPaper/ShowWheel/Wheel, "modulate", Color.TRANSPARENT, 0.3)
		await t.finished
		$DescPaper/ShowWheel/Wheel.hide()
	else:
		$DescPaper/ShowWheel/Wheel.show()
		$DescPaper/ShowWheel.text = "Hide wheel"
		t.tween_property($DescPaper/ShowWheel/Wheel, "modulate", Color.WHITE, 0.3).from(Color.TRANSPARENT)
		t.tween_property($DescPaper/ShowWheel, "position:x", 520, 0.3)
