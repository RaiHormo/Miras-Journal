extends CanvasLayer

#a
@onready var balloon: ColorRect = $Balloon
@onready var character_label: Label = null
@onready var dialogue_label := $Balloon/Panel2/DialogueLabel
@onready var responses_menu: VBoxContainer = null
@onready var response_template: Button = null
@onready var Portrait: TextureRect = $Balloon/Margin/Portrait
var currun = false
@onready var t :Tween = get_tree().create_tween()

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## The current line
var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		is_waiting_for_input = false
		$Balloon/Panel2/InputIndicator.hide()

		if not next_dialogue_line:
			return


		dialogue_line = next_dialogue_line

		#$Balloon/Panel.visible = not dialogue_line.character.is_empty()
		#character_label.text = tr(dialogue_line.character, "dialogue")
		var bord1:StyleBoxFlat = $Balloon/Panel2/Border1.get_theme_stylebox("panel")
		var mem = await Global.match_profile(tr(dialogue_line.character, "dialogue"))
		bord1.border_color = mem.Bord1
		$Balloon/Panel2/Border1.add_theme_stylebox_override("panel", bord1.duplicate())
		var bord2:StyleBoxFlat = $Balloon/Panel2/Border1/Border2.get_theme_stylebox("panel")
		bord2.border_color = mem.Bord2
		$Balloon/Panel2/Border1/Border2.add_theme_stylebox_override("panel", bord2.duplicate())
		var bord3:StyleBoxFlat = $Balloon/Panel2/Border1/Border2/Border3.get_theme_stylebox("panel")
		bord3.border_color = mem.Bord3
		$Balloon/Panel2/Border1/Border2/Border3.add_theme_stylebox_override("panel", bord3.duplicate())


		dialogue_label.modulate.a = 0
		dialogue_label.custom_minimum_size.x = dialogue_label.get_parent().size.x - 1
		dialogue_label.dialogue_line = dialogue_line

		# Show any responses we have
		#responses_menu.modulate.a = 0
		t = create_tween()
		t.set_parallel(true)
		#await t.finished
		if dialogue_line.responses.size() > 0:
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUAD)
			for response in dialogue_line.responses:
				# Duplicate the template so we can grab the fonts, sizing, etc
				var item: Button = response_template.duplicate(0)
				item.name = "Response%d" % responses_menu.get_child_count()
				if not response.is_allowed:
					item.name = String(item.name) + "Disallowed"
					item.modulate.a = 0.4
				item.text = response.text
				item.show()

				responses_menu.add_child(item)
				t.tween_property(responses_menu, "position", Vector2(832 ,318), 1).from(Vector2(2000, 318))
		# Show our balloon
		draw_portrait()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_BACK)
		dialogue_label.text = ""

		if not balloon.visible:
			balloon.show()
			t.tween_property($Balloon, "modulate", Color(1,1,1,1), 0.3).from(Color(0,0,0,0))
			t.tween_property($Balloon, "scale", Vector2(1,1), 0.3).from(Vector2(0.7,0.2))
#		else:
#			t.tween_property($Balloon, "scale", Vector2(1,1), 0.2).from(Vector2(0.9,0.9))
		will_hide_balloon = false

		dialogue_label.modulate.a = 1
		await get_tree().create_timer(0.2).timeout
		if not dialogue_line.text.is_empty():
			var prof = await Global.match_profile(tr(dialogue_line.character, "dialogue"))
			dialogue_label.type_out(prof.TextSound, prof.AudioFrequency, prof.PitchVariance)
			await dialogue_label.finished_typing
		# Wait for input
#		if dialogue_line.responses.size() > 0:
#			responses_menu.modulate.a = 1
#			configure_menu()
		if dialogue_line.time != null:
			var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next(dialogue_line.next_id)
		else:
			is_waiting_for_input = true
			$Balloon/Panel2/InputIndicator.show()
			balloon.focus_mode = Control.FOCUS_ALL
			balloon.grab_focus()
	get:
		return dialogue_line


func _ready() -> void:
#	response_template.hide()
	Portrait.hide()
	balloon.hide()
	balloon.custom_minimum_size.x = balloon.get_viewport_rect().size.x

	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
	Engine.get_singleton("DialogueManager").close.connect(_on_close)



## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	#Global.Controllable = false
	temporary_game_states = extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	#PartyUI.UIvisible = false
	#await get_tree().create_timer(0.3).timeout
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)



### Signals

func _on_close() -> void:
	t=create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_CUBIC)
	#responses_menu.hide()
	if Portrait.visible:
		t.tween_property(Portrait, "modulate", Color(0,0,0,0), 0.2)
#		t.tween_property(Portrait, "position", Vector2(-300, 389), 0.2)
	t.tween_property(balloon, "modulate", Color(0,0,0,0), 0.2)
	t.tween_property(balloon, "scale", Vector2(0.9, 0.5), 0.2)
	await t.finished
	Portrait.hide()
	balloon.hide()
	queue_free()

func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	get_tree().create_timer(0.1).timeout.connect(func():
		if will_hide_balloon:
			will_hide_balloon = false

			)





func draw_portrait():
	#await get_tree().create_timer(0.2).timeout
	if Global.HasPortrait:
		Portrait.texture = Global.PortraitIMG
		Global.portrait_clear()
		Portrait.show()
		if Global.PortraitRedraw:
			t=create_tween()
			t.set_parallel(true)
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_CUBIC)
			t.tween_property(Portrait, "modulate", Color(1,1,1,1), 0.3).from(Color(0,0,0,0))
			#t.tween_property(Portrait, "position", Vector2(-55, 389), 0.3).from(Vector2(-200, 389))
	else:
		if Portrait.visible:
			t=create_tween()
			t.set_parallel(true)
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_CUBIC)
			t.tween_property(Portrait, "modulate", Color(0,0,0,0), 0.2)
			#t.tween_property(Portrait, "position", Vector2(-200, 389), 0.3)
			await get_tree().create_timer(0.2).timeout
		Portrait.hide()

