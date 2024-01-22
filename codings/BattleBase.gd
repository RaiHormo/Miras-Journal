extends Control
class_name Battle
@export var Party: PartyData
@export var Seq: BattleSequence= Loader.Seq
@export var Troop: Array[Actor]
@export var TurnOrder: Array[Actor]
@export var Turn: int = 0
@onready var CurrentChar: Actor = Global.Party.Leader
@export var TurnInd: int = -1
signal GetControl
@onready var t = Tween
var dub
var initial
@export var curve:Curve
signal next_turn
signal check_party
signal anim_done
signal take_dmg
var CurrentAbility: Ability = Global.Party.Leader.StandardAttack
var PartyArray: Array[Actor] = []
var Action: bool
var CurrentTarget: Actor
var AwaitVictory = false
var count: int
var totalSP: int = 0
var callout_onscreen := false

func _ready():
	Global.Bt = self
	Global.Controllable = false
	$Cam.make_current()
	Loader.InBattle = true
	TurnInd= -1
	Turn = 0
	Seq = Loader.Seq.duplicate()
	Party = Global.Party
	for i in Seq.Enemies.size():
		Seq.Enemies[i-1] = Seq.Enemies[i-1].duplicate(true)
	Troop = Seq.Enemies
	Party.Leader.node = $Act/Actor0
	TurnOrder.push_front(Party.Leader)
	PartyArray.push_back(Party.Leader)
	$Background.texture = Seq.BattleBack
	if Seq.BattleBack == null:
		$Act/Actor0.light_mask = 1
	if Seq.PositionSameAsPlayer: Seq.ScenePosition = Global.Player.global_position + Vector2(45,0)
	global_position = Seq.ScenePosition
	global_position = Vector2i(global_position)
	$Act/Actor0.sprite_frames = Party.Leader.BT
	$Act/Actor0.animation = &"Entrance"
	$Act/Actor0.frame = 0
	$Act/Actor0/Shadow.modulate = Color.WHITE
	$Canvas/Callout.modulate = Color.TRANSPARENT
	$Canvas/SPGain.hide()
	$Canvas/VictoryItems.hide()
	if Global.Area != null: Global.Area.show()
	if Global.check_member(1):
		dub = $Act/Actor0.duplicate()
		dub.name = "Actor1"
		$Act.add_child(dub)
		Party.Member1.node = $Act/Actor1
		dub.sprite_frames = Party.Member1.BT
		TurnOrder.push_front(Party.Member1)
		PartyArray.push_back(Party.Member1)
		dub.material = dub.material.duplicate()
		dub.add_child(Party.Member1.SoundSet.instantiate())
	if Global.check_member(2):
		dub = $Act/Actor0.duplicate()
		dub.name = "Actor2"
		$Act.add_child(dub)
		dub.sprite_frames = Party.Member2.BT
		Party.Member2.node = $Act/Actor2
		TurnOrder.push_front(Party.Member2)
		PartyArray.push_back(Party.Member2)
		dub.material = dub.material.duplicate()
		dub.add_child(Party.Member2.SoundSet.instantiate())
	if Global.check_member(3):
		dub = $Act/Actor0.duplicate()
		dub.name = "Actor3"
		$Act.add_child(dub)
		dub.sprite_frames = Party.Member3.BT
		Party.Member3.node = $Act/Actor3
		PartyArray.push_back(Party.Member3)
		TurnOrder.push_front(Party.Member3)
		dub.material = dub.material.duplicate()
		dub.add_child(Party.Member3.SoundSet.instantiate())
	for i in Troop.size():
		dub = $Act/Actor0.duplicate()
		dub.name = "Enemy" + str(i)
		$Act.add_child(dub)
		TurnOrder.push_front(Troop[i])
		Troop[i].node = dub
		dub.sprite_frames = Troop[i].BT
		dub.material = dub.material.duplicate()
		dub.offset = Troop[i].Offset
		dub.play("Idle")
		Troop[i].Health = Troop[i].MaxHP
		Troop[i].Aura = Troop[i].MaxAura
		dub.add_child(Troop[i].SoundSet.instantiate())
	if Loader.BtAdvantage == 1:
		for i in TurnOrder:
			if not i.IsEnemy: i.Speed += 5
	elif Loader.BtAdvantage == 2:
		for i in TurnOrder:
			if i.IsEnemy: i.Speed += 5
	TurnOrder.sort_custom(speed_sort)
	$Act/Actor0.add_child(Party.Leader.SoundSet.instantiate())
	for i in TurnOrder.size():
		print(TurnOrder[i].Speed, " - ", TurnOrder[i].FirstName)
	for i in TurnOrder:
		i.node.get_node("State").play("None")
		if not i.Shadow:
				i.node.get_child(0).hide()
		if i.IsEnemy: i.node.get_node("Glow").energy = i.GlowDef
		else:
			t = create_tween()
			t.tween_property(i.node.get_node("Glow"), "energy", i.GlowDef, 1)
		i.node.get_node("Glow").color = i.MainColor
	position_sprites()
	turn_ui_init()
	if Loader.Attacker != null: Loader.Attacker.hide()
	await entrance()

func speed_sort(a, b):
	if a.Speed > b.Speed:
		return true
	elif a.Speed == b.Speed:
		if a.IsEnemy:
			return false
		else:
			return true
	else:
		return false

func turn_ui_init():
	for i in TurnOrder:
		var entr = $Canvas/TurnOrderPop/Margin/List.get_child(0).duplicate()
		entr.get_node("Icon").texture = i.PartyIcon
		entr.get_node("Name").text = i.FirstName
		entr.set_meta("Actor", i)
		$Canvas/TurnOrderPop/Margin/List.add_child(entr)
	if $Canvas/TurnOrderPop/Margin/List.get_child(0).name == "Char":
		$Canvas/TurnOrderPop/Margin/List/Char.queue_free()

func turn_ui_check():
	for i in $Canvas/TurnOrderPop/Margin/List.get_children():
		if i.get_meta("Actor") == CurrentChar: i.get_node("Arrow").show()
		else: i.get_node("Arrow").hide()

func position_sprites():
	$Act/Actor0.show()
	if Global.number_of_party_members()==1:
		$Act/Actor0.position = Vector2(-45,0)
	if Global.number_of_party_members()==2:
		$Act/Actor0.position = Vector2(-45,-15)
		$Act/Actor1.show()
		$Act/Actor1.position = Vector2(-45,45)
	if Global.number_of_party_members()==3:
		$Act/Actor0.position = Vector2(-45,-25)
		$Act/Actor1.show()
		$Act/Actor1.position = Vector2(-45,15)
		$Act/Actor2.show()
		$Act/Actor2.position = Vector2(-45,55)
	if Global.number_of_party_members()==4:
		$Act/Actor0.position = Vector2(-45,-35)
		$Act/Actor1.show()
		$Act/Actor1.position = Vector2(-45,0)
		$Act/Actor2.show()
		$Act/Actor2.position = Vector2(-45,35)
		$Act/Actor3.show()
		$Act/Actor3.position = Vector2(-45,70)
	for i in TurnOrder:
		pixel_perfectize(i)


	if Troop.size() == 1:
		$Act/Enemy0.show()
		$Act/Enemy0.position = Vector2(66,0)
	if Troop.size() == 2:
		if $Act.has_node("Enemy0"):
			$Act/Enemy0.show()
			$Act/Enemy0.position = Vector2(66,-15)
		if $Act.has_node("Enemy1"):
			$Act/Enemy1.show()
			$Act/Enemy1.position = Vector2(46,30)
	if Troop.size() == 3:
		if $Act.has_node("Enemy0"):
			$Act/Enemy0.show()
			$Act/Enemy0.position = Vector2(66,-25)
		if $Act.has_node("Enemy1"):
			$Act/Enemy1.show()
			$Act/Enemy1.position = Vector2(36,15)
		if $Act.has_node("Enemy2"):
			$Act/Enemy2.show()
			$Act/Enemy2.position = Vector2(66,55)

func entrance():
	t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUART)
	if Seq.Transition:
		$Cam.zoom = Vector2(5,5)
		$Cam.position = Vector2(90,10)
		PartyUI.UIvisible = false
		if Troop.size()<3:
			Loader.battle_bars(3)
		else:
			Loader.battle_bars(2)
		t.tween_property($Cam, "zoom", Vector2(5.5,5.5), 0.5)
		t.parallel().tween_property($Cam, "position", Vector2(90,10), 0.5)
		t.tween_property($Cam, "position", Vector2(-50,10), 0.5).set_delay(0.5)
		await get_tree().create_timer(0.3).timeout
		$EnemyUI.all_enemy_ui()
		if Loader.BtAdvantage == 1:
			for i in Troop: damage(i, 1, false, 24/Troop.size())
		await get_tree().create_timer(0.5).timeout
	else:
		t.tween_property($Cam, "position", Vector2(-50,10), 0.5)
		$Cam.global_position = Global.get_cam().global_position
		$Cam.zoom = Global.get_cam().zoom
	for i in PartyArray:
		entrance_anim(i)
	Loader.battle_bars(2)
	await get_tree().create_timer(0.5).timeout
	if not Seq.Transition: $EnemyUI.all_enemy_ui()
	PartyUI.UIvisible = true
	PartyUI.battle_state()
	await get_tree().create_timer(0.7).timeout
	next_turn.emit()

func entrance_anim(i: Actor):
	play_sound("Entrance", i)
	await anim(&"Entrance", i)
	anim(&"Idle")

func _on_next_turn():
	if Troop.size() == 0:
		victory()
		return
	#position_sprites()
	Turn += 1
	if TurnOrder.size() -1 <= TurnInd:
		TurnInd = 0
	else:
		TurnInd += 1
	CurrentChar = TurnOrder[TurnInd]
	if CurrentChar.node == null:
		_on_next_turn()
		return
	print("-------------------------------------------------")
	print("Turn: ", Turn, " - Index: ", TurnInd, " - Name: ", CurrentChar.FirstName)
	initial = CurrentChar.node.position
	if CurrentChar.has_state("Knocked Out"):
		if CurrentChar.IsEnemy:
			Troop.erase(CurrentChar)
			TurnOrder.erase(CurrentChar)
			if Troop.is_empty():
				victory()
				return
			else:
				end_turn()
				return
		else:
			end_turn()
			return
	$Act.handle_states()


func make_move():
	if CurrentChar.Controllable:
		print("Control")
		GetControl.emit()
	else:
		$AI.ai()

func _on_ai_chosen():
	confirm_next()

func confirm_next(action_anim = true):
	if CurrentChar.Controllable: $BattleUI.close()
	if action_anim:
		match CurrentChar.NextAction:
			"Ability":
				var tl = create_tween()
				tl.set_ease(Tween.EASE_OUT)
				tl.set_trans(Tween.TRANS_QUART)
				focus_cam(CurrentChar)
				#tl.tween_property($Cam, "zoom", Vector2(5,5), 0.3)
				tl.parallel().tween_property($Cam, "zoom", Vector2(5.5,5.5), 0.3)
				callout(CurrentChar.NextMove)
				anim("Ability")
				var timer = get_tree().create_timer(1)
				await CurrentChar.node.animation_finished
				if timer.time_left != 0: await timer.timeout
	_on_battle_ui_ability_returned(CurrentChar.NextMove, CurrentChar.NextTarget)

func _input(event):
	if Input.is_action_just_pressed("DebugR"):
		end_battle()
	if Input.is_action_just_pressed("DebugV"):
		for i in Troop:
			death(i)
		$BattleUI.close()
		victory()
	if Input.is_action_pressed("Dash") and Action:
			Engine.time_scale = 8
	elif (not Action) or Input.is_action_just_released("Dash"):
		Engine.time_scale = 1
	if AwaitVictory:
		if Input.is_action_just_released("ui_accept"):
			end_battle()
	if Input.is_action_just_pressed("DebugF"):
		print(relation_to_dmg_modifier(color_relation(CurrentChar.MainColor, $BattleUI.target.MainColor)))


func _on_battle_ui_ability():
	if CurrentChar.node == null: return
	if $BattleUI.PrevStage == "root":
		play_sound("Ability", CurrentChar)
		anim("Ability")
		await CurrentChar.node.animation_finished
	anim("AbilityLoop")

func _on_battle_ui_root():
	stop_sound("Ability", CurrentChar)
	anim("Idle")

func callout(ab:Ability = CurrentAbility):
	if not ab.Callout:
		return
	var tc = create_tween()
	tc.set_ease(Tween.EASE_OUT)
	tc.set_trans(Tween.TRANS_QUINT)
	if callout_onscreen:
		tc.tween_property($Canvas/Callout, "modulate", Color.TRANSPARENT, 0.2)
		await tc.finished
		tc = create_tween()
		tc.set_ease(Tween.EASE_OUT)
		tc.set_trans(Tween.TRANS_QUINT)
	callout_onscreen = true
	if ab.ColorSameAsActor: ab.WheelColor = CurrentChar.MainColor
	$Canvas/Callout.text = ab.name
	$Canvas/Callout.add_theme_color_override("font_color", ab.WheelColor)
	tc.tween_property($Canvas/Callout, "position", Vector2(37, 636), 2).from(Vector2(400, 636))
	tc.parallel().tween_property($Canvas/Callout, "modulate", Color.WHITE, 2).from(Color.TRANSPARENT)
	#await tc.finished
	#print("call")
	tc.set_ease(Tween.EASE_IN)
	if CurrentChar.Controllable:
		tc.tween_property($Canvas/Callout, "position", Vector2(-200, 636), 0.5).set_delay(1)
	else: tc.tween_property($Canvas/Callout, "position", Vector2(-200, 636), 0.5).set_delay(4)
	tc.parallel().tween_property($Canvas/Callout, "modulate", Color.TRANSPARENT, 0.5)
	await tc.finished
	callout_onscreen = false

func _on_battle_ui_ability_returned(ab :Ability, tar:Actor):
	CurrentChar.NextAction = ""
	CurrentChar.NextMove = null
	CurrentChar.NextTarget = null
	CurrentAbility = ab
	CurrentTarget = tar
	if ab == null:
		end_turn()
		return
	if ab.ColorSameAsActor:
		ab.WheelColor = CurrentChar.MainColor
	if ab.Target == 1:
		if tar.has_state("Knocked Out"):
			var i = -1
			var oldtar = CurrentTarget.FirstName
			while CurrentTarget.FirstName == oldtar or CurrentTarget.has_state("Knocked Out") or CurrentTarget.node == null:
				i += 1
				if i>get_ally_faction(CurrentTarget).size():
					if get_ally_faction(CurrentTarget)[0].IsEnemy:
						victory()
						return
					else:
						game_over()
						return
				CurrentTarget = get_ally_faction(CurrentTarget)[i-1]
		if tar.IsEnemy:
			$BattleUI.emit_signal("targetFoc", tar)
	elif ab.Target == 0:
		if CurrentChar.IsEnemy:
			$BattleUI.emit_signal("targetFoc", CurrentChar)
	if CurrentChar.IsEnemy:
		$BattleUI.emit_signal("targetFoc", CurrentChar)
	if ab.ActionSequence != &"":
		CurrentChar.add_aura(-CurrentAbility.AuraCost)
		if CurrentAbility.Callout and CurrentChar.Controllable:
			callout()
		$Act.play(ab.ActionSequence, CurrentTarget)
	else:
		end_turn()
		return


###################################################

func jump_to_target(character, tar, offset, time):
	t = create_tween()
	var target = tar.node.position + offset
	var start = character.node.position
	var jump_distance : float = start.distance_to(target)
	var jump_height : float = jump_distance * 0.5 #will need tweaking
	var midpoint = start.lerp(target, 0.5) + Vector2.UP * jump_height
	var jump_time = jump_distance * (time * 0.001) #will also need tweaking, this controls how fast the jump is
	t.tween_method(Global._quad_bezier.bind(start, midpoint, target, character.node), 0.0, 1.0, jump_time)
	await t.finished
	anim_done.emit()

func return_cur(target:Actor = CurrentChar):
	var tc= create_tween()
	tc.set_trans(Tween.TRANS_QUAD)
	tc.set_ease(Tween.EASE_OUT)
	tc.tween_property(target.node, "position", initial, 0.2)
	await tc.finished

func end_turn():
	Global.check_party.emit()
	if Seq.check_events():
		await Seq.call_events()
	Seq.reset_events()
	await get_tree().create_timer(0.3).timeout
	if CurrentChar.node != null:
		CurrentChar.node.z_index = 0
	next_turn.emit()

func damage(target: Actor, is_magic:= false, elemental:= false, x: int = calc_num(), effect:= true, limiter:= false, ignore_stats:= false):
	take_dmg.emit()
	var el_mod: float = 1
	if elemental:
		var relation = color_relation(CurrentAbility.WheelColor, target.MainColor)
		if relation == "wk": pop_num(target, "WEAK")
		if relation == "op": pop_num(target, "WEAK!")
		if relation == "res": pop_num(target, "RESIST")
		print(relation)
		el_mod = relation_to_dmg_modifier(relation)
	print("Attack power: ", x, " * ", el_mod)
	var dmg = target.calc_dmg(x * el_mod, is_magic, CurrentChar)
	if ignore_stats: dmg = x
	target.damage(dmg, limiter)
	print(CurrentChar.FirstName + " deals " + str(dmg) + " damage to " + target.FirstName)
	check_party.emit()
	if CurrentAbility.RecoverAura: CurrentChar.add_aura(dmg/2)
	if elemental: pop_num(target, dmg, CurrentAbility.WheelColor)
	else: pop_num(target, dmg)
	if target.Health == 0:
		await death(target)
		return
	if target.has_state("Guarding"):
		pass
	else:
		if effect and elemental:
			if el_mod > 1:
				target.node.get_node("Particle").emitting = true
			t = create_tween()
			t.set_ease(Tween.EASE_IN)
			t.set_trans(Tween.TRANS_QUART)
			target.node.material.set_shader_parameter("outline_enabled", true)
			target.node.material.set_shader_parameter("outline_color", target.MainColor)
			target.node.get_node("Particle").process_material.gravity = Vector3(offsetize(120), 0, 0)
			target.node.get_node("Particle").process_material.color = target.MainColor
			t.tween_property(target.node.material, "shader_parameter/outline_color", Color.TRANSPARENT, 0.5)
		else: play_sound("Hit", target)
		hit_animation(target)
		await t.finished
		target.node.material.set_shader_parameter("outline_enabled", false)


func hit_animation(tar):
	anim("Hit", tar)
	await tar.node.animation_finished
	anim("Idle", tar)


func screen_shake(amount:float = 15, times:float = 7, ShakeDuration:float = 0.2):
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	var dur = ShakeDuration/times
	var am  = amount
	for i in range(0, times):
		am = am - (amount/times)
		#print(am)
		#print(amount, " / ", times, " = ",amount/times)
		t.tween_property($Cam, "offset", Vector2(randi_range(-am,am), randi_range(-am,am)), dur).as_relative()
		t.tween_property($Cam, "offset", Vector2.ZERO, dur)

func calc_num():
	var base: int
	match CurrentAbility.Damage:
		0: base = 0
		1: base = 12
		2: base = 24
		3: base = 48
		4: base = 96
	if CurrentAbility.DmgVarience:
		base = int(base * randf_range(0.8, 1.2))
	return base

func play_effect(stri: String, tar:Actor, offset = Vector2.ZERO):
	if $Act/Effects.sprite_frames.has_animation(stri):
		var ef:AnimatedSprite2D = $Act/Effects.duplicate()
		$Act.add_child(ef)
		ef.position = tar.node.position + offset
		ef.play(stri)
		await ef.animation_finished
		ef.queue_free()

func offsetize(num, target=CurrentChar):
	if target == null: return num
	if CurrentAbility != null and CurrentAbility.Target == 0:
		return 0
	if target.IsEnemy:
		return -num
	else:
		return num

func pop_num(target:Actor, text, color: Color = Color.WHITE):
		var number:Label = target.node.get_node("Nums").duplicate()
		target.node.add_child(number)
		number.modulate = Color.TRANSPARENT
		number.show()
		number.add_theme_color_override("font_color", color)
		var tn = create_tween()
		tn.set_ease(Tween.EASE_IN)
		tn.set_trans(Tween.TRANS_QUART)
		number.text = str(text)
		var off:int = 1
		if text is String: off = 0
		tn.tween_property(number, "position", Vector2(offsetize(20*off)*
			randf_range(0.8,1.2), -10*randf_range(0.8,1.2)), 0.3).as_relative().from(Vector2(-217, -36))
		tn.parallel().tween_property(number, "modulate", Color.WHITE, 0.3).from(Color.TRANSPARENT)
		tn.set_ease(Tween.EASE_OUT)
		tn.tween_property(number, "modulate", Color.TRANSPARENT, 2).from(Color.WHITE)
		tn.parallel().tween_property(number, "position", Vector2(offsetize(14*off)*
			randf_range(0.8,1.2), -6*randf_range(0.8,1.2)), 2).as_relative()
		await tn.finished
		if number!=null:
			number.queue_free()

func play_sound(SoundName: String, act: Actor):
	if act.node.get_node("SFX").has_node(SoundName):
		act.node.get_node("SFX").get_node(SoundName).play()

func stop_sound(SoundName: String, act: Actor):
	if act.node.get_node("SFX").has_node(SoundName):
		act.node.get_node("SFX").get_node(SoundName).stop()

func death(target:Actor):
	if target == null or target.has_state("KnockedOut"): return
#	if target.IsEnemy and Troop.size() == 1:
#		slowmo()
	target.States.clear()
	target.node.get_node("State").play("None")
	target.add_state("KnockedOut")
	if target.IsEnemy: totalSP += target.RecivedSP
	anim("KnockOut", target)
	target.node.get_node("Particle").emitting = true
	t = create_tween()
	target.Health = 0
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	target.node.material.set_shader_parameter("outline_enabled", true)
	target.node.material.set_shader_parameter("outline_color", target.MainColor)
	target.node.get_node("Particle").process_material.gravity = Vector3(offsetize(120), 0, 0)
	target.node.get_node("Particle").process_material.color = target.MainColor
	t.parallel().tween_property(target.node.get_node("Shadow"), "modulate", Color.TRANSPARENT, 0.5)
	t.parallel().tween_property(target.node.material, "shader_parameter/outline_color", Color.TRANSPARENT, 0.5)
	await t.finished
	if target.node != null:
		target.node.material.set_shader_parameter("outline_enabled", false)
		if target.Disappear:
			t = create_tween()
			t.tween_property(target.node, "modulate", Color.TRANSPARENT, 0.5)
			t.tween_property(target.node.get_node("Glow"), "energy", 0, 0.5)
			await t.finished
			if target != null:
				target.node.queue_free()
				target.node = null
				if target.IsEnemy:
					Troop.erase(target)
					TurnOrder.erase(target)

func slowmo(timescale = 0.5, time= 1):
	Engine.time_scale = 0.5
	await Event.wait(time * timescale)
	Engine.time_scale = 1

func get_ally_faction(act: Actor = CurrentChar):
	if act.IsEnemy: return Troop
	else: return PartyArray

func get_oposing_faction(act: Actor = CurrentChar):
	if act.IsEnemy: return PartyArray
	else: return Troop


func hp_sort(a:Actor, b:Actor):
	if a.Health==0:
		return false
	if a.Health <= b.Health:
		return true
	else:
		return false

func anim(animation: String="Idle", chara: Actor = CurrentChar):
	if animation not in chara.node.sprite_frames.get_animation_names(): return
	if animation in chara.GlowAnims and chara.GlowSpecial != 0:
		t=create_tween()
		chara.node.get_node("Glow").color = chara.MainColor
		t.tween_property(chara.node.get_node("Glow"), "energy", chara.GlowSpecial, 1)
	elif chara.node.animation in chara.GlowAnims and chara.GlowSpecial != 0:
		t.kill()
		t=create_tween()
		chara.node.get_node("Glow").color = chara.MainColor
		t.tween_property(chara.node.get_node("Glow"), "energy", chara.GlowDef, 0.3)
	chara.node.play(animation)
	pixel_perfectize(chara)
	await chara.node.animation_finished

func pixel_perfectize(chara: Actor, xy: int = 0):
	if int(chara.node.sprite_frames.get_frame_texture(chara.node.animation, chara.node.frame).get_size()[xy]) % 2 == 0:
		chara.node.offset[xy] = chara.Offset[xy]
	else: chara.node.offset[xy] = chara.Offset[xy] + 0.5
	if xy == 0: pixel_perfectize(chara, 1)

func glow(amount:float = 1, time = 1, chara:Actor = CurrentChar):
	t.kill()
	t=create_tween()
	t.tween_property(chara.node.get_node("Glow"), "energy", amount, time)

func focus_cam(chara:Actor, time:float=0.5, offset=-40):
	var tc = create_tween()
	tc.set_ease(Tween.EASE_IN_OUT)
	tc.set_trans(Tween.TRANS_QUART)
	tc.tween_property($Cam, "position", Vector2(chara.node.position.x - offsetize(offset),chara.node.position.y /2), time)

func move(chara:Actor, pos:Vector2, time:float, mode:Tween.EaseType = Tween.EASE_IN_OUT, offset:Vector2 = Vector2.ZERO):
	t = create_tween()
	t.set_ease(mode)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(chara.node, "position", pos + offset, time)
	await t.finished
	anim_done.emit()

func heal(target:Actor, amount: int = int(max(calc_num(), target.MaxHP*((calc_num()*CurrentChar.Magic)*0.02)))):
	target.add_health(amount)
	check_party.emit()
	PartyUI._check_party()
	pop_aura(target)
	pop_num(target, "+"+str(amount))

func pop_aura(target: Actor, time:float=0.5):
	target.node.material.set_shader_parameter("outline_enabled", true)
	target.node.material.set_shader_parameter("outline_color", Color.WHITE)
	await get_tree().create_timer(time).timeout
	t = create_tween()
	t.parallel().tween_property(target.node.material, "shader_parameter/outline_color", Color.TRANSPARENT, 0.5)
	await t.finished
	target.node.material.set_shader_parameter("outline_enabled", false)

func victory():
	print("Victory!")
	$Canvas.layer = 1
	Loader.BattleResult = 1
	for i in PartyArray:
		victory_anim(i)
	t = create_tween()
	$Canvas/Callout.text = "Victory"
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT)
	t.set_parallel()
	$EnemyUI/EnemyFocus.hide()
	$Canvas/TurnOrder.hide()
	$Canvas/Callout.add_theme_color_override("font_color", Color.WHITE)
	$Canvas/Callout.scale = Vector2(1.5,1.5)
	PartyUI._on_expand(2)
	$Canvas/DottedBack.show()
	t.tween_property($Canvas/DottedBack, "modulate", Color(0.188,0.188,0.188,0.8), 1).from(Color(0.188,0.188,0.188,0))
	t.tween_property($Canvas/Callout, "position", Vector2(700, 50), 2).from(Vector2(1200, 50))
	t.tween_property($Canvas/Callout, "modulate", Color.WHITE, 2).from(Color.TRANSPARENT)
	t.tween_property($Cam, "position", Vector2(-20,10), 1)
	t.tween_property($Cam, "zoom", Vector2(5,5), 1)
	victory_count_sp()
	victory_show_items()
	Loader.battle_bars(0)
	$EnemyUI.colapse_root()
	AwaitVictory = true
	if Global.Player != null:
		Global.Player.global_position = $Act/Actor0.global_position
		if Party.check_member(1):
			Global.Area.get_node("Follower1").global_position = $Act/Actor1.global_position
		if Party.check_member(2):
			Global.Area.get_node("Follower3").global_position = $Act/Actor2.global_position
		if Party.check_member(3):
			Global.Area.get_node("Follower3").global_position = $Act/Actor3.global_position
		Global.get_cam().global_position = Global.Player.global_position

func escape():
	print("Escaped")
	Loader.BattleResult = 2
	end_battle()

func game_over():
	print("The party was wiped out")
	end_battle()

func end_battle():
	if Global.Area == null: Loader.travel_to("Debug"); queue_free(); return
	for i in TurnOrder:
		for j in i.States: if j.RemovedOnBattleEnd: i.States.erase(j)
	await Loader.end_battle()
	queue_free()

func victory_anim(chara:Actor):
	chara.node.get_node("State").play("None")
	anim("Victory", chara)
	await chara.node.animation_finished
	anim("VictoryLoop", chara)

func victory_count_sp():
	await Event.wait(0.7)
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT)
	t.set_parallel()
	$Canvas/SPGain.show()
	t.tween_property($Canvas/SPGain, "position:x", 918, 0.5).from(1000)
	t.tween_property($Canvas/SPGain, "modulate", Color.WHITE, 0.5).from(Color.TRANSPARENT)
	t.tween_property($Canvas/SPGain, "size:x", 260, 0.5).from(1)
	t.tween_property($Canvas/SPGain/VBoxContainer/Text, "custom_minimum_size:x", 140, 0.5).from(1)
	await t.finished
	var sp = totalSP
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT)
	t.tween_property(self, "count", sp, 2).from(0)
	while $Canvas/SPGain/VBoxContainer/Number.text != str(sp):
		$Canvas/SPGain/VBoxContainer/Number.text = str(count)
		await Event.wait()
	var dub = $Canvas/SPGain.duplicate()
	for i in PartyArray:
		i.add_SP(totalSP)
	Global.check_party.emit()
	$Canvas.add_child(dub)
	await Event.wait()
	t = create_tween()
	t.set_parallel()
	t.tween_property(dub, "scale", Vector2(1.5, 1.5), 0.3)
	t.tween_property(dub, "modulate", Color.TRANSPARENT, 0.3)
	await t.finished
	dub.queue_free()

func victory_show_items():
	await Event.wait(2)
	for i in $Canvas/VictoryItems.get_children():
		i.modulate = Color.TRANSPARENT
	await Event.wait()
	$Canvas/VictoryItems.show()
	for i in $Canvas/VictoryItems.get_children():
		t = create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUINT)
		t.set_parallel()
		t.tween_property(i, "modulate", Color.WHITE, 0.5).from(Color.TRANSPARENT)
		t.tween_property(i, "position:x", i.position.x, 0.5).from(i.position.x+500)
		await t.finished
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT)
	$Canvas/TurnOrder.show()
	$Canvas/TurnOrder.icon = Global.get_controller().ConfirmIcon
	$Canvas/TurnOrder.text = "Continue"
	t.tween_property($Canvas/TurnOrder, "position:x", 1060, 0.5).from(1500)

func miss(target:Actor = CurrentTarget):
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	play_effect("Miss", target)
	t.tween_property(target.node, "position:x", target.node.position.x + offsetize(30), 0.3)
	pop_num(target, "Miss")
	await Event.wait(0.5)
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(target.node, "position:x", target.node.position.x - offsetize(30), 0.3)

func _on_battle_ui_command():
	anim("Command")

func add_to_troop(en: Actor):
	Troop.append(en)
	dub = $Act/Actor0.duplicate()
	dub.name = "Enemy" + str(Troop.size())
	$Act.add_child(dub)
	TurnOrder.push_front(en)
	en.node = dub
	dub.sprite_frames = en.BT
	dub.material = dub.material.duplicate()
	dub.offset = en.Offset
	anim(&"Idle", en)
	en.Health = en.MaxHP
	en.Aura = en.MaxAura
	dub.add_child(en.SoundSet.instantiate())
	position_sprites()

func color_relation(attacker:Color, defender:Color) -> String:
	var affinity = Global.get_affinity(attacker)
	var def = Global.get_affinity(defender)
	if def.hue in affinity.oposing_range: return "op"
	elif def.hue in affinity.weak_range: return "wk"
	elif def.hue in affinity.resist_range: return "res"
	elif def.hue in affinity.near_range: return "res"
	else: return "n"

func relation_to_dmg_modifier(relation:String) -> float:
	var base: float
	var value_mod: float = remap(CurrentChar.MainColor.v, 0,1,2,1)
	if relation == "op": base = 2 * value_mod
	elif relation == "wk": base = 1.5 * value_mod
	elif relation == "res": base = 0.5
	else: return 1
	return round(base*10)/10

func zoom(am:float = 5, time = 0.5, ease := Tween.EASE_IN_OUT):
	t = create_tween()
	t.set_ease(ease)
	t.tween_property($Cam, "zoom", Vector2(am,am), time)
	await t.finished

func _on_battle_ui_item() -> void:
	await anim("Bag")
	anim("BagLoop")

func shake_actor(chara := CurrentTarget, amount := 2, repeat := 5, time := 0.03):
	for i in repeat:
		t = create_tween()
		t.tween_property(chara.node, "position:x", amount, time).as_relative()
		t.tween_property(chara.node, "position:x", -amount*2, time*2).as_relative()
		t.tween_property(chara.node, "position:x", amount, time).as_relative()
		await t.finished

func stat_change(stat: StringName, amount: float, chara := CurrentChar, turns: int = 3):
	var updown: String
	if amount > 0: updown = "Up"
	else: updown = "Down"
	match stat:
		&"Atk": chara.AttackMultiplier += amount
		&"Mag": chara.MagicMultiplier += amount
		&"Def": chara.DefenceMultiplier += amount
	chara.add_state(stat + updown)
	await Event.wait(1.2)
	pop_num(chara, stat_name(stat) + " x" + str(amount), (await Global.get_state(stat + updown)).color)

func stat_name(stat: StringName) -> String:
	match stat:
		&"Atk": return "Attack"
		&"Def": return "Defense"
		&"Mag": return "Magic"
		_: return "Stat"

func on_state_add(state: State, chara: Actor):
	add_state_effect(state, chara)
	match state.name:
		"Guarding":
			chara.Defence *= 2

func add_state_effect(state: State, chara: Actor):
	if chara.node.get_node_or_null(state.name) == null and chara.node.get_node("State").sprite_frames.has_animation(state.name):
		var dub = chara.node.get_node("State").duplicate()
		dub.name = state.name
		chara.node.add_child(dub)
		dub.play(state.name)

func remove_state_effect(state: State, chara: Actor):
	if chara.node.get_node_or_null(state.name) != null:
		chara.node.get_node(state.name).queue_free()

func get_actor(codename: StringName) -> Actor:
	for i in TurnOrder:
		if i.codename == codename: return i
	return null
