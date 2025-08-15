extends CanvasLayer
class_name Textbox

@onready var balloon: ColorRect = $Balloon
@onready var character_label: Label = $Balloon/Panel/CharacterLabel
@onready var dialogue_label := $Balloon/Panel2/DialogueLabel
@onready var responses_menu: VBoxContainer = $Balloon/Responses
@onready var response_template: Button = $Balloon/Responses/Button.duplicate(0)
var mem: TextProfile
var next_box: String = ""
var currun = false
var picture: Texture2D = null
@onready var t :Tween
const hold_time = 10


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

		if not is_instance_valid(next_dialogue_line):
			_on_close()
			return

		# Remove any previous responses
		for child in responses_menu.get_children():
			responses_menu.remove_child(child)
			child.queue_free()

		dialogue_line = next_dialogue_line
		var char_name = tr(dialogue_line.character, "dialogue")

		if dialogue_line.text == "(hide)" or dialogue_line.text == " ":
			await hide_box()
			next(dialogue_line.next_id)
			char_name = ""
			return

		$Balloon/Panel.visible = not dialogue_line.character.is_empty()
		while "." in char_name:
			#print(char_name)
			char_name = char_name.erase(char_name.length()-1)
		if "." in tr(dialogue_line.character, "dialogue"):
			var redraw: bool = true
			if character_label.text == char_name: redraw = false
			Global.portrait(tr(dialogue_line.character, "dialogue").replace(".", ""), redraw)
		if Global.find_member(char_name) == null:
			character_label.text = char_name
		else: character_label.text = Global.find_member(char_name).FirstName
		$Balloon/Panel.size.x = 1

		dialogue_line.text = dialogue_line.text.replace("/*", "[color=#787878]*")
		dialogue_line.text = dialogue_line.text.replace("*/", "*[/color]")

		var bord1:StyleBoxFlat = $Balloon/Panel2/Border1.get_theme_stylebox("panel")
		if next_box == "": next_box = char_name
		mem = await Global.match_profile(next_box)
		bord1.border_color = mem.Bord1
		$Balloon/Panel2/Border1.add_theme_stylebox_override("panel", bord1.duplicate())
		var bord2:StyleBoxFlat = $Balloon/Panel2/Border1/Border2.get_theme_stylebox("panel")
		bord2.border_color = mem.Bord2
		$Balloon/Panel2/Border1/Border2.add_theme_stylebox_override("panel", bord2.duplicate())
		var bord3:StyleBoxFlat = $Balloon/Panel2/Border1/Border2/Border3.get_theme_stylebox("panel")
		bord3.border_color = mem.Bord3
		$Balloon/Panel2/Border1/Border2/Border3.add_theme_stylebox_override("panel", bord3.duplicate())
		var inner:StyleBoxFlat = $Balloon/Panel2.get_theme_stylebox("panel")
		inner.bg_color = mem.Inner
		var nametag:StyleBoxFlat = $Balloon/Panel.get_theme_stylebox("panel")
		nametag.bg_color = mem.TextColor
		$Balloon/Panel.add_theme_stylebox_override("panel", nametag.duplicate())
		$Balloon/Panel/CharacterLabel.add_theme_color_override("font_color", mem.Inner)
		$Balloon/Panel2/InputIndicator.modulate = mem.TextColor
		$Balloon/Panel2/DialogueLabel.add_theme_color_override("default_color", mem.TextColor)
		$PictureFrame/Picture.texture = picture

		var glow_bord: StyleBoxFlat = $Balloon/Glow.get_theme_stylebox("panel")
		glow_bord.draw_center = true
		glow_bord.bg_color = mem.Bord1 + Color(-0.15, -0.15, -0.15)
		glow_bord.border_color = Color.TRANSPARENT

		dialogue_label.modulate.a = 0
		dialogue_label.custom_minimum_size.x = dialogue_label.get_parent().size.x - 1
		dialogue_label.dialogue_line = dialogue_line

		# Show any responses we have
		responses_menu.modulate.a = 0
		#await t.finished
		if dialogue_line.responses.size() > 0:
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
				item.connect("focus_entered", _on_button_focus_entered)
				item.modulate = Color.TRANSPARENT
			animate_responces()
		# Show our balloon
		draw_portrait()
		dialogue_label.text = ""

		if not balloon.visible and dialogue_line.text != " ":
			balloon.show()
			t = create_tween()
			t.set_parallel(true)
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_EXPO)
			t.tween_property($Balloon, "modulate", Color(1,1,1,1), 0.4).from(Color(0,0,0,0))
			t.tween_property($Balloon, "scale", Vector2(1,1), 0.4).from(Vector2(0.7,0.2))
		else:
			t = create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_BACK)
			t.tween_property($Balloon, "scale", Vector2(1,1), 0.2).from(Vector2(0.95,0.95))
		will_hide_balloon = false

		dialogue_label.modulate.a = 1
		await get_tree().create_timer(0.1).timeout
		dialogue_label.type_out_with_sound(mem.TextSound, mem.AudioFrequency, mem.PitchVariance)
		await dialogue_label.finished_typing

		# Wait for input
		if dialogue_line.responses.size() > 0:
			responses_menu.modulate.a = 1
			configure_menu()
		elif dialogue_line.time != "":
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
	response_template.hide()
	$Portrait.hide()
	$Hints.hide()
	balloon.hide()
	balloon.custom_minimum_size.x = balloon.get_viewport_rect().size.x
	
	match Global.Settings.TextSpeed:
		1:
			dialogue_label.seconds_per_step = 0.01
			dialogue_label.seconds_per_pause_step = 0.1
		2:
			dialogue_label.seconds_per_step = 0.001
			dialogue_label.seconds_per_pause_step = 0.05

	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
	#Engine.get_singleton("DialogueManager").dialogue_ended.connect(_on_close)

## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	Global.Controllable = false
	temporary_game_states = extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	#if not PartyUI.Expanded: PartyUI.UIvisible = false
	#await get_tree().create_timer(0.3).timeout
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)
	for i in get_tree().root.get_children():
		if i is Textbox and i != self:
			queue_free()


## Go to the next line
func next(next_id: String) -> void:
	next_box = ""
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


### Helpers


# Set up keyboard movement and signals for the response menu
func configure_menu() -> void:
	balloon.focus_mode = Control.FOCUS_NONE

	var items = get_responses()
	for i in items.size():
		var item: Control = items[i]

		item.focus_mode = Control.FOCUS_ALL

		item.focus_neighbor_left = item.get_path()
		item.focus_neighbor_right = item.get_path()

		if i == 0:
			item.focus_neighbor_top = item.get_path()
			item.focus_previous = item.get_path()
		else:
			item.focus_neighbor_top = items[i - 1].get_path()
			item.focus_previous = items[i - 1].get_path()

		if i == items.size() - 1:
			item.focus_neighbor_bottom = item.get_path()
			item.focus_next = item.get_path()
		else:
			item.focus_neighbor_bottom = items[i + 1].get_path()
			item.focus_next = items[i + 1].get_path()

		item.mouse_entered.connect(_on_response_mouse_entered.bind(item))
		item.gui_input.connect(_on_response_gui_input.bind(item))

	items[0].grab_focus()
	Global.Audio.stop()


# Get a list of enabled items
func get_responses() -> Array:
	var items: Array = []
	for child in responses_menu.get_children():
		if not "Disallowed" in child.name:
			items.append(child)

	return items


#func handle_resize() -> void:
#	if not is_instance_valid(margin):
#		call_deferred("handle_resize")
#		return
#
#	balloon.custom_minimum_size.y = margin.size.y
	# Force a resize on only the height
#	balloon.size.y = 0
#	var viewport_size = balloon.get_viewport_rect().size
#	balloon.global_position = Vector2((viewport_size.x - balloon.size.x) * 0.5, viewport_size.y - balloon.size.y)


### Signals

func _on_close() -> void:
	await hide_box()
	$Portrait.hide()
	Engine.time_scale = 1
	responses_menu.hide()
	Global.textbox_close.emit()
	if self != null: queue_free()

func hide_box():
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_CUBIC)
	if $Portrait.visible:
		t.tween_property($Portrait, "modulate", Color(0,0,0,0), 0.2)
		t.tween_property($Portrait, "position:x", -100, 0.2)
	t.tween_property(balloon, "modulate", Color(0,0,0,0), 0.2)
	t.tween_property($Fader, "color", Color(0,0,0,0), 0.5)
	t.tween_property(balloon, "scale", Vector2(0.9, 0.5), 0.2)
	await t.finished
	balloon.hide()
	Global.portrait_clear()
	$Portrait.texture = null
	Global.PortraitRedraw = true
	character_label.text = " "

func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	get_tree().create_timer(0.1).timeout.connect(func():
		if will_hide_balloon:
			will_hide_balloon = false)

func _on_response_mouse_entered(item: Control) -> void:
	if "Disallowed" in item.name: return

	item.grab_focus()

func _on_response_gui_input(event: InputEvent, item: Control) -> void:
	if "Disallowed" in item.name:
		return
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialogue_line.responses[item.get_index()].next_id)
		Global.confirm_sound()
	elif event.is_action_pressed("DialogNext") and item in get_responses():
		Global.confirm_sound()
		t = create_tween()
		t.set_parallel()
		t.set_trans(Tween.TRANS_QUART)
		t.tween_property(get_viewport().gui_get_focus_owner(), "position:x", -100, 0.2).as_relative()
		t.tween_property(get_viewport().gui_get_focus_owner(), "modulate", Color.TRANSPARENT, 0.2)
		for i in responses_menu.get_children():
			if get_viewport().gui_get_focus_owner() != i:
				t = create_tween()
				t.set_parallel()
				t.set_trans(Tween.TRANS_QUART)
				t.set_ease(Tween.EASE_IN)
				t.tween_property(i, "position:x", 500, 0.2).as_relative()
				await Event.wait(0.05, false)
		await t.finished
		if item == null or item.get_index() == -1: return
		next(dialogue_line.responses[item.get_index()].next_id)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Dash"):
		var hold_frames := 1
		t = create_tween()
		t.set_trans(Tween.TRANS_QUART)
		t.tween_property($Hints, "position:x", 1400, 0.5)
		if Input.is_action_just_pressed("Dash"):
			while Input.is_action_pressed("Dash"):
				hold_frames += 1
				await Event.wait()
				if hold_frames > hold_time:
					Engine.time_scale = 4
					var ev:= InputEventAction.new()
					ev.action = &"DialogNext"
					ev.pressed = true
					Input.parse_input_event(ev)
			#if Event.allow_skipping:
			#
			#else: Global.toast("Hold the button down to skip")
		Engine.time_scale = 1
		return
	
	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch:
		next(dialogue_line.next_id)
	elif (event.is_action_pressed("DialogNext")) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_pressed() and not event.is_action("DialogNext") and not (
			event.is_action(&"ui_left") or
			event.is_action(&"ui_right") or
			event.is_action(&"ui_up") or
			event.is_action(&"ui_down")
		) and is_waiting_for_input:
			#print(event)
			$Hints/Skip.icon = Global.get_controller().Dash
			$Hints/Advance.icon = Global.get_controller().ConfirmIcon
			$Hints.show()
			t = create_tween()
			t.set_trans(Tween.TRANS_QUART)
			t.tween_property($Hints, "position:x", 1188, 0.5).from(1400)
			await Event.wait(4, false)
			t = create_tween()
			t.set_trans(Tween.TRANS_QUART)
			t.tween_property($Hints, "position:x", 1400, 0.5)
			await t.finished
			$Hints.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

func draw_portrait() -> void:
	#await get_tree().create_timer(0.2).timeout
	if Global.HasPortrait:
		if not dialogue_line.text.begins_with("[color=Gray]*"):
			$Balloon/Arrow.show()
		else: $Balloon/Arrow.hide()
		var pan = $Balloon/Arrow.get_theme_stylebox("panel")
		pan.bg_color = mem.Bord1
		$Portrait.texture = Global.PortraitIMG
		$Portrait/Shadow.texture = $Portrait.texture
		Global.portrait_clear()
		$Portrait.show()
		if Global.PortraitRedraw:
			t=create_tween()
			t.set_parallel(true)
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUINT)
			t.tween_property($Balloon, "position:x", 160, 0.5)
			t.tween_property($Portrait, "modulate", Color(1,1,1,1), 0.8).from(Color(0,0,0,0))
			t.tween_property($Portrait, "position:x", 0, 0.8).from(-200)
			t.tween_property($Portrait/Shadow, "position", Vector2(-131, 150), 1).from(Vector2(0, 0))
	else:
		$Balloon/Arrow.hide()
		if $Portrait.visible:
			t=create_tween()
			t.set_parallel(true)
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUAD)
			t.tween_property($Balloon, "position:x", 0, 0.5)
			t.tween_property($Portrait/Shadow, "position", Vector2(0, 0), 0.2)
			t.tween_property($Portrait, "modulate", Color(0,0,0,0), 0.3)
			t.tween_property($Portrait, "position:x", -200, 0.3)
			await t.finished
		$Portrait.hide()

func _on_button_focus_entered() -> void:
	Global.cursor_sound()

func animate_responces():
	await dialogue_label.finished_typing
	Engine.time_scale = 1
	for i in responses_menu.get_children():
		if "Disallowed" in i.name:
			i.hide()
	for i in responses_menu.get_children():
		if i == null: continue
		t = create_tween()
		t.set_parallel(true)
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUAD)
		t.tween_property(i, "position:x", i.position.x, 0.3).from(500)
		t.tween_property(i, "modulate", Color.WHITE, 0.3).from(Color.TRANSPARENT)
		await Event.wait(0.1, false)
