extends CanvasLayer

var chara: Actor
var slots: int
var setting:= false
var active_slot: int = 0

func _init() -> void:
	hide()

func draw_character(character: Actor):
	chara = character
	#Test
	Global.Complimentaries = ["FluidBlast", "RedShift", "Dispel"]
	chara.SkillLevel = 20
	chara.ComplimentaryList = {"FluidBlast":0, "RedShift":0}
	
	slots = chara.SkillLevel/10 + 1
	await chara.load_complimentaries()
	fetch_equiped_abilities()
	fetch_all_abilities()
	for i in slots-1:
		var grd =  $Background.get_child(0).duplicate()
		grd.set_meta("rate",  randf_range(-0.1, 0.1))
		$Background.add_child(grd)
		grd.rotation_degrees = randf_range(0, 360)
	for i in $Background.get_children(): i.modulate = Color.TRANSPARENT
	$Background.self_modulate = Color.TRANSPARENT
	$Title/Member.text = "[img width=58]%s[/img] %s %s" % [chara.PartyIcon.resource_path, chara.FirstName, chara.LastName]
	refresh()
	show()
	%Equipped.get_child(0).grab_focus()


func fetch_all_abilities():
	var Abilities = await Global.get_complimentaries()
	for n in %AbilityList.get_children():
		if n is Button:
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

func fetch_equiped_abilities():
	while chara.Complimentaries.size() > slots:
		chara.Complimentaries.remove_at(-1)
	var Abilities = chara.Complimentaries
	while slots > %Equipped.get_child_count():
		var dub = %Slot0.duplicate()
		dub.show()
		%Equipped.add_child(dub)
		dub.disabled = true
	var j = 0
	for i in Abilities:
		var dub = $Equipped.get_child(j)
		dub.disabled = false
		dub.text = i.name
		dub.get_node("Icon").texture = i.Icon
		if i.AuraCost != 0:
			dub.get_child(0).text = str(i.AuraCost)
			dub.get_child(0).show()
		else:
			dub.get_child(0).hide()
		dub.name = "Item" + str(dub.get_index(true))
		dub.set_meta("Ability", i)
		j += 1

func refresh():
	$Set.icon = Global.get_controller().ConfirmIcon
	$Back.icon = Global.get_controller().CancelIcon
	for i in %AbilityList.get_children():
		if not i is Button: continue
		if i.get_meta("Ability") in chara.Complimentaries:
			i.disabled = true
		else: i.disabled = false
	var t = create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUART)
	t.tween_property($Background, "self_modulate", chara.MainColor, 1)
	for i in $Background.get_child_count():
		if chara.Complimentaries.size() <= i:
			t.tween_property($Background.get_child(i), "modulate", Color.TRANSPARENT, 1)
		else:
			var color = chara.Complimentaries[i].WheelColor
			if chara.Complimentaries[i].WheelColor == Color.WHITE: color.a = 0.3
			else: color.a = 0.7
			t.tween_property($Background.get_child(i), "modulate", color, randf_range(0.5, 3))


func _on_list_focus_entered() -> void:
	Global.cursor_sound()
	var ab:Ability = get_viewport().gui_get_focus_owner().get_meta("Ability")
	if not is_instance_valid(ab): return
	if ab.WheelColor != Color.WHITE and not ab.ColorSameAsActor and ab.Damage != Ability.D.NONE:
		%Wheel.show()
		%Wheel.color = ab.WheelColor
		%Wheel.draw_wheel()
		%Wheel.draw_wheel()
	else: %Wheel.hide()
	%AttackTitle.text = ab.name
	%AttackTitle/RichTextLabel.text = Global.colorize(ab.description)

func _on_equipped_focus_entered() -> void:
	refresh()
	Global.cursor_sound()
	var foc = get_viewport().gui_get_focus_owner()
	if foc.has_meta("Ability"):
		var ab:Ability = foc.get_meta("Ability")
		if not is_instance_valid(ab): return
		if ab.WheelColor != Color.WHITE and not ab.ColorSameAsActor and ab.Damage != Ability.D.NONE:
			$Desc/Wheel.show()
			$Desc/Wheel.color = ab.WheelColor
			$Desc/Wheel.draw_wheel()
			$Desc/Wheel.draw_wheel()
		else: $Desc/Wheel.hide()
		$Desc/RichTextLabel.text = Global.colorize(ab.description)
	else:
		$Desc/RichTextLabel.text = "This slot is empty.\n\nPress [img width=48]"+Global.get_controller().ConfirmIcon.resource_path+"[/img] to equip one of the available Complimentary abilities to this slot."
		$Desc/Wheel.hide()

func _process(delta: float) -> void:
	for i: TextureRect in $Background.get_children():
		i.rotation_degrees += i.get_meta("rate")

func _on_back_pressed() -> void:
	if $AbilityPanel.visible:
		$AbilityPanel.hide()
		$Equipped.get_child(active_slot).grab_focus()
	else:
		if get_tree().root.has_node("MemberDetails"):
			get_tree().root.get_node("MemberDetails").inactive = false
			get_tree().root.get_node("MemberDetails/AbilityPanel/Border1/Scroller/AbilityList").get_child(1).grab_focus()
		queue_free()

func set_ability(slot: int):
	active_slot = slot
	$AbilityPanel.show()
	refresh()
	%AbilityList.get_child(0).grab_focus()

func _set_pressed():
	if $AbilityPanel.visible:
		_list_ability_pressed()
	else:
		_on_slot_pressed()

func _on_slot_pressed() -> void:
	var foc = get_viewport().gui_get_focus_owner()
	set_ability(foc.get_index())

func _list_ability_pressed():
	chara
