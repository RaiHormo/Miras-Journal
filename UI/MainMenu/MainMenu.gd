extends CanvasLayer
var stage
var rootIndex =1
var t: Tween
var prevRootIndex =1
var zoom
@onready var Player:CharacterBody2D =get_parent()
@onready var Cam:Camera2D =get_parent().get_node('Camera2D')
@onready var Fader =get_parent().get_node("Fader")
var PrevCtrl:Control = null
var KeyInv :Array[ItemData]

func _ready():
	Player.bag_anim()
	$DescPaper.hide()
	$Confirm.show()
	$Back.show()
	$Confirm.text = "Select"
	$Back.text = "Close"
	get_viewport().connect("gui_focus_changed", _on_focus_changed)
	Fader.show()
	stage = "inactive"
	zoom = Cam.zoom
	Global.ui_sound("Menu")
	t=create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	t.tween_property($Confirm, "position", Vector2(195,742), 0.3).from(Vector2(195,850))
	t.tween_property($Back, "position", Vector2(31,742), 0.4).from(Vector2(31,850))
	Player.get_node("Base/Shadow").z_index = -1
	Player.z_index = 9
	for i in $Rail.get_children():
		i.get_child(0).position = Vector2(-30, -30)
		i.get_child(0).size.x = 64
	t.tween_property(Cam, "position", Vector2(0, -6), 0.5)
	t.tween_property(Cam, "zoom", Vector2(5, 5), 0.5)
	t.tween_property(Fader, "modulate", Color(0,0,0,0.6), 0.5)
	t.tween_property(Fader.material, "shader_parameter/lod", 1.0, 0.5).from(0.0)
	get_inventory()
	$Confirm.icon = Global.get_controller().ConfirmIcon
	$Back.icon = Global.get_controller().CancelIcon
	$Inventory.hide()
	#$Rail.hide()
	$Base.play("Open")
	rootIndex=1
	move_root()
	await $Base.animation_finished
	stage = "root"
	t=create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	$Rail.show()
	for i in $Rail.get_children():
		t.tween_property(i.get_child(0), "size:x", 190, 0.5)
		t.tween_property(i.get_child(0), "position:x", -90, 0.5)
	$Rail/ItemFollow/ItemButton.grab_focus()


func _input(event):
	if Global.LastInput==Global.ProcessFrame: return
	if Input.is_action_just_pressed(Global.confirm()):
		PrevCtrl.emit_signal("pressed")
	$Confirm.icon = Global.get_controller().ConfirmIcon
	$Back.icon = Global.get_controller().CancelIcon
	match stage:
		"root":
			if Input.is_action_just_pressed("ui_up"):
				if rootIndex == 0:
					Global.buzzer_sound()
				else:
					Global.cursor_sound()
					prevRootIndex = rootIndex
					rootIndex -= 1
					move_root()
			elif Input.is_action_just_pressed("ui_down"):
				if rootIndex == 3:
					Global.buzzer_sound()
				else:
					Global.cursor_sound()
					prevRootIndex = rootIndex
					rootIndex += 1
					move_root()
			elif Input.is_action_just_pressed(Global.cancel()):
				Global.cancel_sound()
				close()
		"item":
			if Input.is_action_just_pressed(Global.cancel()):
				Global.cancel_sound()
				_root()

func _on_focus_changed(control:Control):
	if stage == "item":
		if PrevCtrl == control or control == null:
			#Global.buzzer_sound()
			pass
		else: 
			Global.cursor_sound()
	PrevCtrl = control

func close():
	$Base.play("Close")
	stage = "inactive"
	Player.z_index = 1
	Player.get_node("Base/Shadow").z_index = 0
	get_tree().paused = false
	t.kill()
	t=create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_parallel()
	t.tween_property($Rail/JournalFollow, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($Rail/QuestFollow, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($Rail/OptionsFollow, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($Rail/JournalFollow, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($Rail/ItemFollow, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($Rail/OptionsFollow, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($Rail/JournalFollow/JournalButton, "size:x", 64, 0.3)
	t.tween_property($Rail/JournalFollow/JournalButton, "position:x", -30, 0.3)
	t.tween_property($Rail/ItemFollow/ItemButton, "size:x", 64, 0.3)
	t.tween_property($Rail/ItemFollow/ItemButton, "position:x", -30, 0.3)
	t.tween_property($Rail/QuestFollow/QuestButton, "size:x", 64, 0.3)
	t.tween_property($Rail/QuestFollow/QuestButton, "position:x", -30, 0.3)
	t.tween_property($Rail/OptionsFollow/OptionsButton, "size:x", 64, 0.3)
	t.tween_property($Rail/OptionsFollow/OptionsButton, "position:x", -30, 0.3)
	t.tween_property($Confirm, "position", Vector2(195,850), 0.4)
	t.tween_property($Back, "position", Vector2(31,850), 0.3)
	t.tween_property(Fader, "modulate", Color(0,0,0,0), 0.5)
	t.tween_property(Fader.material, "shader_parameter/lod", 0.0, 0.5)
	t.tween_property(Cam, "position", Vector2(0, 0), 0.5)
	t.tween_property(Cam, "zoom", zoom, 0.5)
	PartyUI.UIvisible = true
	await $Base.animation_finished
	Global.Controllable = true
	Fader.hide()
	queue_free()

func move_root():
		var button : Button = $Rail.get_child(rootIndex).get_child(0)
		button.grab_focus()
		t=create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_CUBIC)
		t.set_parallel()
		if rootIndex==0:
			if prevRootIndex == 1:
				t.set_trans(Tween.TRANS_BACK)
				$Base.play("ItemJournal")
			t.tween_property($Rail/JournalFollow/JournalButton, "scale", Vector2(1.2,1.2), 0.3)
			t.tween_property($Rail/ItemFollow/ItemButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/QuestFollow/QuestButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/OptionsFollow/OptionsButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/JournalFollow, "progress", 540, 0.3)
			t.tween_property($Rail/ItemFollow, "progress", 660, 0.3)
			t.tween_property($Rail/QuestFollow, "progress", 770, 0.3)
			t.tween_property($Rail/OptionsFollow, "progress", 880, 0.3)
			t.tween_property($Rail/JournalFollow, "rotation_degrees", -5, 0.3)
			t.tween_property($Rail/ItemFollow, "rotation_degrees", 5, 0.3)
			t.tween_property($Rail/QuestFollow, "rotation_degrees", 25, 0.3)
			t.tween_property($Rail/OptionsFollow, "rotation_degrees", 35, 0.3)
		if rootIndex==1:
			if prevRootIndex == 0:
				$Base.play("JournalItem")
			if prevRootIndex == 2:
				$Base.play("QuestItem")
				t.set_trans(Tween.TRANS_BACK)
			t.tween_property($Rail/JournalFollow/JournalButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/ItemFollow/ItemButton, "scale", Vector2(1.2,1.2), 0.3)
			t.tween_property($Rail/QuestFollow/QuestButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/OptionsFollow/OptionsButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/JournalFollow, "progress", 460, 0.3)
			t.tween_property($Rail/ItemFollow, "progress", 587, 0.3)
			t.tween_property($Rail/QuestFollow, "progress", 709, 0.3)
			t.tween_property($Rail/OptionsFollow, "progress", 817, 0.3)
			t.tween_property($Rail/JournalFollow, "rotation_degrees", -15, 0.3)
			t.tween_property($Rail/ItemFollow, "rotation_degrees", 0, 0.3)
			t.tween_property($Rail/QuestFollow, "rotation_degrees", 15, 0.3)
			t.tween_property($Rail/OptionsFollow, "rotation_degrees", 25, 0.3)
		if rootIndex==2:
			if prevRootIndex == 1:
				$Base.play("ItemQuest")
			if prevRootIndex == 3:
				$Base.play("OptionsQuest")
				t.set_trans(Tween.TRANS_BACK)
			t.tween_property($Rail/JournalFollow/JournalButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/ItemFollow/ItemButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/QuestFollow/QuestButton, "scale", Vector2(1.2,1.2), 0.3)
			t.tween_property($Rail/OptionsFollow/OptionsButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/JournalFollow, "progress", 380, 0.3)
			t.tween_property($Rail/ItemFollow, "progress", 490, 0.3)
			t.tween_property($Rail/QuestFollow, "progress", 590, 0.3)
			t.tween_property($Rail/OptionsFollow, "progress", 700, 0.3)
			t.tween_property($Rail/JournalFollow, "rotation_degrees", -20, 0.3)
			t.tween_property($Rail/ItemFollow, "rotation_degrees", -10, 0.3)
			t.tween_property($Rail/QuestFollow, "rotation_degrees", 0, 0.3)
			t.tween_property($Rail/OptionsFollow, "rotation_degrees", 15, 0.3)
		if rootIndex==3:
			if prevRootIndex == 2:
				$Base.play("QuestOptions")
			t.tween_property($Rail/JournalFollow/JournalButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/ItemFollow/ItemButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/QuestFollow/QuestButton, "scale", Vector2(1,1), 0.3)
			t.tween_property($Rail/OptionsFollow/OptionsButton, "scale", Vector2(1.2,1.2), 0.3)
			t.tween_property($Rail/JournalFollow, "progress", 300, 0.3)
			t.tween_property($Rail/ItemFollow, "progress", 420, 0.3)
			t.tween_property($Rail/QuestFollow, "progress", 540, 0.3)
			t.tween_property($Rail/OptionsFollow, "progress", 650, 0.3)
			t.tween_property($Rail/JournalFollow, "rotation_degrees", -45, 0.3)
			t.tween_property($Rail/ItemFollow, "rotation_degrees", -25, 0.3)
			t.tween_property($Rail/QuestFollow, "rotation_degrees", -10, 0.3)
			t.tween_property($Rail/OptionsFollow, "rotation_degrees", 5, 0.3)

func _root():
	t.kill()
	#stage="inactive"
	stage="root"
	$Confirm.text = "Select"
	$Back.text = "Close"
	PartyUI.UIvisible = true
	t=create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	t.tween_property($DescPaper, "rotation_degrees", -75, 0.3)
	t.tween_property($DescPaper, "scale", Vector2(0.1,0.1), 0.3)
	t.tween_property($DescPaper, "modulate", Color(0,0,0,0), 0.2)
	for i in $Rail.get_children():
		t.tween_property(i.get_child(0), "size:x", 190, 0.3)
		t.tween_property(i.get_child(0), "position", Vector2(-90, -30), 0.3).from(Vector2(-90, -130))
		t.tween_property(i, "modulate", Color.WHITE, 0.3)
		i.z_index=0
		i.get_child(0).toggle_mode = false
	move_root()
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Inventory, "size", Vector2.ZERO, 0.3)
	t.tween_property($Inventory, "modulate", Color.TRANSPARENT, 0.2)
	t.tween_property($Inventory, "position", (Vector2(803, 400)), 0.3)
	t.tween_property(Cam, "position", Vector2(0 ,-6), 0.5)
	t.tween_property($Base, "position", Vector2(643 ,421), 0.8)
	t.tween_property($Rail, "position", Vector2(458 ,235), 0.8).from(Vector2(0 ,235))
	await t.finished
	$Inventory.hide()
	

func _journal():
	pass


func _item():
	PartyUI.UIvisible = false
	$DescPaper.show()
	$Confirm.text = "Use"
	$Back.text = "Back"
	t.kill()
	stage="inacive"
	Global.confirm_sound()
	t=create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	$Rail/ItemFollow/ItemButton.toggle_mode = true
	$Rail/ItemFollow/ItemButton.set_pressed_no_signal(true)
	$Rail/ItemFollow.z_index = 1
	t.tween_property($DescPaper, "rotation_degrees", 0, 0.4).from(-30)
	t.tween_property($DescPaper, "scale", Vector2(0.7,0.7), 0.4)
	t.tween_property($DescPaper, "modulate", Color.WHITE, 0.4)
	t.tween_property($Inventory, "modulate", Color.WHITE, 0.1)
	t.tween_property($Rail/JournalFollow, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($Rail/QuestFollow, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($Rail/OptionsFollow, "modulate", Color.TRANSPARENT, 0.3)
	t.tween_property($Rail/JournalFollow/JournalButton, "size:x", 64, 0.5)
	t.tween_property($Rail/JournalFollow/JournalButton, "position:x", -30, 0.5)
	t.tween_property($Rail/QuestFollow/QuestButton, "size:x", 64, 0.5)
	t.tween_property($Rail/QuestFollow/QuestButton, "position:x", -30, 0.5)
	t.tween_property($Rail/OptionsFollow/OptionsButton, "size:x", 64, 0.5)
	t.tween_property($Rail/OptionsFollow/OptionsButton, "position:x", -30, 0.5)
	t.tween_property($Rail/JournalFollow, "progress", 587, 0.3)
	t.tween_property($Rail/ItemFollow, "progress", 587, 0.3)
	t.tween_property($Rail/QuestFollow, "progress", 587, 0.3)
	t.tween_property($Rail/OptionsFollow, "progress", 587, 0.3)
	$Inventory.show()
	t.tween_property($Inventory, "size", Vector2(547, 549), 0.3).from(Vector2.ZERO)
	t.tween_property($Inventory, "position", Vector2(241, 123), 0.3).from(Vector2(803, 446))
	t.tween_property(Cam, "position", Vector2(100 ,-6), 0.3)
	t.tween_property($Base, "position", Vector2(-500 ,0), 0.6).as_relative()
	if not Item.KeyInv.is_empty():
		$Inventory/Margin/Scroller/Vbox/KeyItems.get_child(0).grab_focus()
	t.tween_property($Rail/ItemFollow/ItemButton, "position", Vector2(-500, -340), 0.3)
	await t.finished
	stage="item"


func _quest():
	pass # Replace with function body.


func _options():
	pass # Replace with function body.




func _on_confirm_button_down():
	Global.buzzer_sound()


func _on_back_button_down():
	Global.cancel_sound()
	match stage:
		"root":
			close()
		"item":
			_root()
		
func get_inventory():
	for item in Item.KeyInv:
		var dub =  $Inventory/Margin/Scroller/Vbox/KeyItems/Item.duplicate()
		dub.icon = item.Icon
		$Inventory/Margin/Scroller/Vbox/KeyItems.add_child(dub)
	$Inventory/Margin/Scroller/Vbox/KeyItems/Item.queue_free()
