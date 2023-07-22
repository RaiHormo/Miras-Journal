extends Control
var TurnOrder: Array[Actor]
var CurrentChar: Actor
var Party: PartyData
var Troop: Array[Actor]
@onready var Cam = $"../Cam"
@onready var t= Tween
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

func _ready():
	t = create_tween()
	hide()

func _process(delta):
	#$BaseRing/Ring2.rotation += 0.001
	if stage=="target":
		$BaseRing/Ring2.rotation += 0.001
		if tweendone:
			tweendone = false
			t = create_tween()
			t.set_ease(Tween.EASE_IN_OUT)
			t.set_trans(Tween.TRANS_SINE)
			t.tween_property($BaseRing/Ring2, "scale", Vector2(1.1,1.1), 0.7)
			t.tween_property($BaseRing/Ring2, "scale", Vector2(1.2,1.2), 0.7)
			await t.finished
			tweendone = true
		

func _on_battle_get_control():
	Global.ui_sound("GetControl")
	active = true
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	Loader.battle_bars(1)
	get_parent().Action = false
	show()
	stage = "root"
	PrevStage= "root"
	$Attack.show()
	$Item.show()
	$Command.show()
	$Ability.show()
	Troop = get_parent().Troop
	TurnOrder = get_parent().TurnOrder
	CurrentChar = get_parent().CurrentChar
	Party = get_parent().Party
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
	for i in Abilities.size():
		dub = dub.duplicate()
		dub.name = "Item" + str(i)
		$AbilityUI/Margin/Scroller/List.add_child(dub)
		dub.text = Abilities[i].name
		dub.icon = Abilities[i].Icon
		if Abilities[i].AuraCost != 0:
			dub.get_child(0).text = str(Abilities[i].AuraCost)
		else:
			dub.get_child(0).hide()
	
	t.tween_property(Cam, "position", Vector2(0,0), 0.5)
	t.tween_property(Cam, "zoom", Vector2(4,4), 0.5)
	t.tween_property($Ability, "modulate", Color(1,1,1,1), 0.5).from(Color.TRANSPARENT)
	t.tween_property($Item, "modulate", Color(1,1,1,1), 0.5).from(Color.TRANSPARENT)
	t.tween_property($Command, "modulate", Color(1,1,1,1), 0.5).from(Color.TRANSPARENT)
	t.tween_property($Attack, "modulate", Color(1,1,1,1), 0.5).from(Color.TRANSPARENT)
	t.tween_property($Ability, "size", Vector2(33,-33), 0.5).from(Vector2(31,33))
	t.tween_property($Attack, "size", Vector2(33,33), 0.5).from(Vector2(31,33))
	t.tween_property($Item, "size", Vector2(33,33), 0.5).from(Vector2(31,33))
	t.tween_property($Command, "size", Vector2(33,33), 0.5).from(Vector2(31,33))
	t.tween_property(self, "rotation_degrees", -720, 0.5).from(360)
	t.tween_property(self, "scale", Vector2(1,1), 0.5).from(Vector2(0.25,0.25))
	t.tween_property($BaseRing, "scale", Vector2(0.25,0.25), 0.1)
	t.tween_property($BaseRing/Ring2, "scale", Vector2(1,1), 0.1)
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
	t.kill()
	t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	stage = "root"
	PrevStage= "root"
	get_parent().get_node("EnemyUI").all_enemy_ui()
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
	t.tween_property($BaseRing/Ring2, "rotation_degrees", -600, 0.3).as_relative()
	t.tween_property(Cam, "position", Vector2(0,0), 0.5)
	t.tween_property(Cam, "zoom", Vector2(4,4), 0.5)
	t.tween_property(self, "scale", Vector2(1,1), 0.3)
	t.tween_property(self, "position", CurrentChar.node.position, 0.3)
	t.tween_property(self, "rotation_degrees", -720, 0.5)
	t.tween_property($BaseRing, "scale", Vector2(0.25,0.25), 0.3)
	t.tween_property($BaseRing/Ring2, "scale", Vector2(1,1), 0.3)
	t.tween_property($Arrow, "modulate", Color(0,0,0,0), 0.3)
	tweendone = false
	active = true
	$Attack.show()
	$Item.show()
	$Command.show()
	$Ability.show()

func _input(event):
	if active:
		if stage == "root":
			if Input.is_action_just_pressed("BtAttack"):
				attack.emit()
			if Input.is_action_just_pressed("BtAbility"):
				ability.emit()
		if stage == "target":
			if Input.is_action_just_pressed(Global.confirm()):
				Global.confirm_sound()
				targeted.emit()
				close()
			if Input.is_action_just_pressed(Global.cancel()):
				if PrevStage != stage:
						Global.cancel_sound()
						emit_signal(PrevStage)
			if Input.is_action_just_pressed("ui_down") and active:
				if Troop.size() == 1:
					Global.buzzer_sound()
					return
				if TargetIndex!=Troop.size() -1:
					TargetIndex += 1
				else:
					TargetIndex = 0
				while Troop[TargetIndex].has_state("Knocked Out"):
					if TargetIndex!=Troop.size() -1:
						TargetIndex += 1
					else:
						TargetIndex = 0
				Global.cursor_sound()
				move_menu()
			if Input.is_action_just_pressed("ui_up") and active:
				if Troop.size() == 1:
					Global.buzzer_sound()
					return
				if TargetIndex!=0:
					TargetIndex -= 1
				else:
					TargetIndex = Troop.size() -1
				Global.cursor_sound()
				while Troop[TargetIndex].has_state("Knocked Out"):
					if TargetIndex!=0:
						TargetIndex -= 1
					else:
						TargetIndex = Troop.size() -1
				move_menu()
		if stage == "ability":
			if Input.is_action_just_pressed(Global.cancel()):
				CurrentChar.node.play("Idle")
				Global.cancel_sound()
				root.emit()
			if Input.is_action_just_pressed(Global.confirm()) and active:
				Global.confirm_sound()
				if Abilities[MenuIndex].Target == 1:
					PrevStage="ability"
					stage = "target"
					get_target()
				if Abilities[MenuIndex].Target == 0:
					emit_signal("ability_returned", Abilities[MenuIndex], CurrentChar)
					close()
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

func _on_attack():
	Global.confirm_sound()
	stage="attack"
	CurrentChar.NextAction = "attack"
	active = false
	get_target()
	CurrentChar.NextMove = CurrentChar.StandardAttack
	#await targeted
	

func _on_ability():
	active= false
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
	t.tween_property($Ability, "size", Vector2(115,33), 0.3)
	t.tween_property(self, "position", CurrentChar.node.position, 0.3)
	t.tween_property($AbilityUI, "modulate", Color(1,1,1,1), 0.1)
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
	stage = "ability"
	t.tween_property($DescPaper, "scale", Vector2(0.17,0.17), 0.4)
	t.tween_property($DescPaper, "rotation_degrees", 0, 0.4) 
	t.tween_property($DescPaper, "modulate", Color(1,1,1,1), 0.4)
	t.tween_property($Attack, "position", Vector2(-20,90), 0.3).as_relative()
	t.tween_property($Item, "position", Vector2(-90,10), 0.3).as_relative()
	t.tween_property($Command, "position", Vector2(-20,-60), 0.3).as_relative()
	t.tween_property($Arrow, "modulate", Color(0.9,0.9,0.9,1), 0.3)
	$Ability.focus_mode = 0
	MenuIndex = 0
	$AbilityUI/Margin/Scroller/List/Item0.grab_focus()
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
	
func close():
	active=false
	t.kill()
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property($Ability, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Item, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Command, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Attack, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Ability, "size", Vector2(33,-33), 0.2)
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
	get_parent().get_node("PartyUI").battle_state()
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

func get_target():
	t.kill()
	t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	
	t.tween_property($Ability, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Item, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Command, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Attack, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Ability, "size", Vector2(33,-33), 0.2)
	t.tween_property($Attack, "size", Vector2(33,33), 0.2)
	t.tween_property($Item, "size", Vector2(33,33), 0.2)
	t.tween_property($Command, "size", Vector2(33,33), 0.2)
#	t.tween_property(self, "rotation_degrees", 360, 0.2)
	
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
	if not LastTarget in Troop:
		LastTarget = Troop[0]
		TargetIndex = 0
	target = LastTarget
	while Troop[TargetIndex].has_state("Knocked Out") or Troop[TargetIndex].node ==null:
		if TargetIndex!=Troop.size() -1:
			TargetIndex += 1
		else:
			TargetIndex = 0
	target = Troop[TargetIndex]
	t.tween_property(self, "position", target.node.position, 0.3)
	t.tween_property(Cam, "position", Vector2(50, target.node.position.y /4), 0.5)
	emit_signal('targetFoc', Troop[TargetIndex])
	await t.finished
	active = true
	stage = "target"
	tweendone = true

func _on_ability_returned(ab, tar):
	close()

func move_menu():
	active= false
	t.kill()
	t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	if stage == "target":
		target= Troop[TargetIndex]
		t.set_parallel()
		t.tween_property(Cam, "position", Vector2(50, target.node.position.y/5), 0.5)
		t.tween_property(self, "position", target.node.position, 0.3)
		LastTarget = target
		emit_signal('targetFoc', Troop[TargetIndex])
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
		CurrentChar.NextMove = CurrentChar.Abilities[MenuIndex]
		if Abilities[MenuIndex].AuraCost != 0:
			$DescPaper/Cost.text = str("Cost ", str(Abilities[MenuIndex].AuraCost))
			$DescPaper/Cost.show()
		else:
			$DescPaper/Cost.hide()
	$DescPaper/Title.text = Abilities[MenuIndex].name
	active= true
	tweendone = true
	


func _on_battle_next_turn():
	if not get_parent().CurrentChar.Controllable:
		hide()
		active = false


func _on_targeted():
	emit_signal("ability_returned", CurrentChar.NextMove, target )

