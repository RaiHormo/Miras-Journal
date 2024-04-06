extends Control
var TurnOrder: Array[Actor]
var CurrentChar: Actor
var Party: PartyData
var Troop: Array[Actor]
@onready var Cam = $"../Cam"
@onready var t= Tween
@onready var tr= Tween
var active: bool
var stage: StringName
signal root
signal ability
signal attack
signal command
signal item
signal ability_returned(ab :Ability, tar)
signal targeted
signal targetFoc(ind :Actor)
var target : Actor
var LastTarget : Actor
var TargetIndex: int
var tweendone := true
var MenuIndex := 0
var Abilities: Array[Ability]
var PrevStage := &"root"
var TargetFaction: Array[Actor]
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
	if CurrentChar != null and CurrentChar.has_state("Confused"):
		$BaseRing.pivot_offset = Vector2(200 + randf_range(-1, 1), 200 + randf_range(-1, 1))

func _on_battle_get_control():
	if Bt.Troop.is_empty():
		close()
		Bt.victory()
		return
	if Bt.CurrentChar.Health == 0:
		Bt.death(Bt.CurrentChar)
		Bt.next_turn.emit()
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
	stage = &"root"
	PrevStage = &"root"
	if Item.ConInv.is_empty() and Item.BtiInv.is_empty(): $Item.disabled = true
	else: $Item.disabled = false
	$Ability.add_theme_constant_override("icon_max_width", 0)
	$Ability.icon = Global.get_controller().AbilityIcon
	$Attack.icon = Global.get_controller().AttackIcon
	$Item.icon = Global.get_controller().ItemIcon
	$Command.icon = Global.get_controller().CommandIcon
	$Attack.show()
	$Item.show()
	$Command.show()
	$Ability.show()
	$Inventory.hide()
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
	fetch_abilities()
	fetch_inventory()
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
	stage = &"root"
	PrevStage = &"root"
	PartyUI.battle_state()
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
	t.tween_property($Inventory, "scale", Vector2(0.1, 0.1), 0.3)
	t.tween_property($Inventory, "modulate", Color(0,0,0,0), 0.3)
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
	$Inventory.hide()

func _input(event: InputEvent) -> void:
	if Global.LastInput==Global.ProcessFrame: return
	if active:
		match stage:
			&"root":
				if Input.is_action_just_pressed("BtAttack") and not $Attack.disabled:
					while Input.is_action_pressed("ui_accept"): await Event.wait()
					attack.emit()
				if Input.is_action_just_pressed("BtCommand") and not $Command.disabled:
					command.emit()
				if Input.is_action_just_pressed("BtItem") and not $Item.disabled:
					item.emit()
				if Input.is_action_just_pressed("BtAbility") and not $Ability.disabled:
					while Input.is_action_pressed("ui_accept"): await Event.wait()
					ability.emit()
			&"target":
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
			&"ability":
				if Input.is_action_just_pressed(Global.cancel()):
					Bt.anim()
					Global.cancel_sound()
					root.emit()
				if Input.is_action_just_pressed("ui_up") and active:
					if %AbilityList.get_child_count() == 1:
						Global.buzzer_sound()
						return
					if MenuIndex!= 0:
						MenuIndex -= 1
					else:
						MenuIndex = %AbilityList.get_child_count() -1
					Global.cursor_sound()
					move_menu()
				if Input.is_action_just_pressed("ui_down") and active:
					if %AbilityList.get_child_count() == 1:
						Global.buzzer_sound()
						return
					if MenuIndex!=%AbilityList.get_child_count() -1:
						MenuIndex += 1
					else:
						MenuIndex = 0
					Global.cursor_sound()
					move_menu()
			&"command":
				if Input.is_action_just_pressed(Global.cancel()):
					Global.cancel_sound()
					emit_signal(PrevStage)
			&"item":
				if Input.is_action_just_pressed(Global.cancel()):
					Global.cancel_sound()
					emit_signal(PrevStage)
			&"pre_target":
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
	stage = &"ability"
	PrevStage = &"root"
	$"../Canvas/Confirm".show()
	$"../Canvas/Back".show()
	$"../Canvas/Confirm".text = "Confirm"
	$"../Canvas/Back".text = "Back"
	$"../Canvas/Confirm".icon = Global.get_controller().ConfirmIcon
	$"../Canvas/Back".icon = Global.get_controller().CancelIcon
	$DescPaper/ShowWheel.icon = Global.get_controller().CommandIcon
	CurrentChar.NextAction = "ability"
	PartyUI.only_current()
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
	t.tween_property($"../Canvas/Confirm", "position",
	Vector2(195,742), 0.4).from(Vector2(195,850))
	t.tween_property($"../Canvas/Back", "position", Vector2(31,742), 0.3).from(Vector2(31,850))
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
	if get_node_or_null("%AbilityList/Item"+str(MenuIndex)) == null:
		MenuIndex = 0
	%AbilityList.get_child(MenuIndex).grab_focus()
	$AbilityUI/Margin/Scroller.scroll_vertical = 0
	var color: Color = Abilities[MenuIndex].WheelColor
	if Abilities[MenuIndex].ColorSameAsActor: color = CurrentChar.MainColor
	$DescPaper/Title.add_theme_color_override("font_color", color - Color(0.2, 0.2, 0.2, 0))
	$DescPaper/Desc.text = Global.colorize(Abilities[0].description)
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
	stage = &"inactive"
	PrevStage= &"root"
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
	t.tween_property(Cam, "position", CurrentChar.node.position +Vector2(-30, 0), 0.3)
	t.tween_property(Cam, "zoom", Vector2(5.5,5.5), 0.3)
	t.tween_property(Bt.get_node("Canvas/TurnOrder"), "position", Vector2(31,850), 0.3)
	t.tween_property(Bt.get_node("Canvas/Back"), "position",
	Vector2(31,742), 0.3).from(Vector2(31,850))
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
	t.tween_property($CommandMenu/CmdBack, "modulate",
	Color.WHITE, 0.3).from(Color.TRANSPARENT)
	t.tween_property($CommandMenu/CmdBack, "rotation_degrees", 12, 0.5).from(120)
	if Bt.Seq.CanEscape:
		$CommandMenu/Escape.show()
		t.tween_property($CommandMenu/Escape,
		"rotation_degrees", 0, 0.3).from(-180)
		$CommandMenu/Escape.icon = Global.get_controller().LZ
		$CommandMenu.modulate = Color.WHITE
	else: $CommandMenu/Escape.hide()
	$CommandMenu.show()
	await Event.wait()
	stage = &"command"


func _on_item() -> void:
	stage = &"item"
	PrevStage = &"root"
	if Item.ConInv.is_empty() and Item.BtiInv.is_empty(): $Item.disabled = true; return
	Bt.get_node("Canvas/Back").show()
	Bt.get_node("Canvas/Back").text = "Back"
	Bt.get_node("Canvas/Back").icon = Global.get_controller().CancelIcon
	$Inventory/Cbutton.icon = Global.get_controller().R
	$Inventory/BIbutton.icon = Global.get_controller().L
	$Inventory.show()
	CurrentChar.NextAction = "item"
	await fetch_inventory()
	t.kill()
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT)
	t.set_parallel()
	Global.confirm_sound()
	Bt.get_node("EnemyUI").colapse_root()
	t.tween_property(self, "rotation_degrees", -720, 0.1)
	t.tween_property(Cam, "position", CurrentChar.node.position +Vector2(-80, 0), 0.3)
	t.tween_property(Cam, "zoom", Vector2(5.5,5.5), 0.3)
	t.tween_property(Bt.get_node("Canvas/TurnOrder"), "position", Vector2(31,850), 0.3)
	t.tween_property($"../Canvas/Confirm", "position",
	Vector2(195,742), 0.4).from(Vector2(195,850))
	t.tween_property($"../Canvas/Back", "position", Vector2(31,742), 0.3).from(Vector2(31,850))
	t.tween_property($Ability, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Inventory, "modulate", Color.WHITE, 0.3).from(Color.WHITE)
	t.tween_property($Inventory, "scale", Vector2(0.21, 0.21), 0.3).from(Vector2(0.1, 0.1))
	t.tween_property($Item, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Command, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Attack, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Ability, "size", Vector2(33,-33), 0.2)
	t.tween_property($Attack, "size", Vector2(33,33), 0.2)
	t.tween_property($Item, "size", Vector2(33,33), 0.2)
	t.tween_property($Command, "size", Vector2(33,33), 0.2)
	t.tween_property($BaseRing/Ring2, "scale", Vector2(0.9,0.9), 0.3)
	t.tween_property($BaseRing/Ring2, "position", Vector2(160,0), 0.3)
	t.tween_property($BaseRing, "scale", Vector2(1.1,1.1), 0.3)
	t.tween_property($BaseRing, "position", Vector2(-320,-200), 0.3)
	$Item.hide()
	$Ability.hide()
	$Command.hide()
	$Attack.hide()
	PartyUI.only_current()
	focus_inv_default()
	await Event.wait(0.1)
	focus_inv_default()

func close():
	active=false
	stage = &"inactive"
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

	$Ability.icon = Global.get_controller().AbilityIcon
	$Attack.icon = Global.get_controller().AttackIcon
	$Item.icon = Global.get_controller().ItemIcon
	$Command.icon = Global.get_controller().CommandIcon

	t.tween_property($BaseRing, "scale", Vector2(0.01,0.01), 0.3)
	t.tween_property($BaseRing/Ring2, "position", Vector2.ZERO, 0.3)
	t.tween_property($BaseRing/Ring2, "scale", Vector2(1,1), 0.4)
	t.tween_property($BaseRing/Ring2, "rotation_degrees", +600, 0.3).as_relative()
	t.tween_property($BaseRing, "position", Vector2(-200,-200), 0.3)
	t.tween_property($DescPaper, "rotation_degrees", -75, 0.3)
	t.tween_property($DescPaper, "scale", Vector2(0.1,0.1), 0.3)
	t.tween_property($DescPaper, "modulate", Color(0,0,0,0), 0.2)
	t.tween_property($AbilityUI, "modulate", Color(0,0,0,0), 0.3)
	t.tween_property($AbilityUI, "position", Vector2(12,-140), 0.3)
	t.tween_property($AbilityUI, "size", Vector2(100,5), 0.3)
	t.tween_property($Inventory, "scale", Vector2(0.1, 0.1), 0.3)
	t.tween_property($Inventory, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($Arrow, "modulate", Color(0,0,0,0), 0.2)
	t.tween_property($"../Canvas/AttackTitle", "position", Vector2(1350, 550), 0.5)
	t.tween_property(Bt.get_node("Canvas/Confirm"), "position", Vector2(195,850), 0.4)
	t.tween_property(Bt.get_node("Canvas/Back"), "position", Vector2(31,850), 0.3)
	PartyUI.battle_state()
	await t.finished
	hide()


func _on_ability_pressed():
	if stage == &"root": ability.emit()
func _on_attack_pressed():
	attack.emit()
func _on_item_pressed():
	item.emit()
func _on_command_pressed():
	if stage == &"root": command.emit()
	if stage == &"command" and Bt.Seq.CanEscape: _on_escape()

func get_target(faction:Array[Actor]):
	if Bt.Action: return
	if foc!=null:
		foc.hide()
		foc.show()
	if Troop.is_empty():
		close()
		Bt.victory()
		return
	active = true
	stage = &"pre_target"
	TargetFaction = faction
	Bt.get_node("Canvas/Confirm").show()
	Bt.get_node("Canvas/Back").show()
	Bt.get_node("Canvas/Confirm").text = "Target"
	Bt.get_node("Canvas/Back").text = "Cancel"
	Bt.get_node("Canvas/Confirm").icon = Global.get_controller().ConfirmIcon
	Bt.get_node("Canvas/Back").icon = Global.get_controller().CancelIcon
	$"../Canvas/AttackTitle/Wheel".show_atk_color(CurrentChar.NextMove.WheelColor)
	if (CurrentChar.NextAction == "ability" and CurrentChar.NextMove.WheelColor.s > 0
	and CurrentChar.NextMove.Damage != 0):
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
	t.tween_property(Bt.get_node("Canvas/Confirm"), "position",
	Vector2(195,742), 0.3).from(Vector2(195,850))
	t.tween_property(Bt.get_node("Canvas/Back"), "position",
	Vector2(31,742), 0.4).from(Vector2(31,850))

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
	$"../Canvas/AttackTitle/RichTextLabel".text = Global.colorize(CurrentChar.NextMove.description)
	$"../Canvas/AttackTitle".text = CurrentChar.NextMove.name
	$"../Canvas/AttackTitle".icon = CurrentChar.NextMove.Icon

	if LastTarget == null or not LastTarget in faction:
		LastTarget = faction[0]
		TargetIndex = 0
	target = LastTarget
	if (TargetIndex >= faction.size() -1 or
	faction[TargetIndex].has_state("Knocked Out") or faction[TargetIndex].node == null):
		TargetIndex = 0
	target = faction[TargetIndex]
	t.tween_property(self, "position", target.node.position, 0.3)
	t.tween_property(Cam, "zoom", Vector2(4.5,4.5), 0.5)
	t.tween_property(Cam, "position", Vector2(target.node.position.x,
	target.node.position.y /4), 0.5)
	emit_signal('targetFoc', faction[TargetIndex])
	$"../Canvas/AttackTitle/Wheel".show_trg_color(target.MainColor)
	await t.finished
	stage = &"target"
	while stage == &"target":
		tr = create_tween()
		tr.set_ease(Tween.EASE_IN_OUT)
		tr.set_trans(Tween.TRANS_SINE)
		tr.tween_property($BaseRing/Ring2, "scale", -Vector2(0.1,0.1), 0.7).as_relative()
		if stage != "target": return
		tr.tween_property($BaseRing/Ring2, "scale", Vector2(0.1,0.1), 0.7).as_relative()
		await tr.finished

func _on_ability_returned(ab:Ability, tar):
	print("Using ", ab.name, " on ", tar.FirstName)
	close()

func move_menu():
	if stage == &"target" or stage == &"pre_target":
		#active= false
		t = create_tween()
		t.set_ease(Tween.EASE_IN_OUT)
		t.set_trans(Tween.TRANS_CUBIC)
		target = TargetFaction[TargetIndex]
		if target.node == null:
			Bt.fix_enemy_node_issues()
			move_menu()
			return
		t.set_parallel()
		t.tween_property(Cam, "position", Vector2(target.node.position.x,
		target.node.position.y /4), 0.5)
		t.tween_property(self, "position", target.node.position, 0.3)
		LastTarget = target
		emit_signal('targetFoc', TargetFaction[TargetIndex])
		$"../Canvas/AttackTitle/Wheel".show_trg_color(target.MainColor)
		await get_tree().create_timer(0.2).timeout
	if stage == &"ability":
		active= false
		await get_tree().create_timer(0.001).timeout
		t = create_tween()
		t.set_ease(Tween.EASE_IN_OUT)
		t.set_trans(Tween.TRANS_CUBIC)
		if not %AbilityList.get_child(MenuIndex).has_focus():
			%AbilityList.get_child(MenuIndex).grab_focus()
		if MenuIndex < 6:
			t.tween_property($AbilityUI/Margin/Scroller, "scroll_vertical", 0, 0.2)
		if MenuIndex >= 6:
			t.tween_property($AbilityUI/Margin/Scroller,
			"scroll_vertical", 80 + (MenuIndex-6) *70, 0.2)
		#print(MenuIndex)
		$DescPaper/Desc.text = Global.colorize(Abilities[MenuIndex].description)
		var color: Color = Abilities[MenuIndex].WheelColor
		if Abilities[MenuIndex].ColorSameAsActor or color == Color.WHITE: color = CurrentChar.MainColor
		$DescPaper/Title.add_theme_color_override("font_color",
		color - Color(0.2, 0.2, 0.2, 0))
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
	stage = "inactive"
	if CurrentChar.has_state("Confused") and randi_range(0, 5) > 0:
		var proper_tar:Actor = TargetFaction[TargetIndex]
		TargetFaction = TurnOrder
		TargetIndex = randi_range(0, TurnOrder.size()-1)
		while TargetFaction[TargetIndex] == proper_tar:
			TargetIndex = randi_range(0, TurnOrder.size()-1)
		await move_menu()
		confusion_msg()
	emit_signal("ability_returned", CurrentChar.NextMove, TargetFaction[TargetIndex])
	close()

func confusion_msg():
	var tar: Actor = TargetFaction[TargetIndex]
	if CurrentChar == tar:
		Global.toast(CurrentChar.FirstName+" hits "+CurrentChar.Pronouns[3]+" in Confusion!")
	elif tar in Bt.get_ally_faction(CurrentChar) and CurrentChar.NextMove.Target == Ability.T.ONE_ENEMY:
		Global.toast(CurrentChar.FirstName+" hits an ally in confusion!")
	else:
		Global.toast(CurrentChar.FirstName+" misses "+CurrentChar.Pronouns[2]+" target in Confusion!")

func _on_back_pressed():
	Global.cancel_sound()
	emit_signal(PrevStage)

func _on_focus_changed(control:Control):
	foc = control
	if control is Button:
		MenuIndex = control.get_index()
		move_menu()
	if stage == &"item":
		#print(control)
		focus_item(control)

func _on_ability_entry():
	if active:
		Global.confirm_sound()
		var ab:Ability = %AbilityList.get_child(MenuIndex).get_meta("Ability")
		match ab.Target:
			Ability.T.ONE_ENEMY:
				PrevStage="ability"
				stage = &"target"
				get_target(Bt.get_oposing_faction())
			Ability.T.ONE_ALLY:
				PrevStage="ability"
				stage = &"target"
				get_target(Bt.get_ally_faction())
			Ability.T.SELF:
				emit_signal("ability_returned", ab, CurrentChar)
				close()
			Ability.T.AOE_ALLIES:
				emit_signal("ability_returned", ab, Bt.get_ally_faction())
				close()
			Ability.T.ANY:
				PrevStage="ability"
				stage = &"target"
				get_target(Bt.TurnOrder)
			_:
				emit_signal("ability_returned", ab)
				close()

func _on_confirm_pressed():
	if active:
		if stage == &"pre_target":
			active = false
			Global.confirm_sound()
			while stage != "target": await Event.wait()
			targeted.emit()
		if stage == &"target":
			Global.confirm_sound()
			targeted.emit()
		if stage == &"item":
			if foc == null or foc.get_meta("ItemData") == null: return
			elif foc is Button and foc.get_meta("ItemData").Use != 0:
				var item: ItemData = foc.get_meta("ItemData")
				CurrentChar.NextTarget = CurrentChar
				#Item.use(foc.get_meta("ItemData"))
				Item.remove_item(foc.get_meta("ItemData"))
				if item.BattleEffect.Target == Ability.T.SELF:
					ability_returned.emit(item.BattleEffect, CurrentChar)
				Global.confirm_sound()

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
	if stage == &"command":
		stage = &"inactive"
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

func fetch_inventory():
	await Item.verify_inventory()
	for i in $Inventory/Margin/Consumables/Grid.get_children():
		i.queue_free()
	for i in $Inventory/Margin/BattleItems/Grid.get_children():
		i.queue_free()
	for item in Item.ConInv: if item.UsedInBattle:
		var dub =  $Inventory/Item.duplicate()
		dub.icon = item.Icon
		dub.set_meta("ItemData", item)
		if item.Quantity>1:
			dub.text = str(item.Quantity)
		else: dub.text = ""
		$Inventory/Margin/Consumables/Grid.add_child(dub)
		dub.show()
	for item in Item.BtiInv:
		var dub =  $Inventory/Item.duplicate()
		dub.icon = item.Icon
		dub.set_meta("ItemData", item)
		if item.Quantity>1:
			dub.text = str(item.Quantity)
		else: dub.text = ""
		$Inventory/Margin/BattleItems/Grid.add_child(dub)
		dub.show()
	await Event.wait()
	if $Inventory/Margin/Consumables/Grid.get_children().is_empty():
		$Inventory/Cbutton.disabled = true
		$Inventory/Margin.current_tab = 0
	elif $Inventory/Margin/BattleItems/Grid.get_children().is_empty():
		$Inventory/BIbutton.disabled = true
		$Inventory/Margin.current_tab = 1
	else:
		$Inventory/Margin.current_tab = 0
		_on_b_ibutton_pressed(true)
	if $Inventory/Cbutton.disabled and $Inventory/BIbutton.disabled:
		$Item.disabled = true
		return

func fetch_abilities():
	for n in %AbilityList.get_children():
		%AbilityList.remove_child(n)
		n.queue_free()
	for i in Abilities:
		var dub = %Ab0.duplicate()
		dub.show()
		%AbilityList.add_child(dub)
		dub.text = i.name
		dub.get_node("Icon").texture = i.Icon
		if i.AuraCost != 0:
			dub.get_child(0).text = str(i.AuraCost)
			dub.get_child(0).show()
		else:
			dub.get_child(0).hide()
		dub.name = "Item" + str(dub.get_index(true))
		dub.set_meta("Ability", i)
	for i in %AbilityList.get_children():
		if i.get_meta("Ability").AuraCost > CurrentChar.Aura or i.get_meta("Ability").disabled:
			if i.get_meta("Ability").AuraCost > CurrentChar.Aura:
				i.get_node("Label").add_theme_color_override("font_color", Color(1,0.25,0.32,0.5))
			i.disabled = true
			%AbilityList.get_children().push_back(i)

func focus_inv_default():
	if $Inventory/Margin/BattleItems/Grid.get_child_count() == 0:
		$Inventory/Margin.current_tab = 1
	else: $Inventory/Margin.current_tab = 0
	match $Inventory/Margin.current_tab:
		0: $Inventory/Margin/BattleItems/Grid.get_child(0).grab_focus()
		1: $Inventory/Margin/Consumables/Grid.get_child(0).grab_focus()

func _on_b_ibutton_pressed(tog:bool) -> void:
	if $Inventory/BIbutton.disabled: Global.buzzer_sound(); return
	if $Inventory/Margin.current_tab == 1: Global.confirm_sound()
	$Inventory/Cbutton.button_pressed = false
	$Inventory/Margin.current_tab = 0
	$Inventory/BIbutton.set_pressed_no_signal(true)
	$Inventory/Cbutton.set_pressed_no_signal(false)
	$Inventory/Margin/BattleItems/Grid.get_child(0).grab_focus()


func _on_cbutton_pressed(tog:bool) -> void:
	if $Inventory/Cbutton.disabled: Global.buzzer_sound(); return
	if $Inventory/Margin.current_tab == 0: Global.confirm_sound()
	$Inventory/Margin.current_tab = 1
	$Inventory/Cbutton.set_pressed_no_signal(true)
	$Inventory/BIbutton.set_pressed_no_signal(false)
	$Inventory/Margin/Consumables/Grid.get_child(0).grab_focus()

func focus_item(node:Button):
	if not node.get_parent() is GridContainer: return
	var item:ItemData = node.get_meta("ItemData")
	$Inventory/DescPaper/Title.text = item.Name
	$Inventory/DescPaper/Desc.text = Global.colorize(item.Description)
	$Inventory/DescPaper/Art.texture = item.Artwork
	if item.Quantity>1:
		$Inventory/DescPaper/Amount.text = str(item.Quantity) + " in bag"
		$Inventory/DescPaper/Amount.show()
	else:
		$Inventory/DescPaper/Amount.hide()
	if item.Use == 0:
		$"../Canvas/Confirm".hide()
	elif item.Use == ItemData.U.INSPECT:
		$"../Canvas/Confirm".show()
		$"../Canvas/Confirm".text = "Inspect"
	else:
		$"../Canvas/Confirm".show()
		$"../Canvas/Confirm".text = "Use"

