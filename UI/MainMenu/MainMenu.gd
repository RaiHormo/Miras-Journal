extends CanvasLayer
var stage
var rootIndex =1
var t: Tween
var prevRootIndex =1
var zoom
@onready var Player:CharacterBody2D =get_parent()
@onready var Cam:Camera2D =get_parent().get_node('Camera2D')
@onready var Fader:ColorRect =get_parent().get_node("Fader")

func _ready():
	stage = "inactive"
	zoom = Cam.zoom
	Global.ui_sound("Menu")
	t=create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
	Player.z_index = 9
	t.tween_property(Cam, "position", Vector2(0, -6), 0.5)
	t.tween_property(Cam, "zoom", Vector2(5, 5), 0.5)
	t.tween_property(Fader, "color", Color(0,0,0,0.6), 0.5)
	$Inventory.hide()
	$Rail.hide()
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
		i.get_child(0).position.x = -30
		i.get_child(0).size.x = 64
		t.tween_property(i.get_child(0), "size:x", 190, 0.5)
		t.tween_property(i.get_child(0), "position:x", -90, 0.5)
	$Rail/ItemFollow/ItemButton.grab_focus()
	

func _input(event):
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
				$Base.play("Close")
				stage = "inactive"
				t=create_tween()
				t.set_ease(Tween.EASE_OUT)
				t.set_trans(Tween.TRANS_CUBIC)
				t.set_parallel()
				#t.tween_property($Base, "modulate", Color.TRANSPARENT, 0.8)
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
				t.tween_property(Fader, "color", Color(0,0,0,0), 0.5)
				t.tween_property(Cam, "position", Vector2(0, 0), 0.5)
				t.tween_property(Cam, "zoom", zoom, 0.5)
				await $Base.animation_finished
				Global.Controllable = true
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




func _on_journal_button_pressed():
	pass


func _on_item_button_pressed():
	stage="item"
	Global.confirm_sound()
	t=create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.set_parallel()
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
	t.tween_property($Inventory, "size", Vector2(640, 444), 0.3).from(Vector2.ZERO)
	t.tween_property($Inventory, "position", Vector2(803, 223), 0.3).from(Vector2(803, 446))
	


func _on_quest_button_pressed():
	pass # Replace with function body.


func _on_options_button_pressed():
	pass # Replace with function body.
