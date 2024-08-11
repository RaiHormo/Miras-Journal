extends Node2D
class_name Battle
@export var Party: PartyData
@export var Seq: BattleSequence= Loader.Seq
@export var Troop: Array[Actor]
@export var TurnOrder: Array[Actor]
@export var Turn: int = 0
@onready var CurrentChar: Actor
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
var CurrentAbility: Ability
var PartyArray: Array[Actor] = []
var Action: bool
var CurrentTarget: Actor
var CurrentTargets: Array[Actor]
var AwaitVictory = false
var count: int
var totalSP: int = 0
var ObtainedItems: Array[ItemData] = []
var callout_onscreen := false
var lock_turn:= false
var no_crits:= false
var no_misses:= false
var follow_up_next:= false
var aoe_returns:= 0

func _ready():
	Loader.battle_start.emit()
	Global.Bt = self
	get_tree().paused = false
	Global.Controllable = false
	$Cam.make_current()
	Loader.InBattle = true
	TurnInd= -1
	Turn = 0
	CurrentChar = Global.Party.Leader
	CurrentAbility = Global.Party.Leader.StandardAttack
	Seq = Loader.Seq.duplicate()
	Seq.reset_events(true)
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
	if Seq.PositionSameAsPlayer:
		Seq.ScenePosition = Global.Player.global_position + Vector2(45,0)
	global_position = Seq.ScenePosition
	global_position = Vector2i(global_position)
	$Act/Actor0.sprite_frames = Party.Leader.BT
	$Act/Actor0.animation = &"Entrance"
	$Act/Actor0.frame = 0
	$Act/Actor0/Shadow.modulate = Color.WHITE
	$Canvas/Callout.modulate = Color.TRANSPARENT
	$Canvas/SPGain.hide()
	$Canvas/VictoryItems.hide()
	if Global.Area: Global.Area.show()
	for i in range(1, 4):
		if Global.check_member(i):
			dub = $Act/Actor0.duplicate()
			dub.name = "Actor"+ str(i)
			$Act.add_child(dub)
			Party.array()[i].node = dub
			dub.sprite_frames = Party.array()[i].BT
			TurnOrder.push_front(Party.array()[i])
			PartyArray.push_back(Party.array()[i])
			dub.material = dub.material.duplicate()
			dub.add_child(Party.array()[i].SoundSet.instantiate())
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
			if not i.IsEnemy: i.SpeedBoost += 5
	elif Loader.BtAdvantage == 2:
		for i in TurnOrder:
			if i.IsEnemy: i.SpeedBoost += 5
	$Act/Actor0.add_child(Party.Leader.SoundSet.instantiate())
	for i in TurnOrder:
		sprite_init(i)
		i.NextAction = ""
		i.BattleLog.clear()
	position_sprites()
	turn_ui_init()
	if Loader.Attacker: Loader.Attacker.hide()
	if Seq.EntranceSequence != "": await $Act.call(Seq.EntranceSequence)
	TurnOrder.sort_custom(speed_sort)
	for i in TurnOrder:
		print(i.Speed+i.SpeedBoost, " - ", i.FirstName)
	await entrance()

func sprite_init(i: Actor):
	i.node.get_node("State").play("None")
	if not i.Shadow:
			i.node.get_child(0).hide()
	if i.IsEnemy: i.node.get_node("Glow").energy = i.GlowDef
	else:
		t = create_tween()
		t.tween_property(i.node.get_node("Glow"), "energy", i.GlowDef, 1)
	i.node.get_node("Glow").color = i.MainColor

func speed_sort(a: Actor, b: Actor):
	if a.Speed + a.SpeedBoost > b.Speed + b.SpeedBoost:
		return true
	elif a.Speed + a.SpeedBoost == b.Speed + b.SpeedBoost:
		if a.IsEnemy:
			return false
		else:
			return true
	else:
		return false

func turn_ui_init():
	var entr = $Canvas/TurnOrderPop/Margin/List.get_child(0).duplicate()
	for i in $Canvas/TurnOrderPop/Margin/List.get_children(): i.queue_free()
	for i in TurnOrder:
		entr = entr.duplicate()
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
	match Global.number_of_party_members():
		1:
			$Act/Actor0.position = Vector2(-45,0)
		2:
			$Act/Actor0.position = Vector2(-45,-15)
			$Act/Actor1.show()
			$Act/Actor1.position = Vector2(-45,45)
		3:
			$Act/Actor0.position = Vector2(-45,-25)
			$Act/Actor1.show()
			$Act/Actor1.position = Vector2(-45,15)
			$Act/Actor2.show()
			$Act/Actor2.position = Vector2(-45,55)
		4:
			$Act/Actor0.position = Vector2(-45,-35)
			$Act/Actor1.show()
			$Act/Actor1.position = Vector2(-45,0)
			$Act/Actor2.show()
			$Act/Actor2.position = Vector2(-45,35)
			$Act/Actor3.show()
			$Act/Actor3.position = Vector2(-45,70)

	match Troop.size():
		1:
			$Act/Enemy0.show()
			$Act/Enemy0.position = Vector2(66,0)
		2:
			if $Act.has_node("Enemy0"):
				$Act/Enemy0.show()
				$Act/Enemy0.position = Vector2(66,-15)
			if $Act.has_node("Enemy1"):
				$Act/Enemy1.show()
				$Act/Enemy1.position = Vector2(46,30)
		3:
			if $Act.has_node("Enemy0"):
				$Act/Enemy0.show()
				$Act/Enemy0.position = Vector2(66,-25)
			if $Act.has_node("Enemy1"):
				$Act/Enemy1.show()
				$Act/Enemy1.position = Vector2(36,15)
			if $Act.has_node("Enemy2"):
				$Act/Enemy2.show()
				$Act/Enemy2.position = Vector2(66,55)
		4:
			if $Act.has_node("Enemy0"):
				$Act/Enemy0.show()
				$Act/Enemy0.position = Vector2(66,-35)
			if $Act.has_node("Enemy1"):
				$Act/Enemy1.show()
				$Act/Enemy1.position = Vector2(36,15)
			if $Act.has_node("Enemy2"):
				$Act/Enemy2.show()
				$Act/Enemy2.position = Vector2(90, 15)
			if $Act.has_node("Enemy3"):
				$Act/Enemy3.show()
				$Act/Enemy3.position = Vector2(66,65)
	for i in TurnOrder:
		pixel_perfectize(i)

func entrance():
	if Seq.Transition:
		$Cam.zoom = Vector2(5,5)
		$Cam.position = Vector2(90,10)
		if Troop.size()<3:
			Loader.battle_bars(3)
		else:
			Loader.battle_bars(2)
		if Seq.EntranceBanter != "":
			if Seq.EntranceBanterIsPassive:
				Global.passive("entrance_banter", Seq.EntranceBanter)
			else:
				Global.textbox("entrance_banter", Seq.EntranceBanter)
				while Global.textbox_open:
					if $Cam.position.x > -30: $Cam.position.x -= 0.03
					await Event.wait()
		t = create_tween()
		t.set_ease(Tween.EASE_IN_OUT)
		t.set_trans(Tween.TRANS_QUART)
		t.tween_property($Cam, "zoom", Vector2(5.5,5.5), 0.5)
		t.parallel().tween_property($Cam, "position", Vector2(90,10), 0.5)
		t.tween_property($Cam, "position", Vector2(-50,10), 0.5).set_delay(0.5)
		await Event.wait(0.3, false)
		$EnemyUI.all_enemy_ui(true)
		if Loader.BtAdvantage == 1:
			for i in Troop: damage(i, 1, false, 24/Troop.size())
		await Event.wait(0.5, false)
	elif Seq.EntranceSequence == "":
		t = create_tween()
		t.set_ease(Tween.EASE_IN_OUT)
		t.set_trans(Tween.TRANS_QUART)
		t.tween_property($Cam, "position", Vector2(-50,10), 0.5)
		$Cam.global_position = Global.get_cam().global_position
		$Cam.zoom = Global.get_cam().zoom
	if Seq.EntranceSequence == "":
		for i in PartyArray:
			entrance_anim(i)
	Loader.battle_bars(2)
	await Event.wait(0.5, false)
	if not Seq.Transition: $EnemyUI.all_enemy_ui(true)
	PartyUI.battle_state(true)
	await Event.wait(0.7, false)
	if Seq.EntranceSequence == "": next_turn.emit()

func entrance_anim(i: Actor):
	play_sound("Entrance", i)
	await anim(&"Entrance", i)
	if i.node.animation == &"Entrance" or i.node.animation == &"Idle": anim("", i)

func _on_next_turn():
	if check_for_victory(): return
	for i in TurnOrder:
		if i.Aura == 0 and not i.has_state("AuraBreak") and not i.has_state("KnockedOut") and i.Health != 0:
			await i.add_state("AuraBreak")
			if i != CurrentChar:
				follow_up_next = true
	#position_sprites()
	Turn += 1
	if follow_up_next:
		Global.toast("FOLLOW UP!")
		follow_up_next = false
	else:
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
	if CurrentChar.IsEnemy: $EnemyUI._on_battle_ui_target_foc(CurrentChar)
	$Act.handle_states()

func check_for_victory() -> bool:
	var j = 0
	for i in Troop:
		if i.has_state("Knocked Out"): j += 1
	if j == Troop.size() or Troop.size() == 0:
		victory()
		return true
	else: return false

func make_move():
	if check_for_victory(): return
	if CurrentChar.NextAction == "":
		if CurrentChar.Controllable:
			print("Control")
			GetControl.emit()
		else:
			$AI.ai()
	else:
		print("Forced move")
		confirm_next()

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
				var timer = get_tree().create_timer(0.5)
				await anim("Ability")
				if timer.time_left != 0: await timer.timeout
	if CurrentChar.NextTarget == null:
		CurrentChar.NextTarget = random_target(CurrentChar.NextMove)
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
	elif Input.is_action_just_released("Dash"):
		Engine.time_scale = 1
	if AwaitVictory:
		if Input.is_action_just_released("ui_accept"):
			end_battle()
	if Input.is_action_just_pressed("DebugF"):
		print(relation_to_dmg_modifier(color_relation(CurrentChar.MainColor,
		$BattleUI.target.MainColor)))

func _on_battle_ui_ability():
	if CurrentChar.node == null: return
	if $BattleUI.PrevStage == "root":
		play_sound("Ability", CurrentChar)
		await anim("Ability")
	if CurrentChar.node.animation == "Ability": anim("AbilityLoop")

func _on_battle_ui_root():
	Engine.time_scale = 1
	$EnemyUI.all_enemy_ui()
	stop_sound("Ability", CurrentChar)
	anim()

func callout(ab:Ability = CurrentAbility):
	if not ab.Callout:
		return
	var tc = create_tween()
	tc.set_ease(Tween.EASE_OUT)
	tc.set_trans(Tween.TRANS_QUINT)
	if callout_onscreen:
		tc.tween_property($Canvas/Callout, "modulate", Color.TRANSPARENT, 0.2)
		await tc.finished
		tc.kill()
		tc = create_tween()
		tc.set_ease(Tween.EASE_OUT)
		tc.set_trans(Tween.TRANS_QUINT)
	callout_onscreen = true
	if ab.ColorSameAsActor: ab.WheelColor = CurrentChar.MainColor
	$Canvas/Callout.text = ab.name
	$Canvas/Callout.add_theme_color_override("font_color", ab.WheelColor)
	tc.tween_property(
		$Canvas/Callout, "position", Vector2(37, 636), 2).from(Vector2(400, 636))
	tc.parallel().tween_property(
		$Canvas/Callout, "modulate", Color.WHITE, 2).from(Color.TRANSPARENT)
	#await tc.finished
	#print("call")
	tc.set_ease(Tween.EASE_IN)
	if CurrentChar.Controllable:
		tc.tween_property(
			$Canvas/Callout, "position", Vector2(-200, 636), 0.5).set_delay(1)
	else: tc.tween_property(
		$Canvas/Callout, "position", Vector2(-200, 636), 0.5).set_delay(4)
	tc.parallel().tween_property(
		$Canvas/Callout, "modulate", Color.TRANSPARENT, 0.5)
	await tc.finished
	callout_onscreen = false

func _on_battle_ui_ability_returned(ab :Ability, tar: Actor):
	print("Using ", ab.name, " on ", tar.FirstName)
	for i in CurrentChar.BattleLog: if i.turn == Turn:
		print("Double turn detected, aborting")
		return
	var log_entry = Actor.log_entry.new()
	log_entry.ability = ab; log_entry.target = tar; log_entry.turn = Turn
	CurrentChar.BattleLog.append(log_entry)
	CurrentChar.NextAction = ""
	CurrentChar.NextMove = null
	CurrentChar.NextTarget = null
	CurrentAbility = ab
	CurrentTarget = tar
	if ab.remove_item_on_use != null:
		Item.remove_item(ab.remove_item_on_use)
	if ab == null:
		end_turn()
		return
	if ab.ColorSameAsActor:
		ab.WheelColor = CurrentChar.MainColor
	if ab.Target == 1:
		if tar and tar.has_state("Knocked Out"):
			var i = -1
			var oldtar = CurrentTarget.FirstName
			while (CurrentTarget.FirstName == oldtar or
			CurrentTarget.has_state("Knocked Out") or CurrentTarget.node == null):
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
	elif ab.Target == 2: $EnemyUI.all_enemy_ui()
	if ab.ActionSequence != &"":
		CurrentChar.add_aura(-CurrentAbility.AuraCost)
		if CurrentAbility.Callout and CurrentChar.Controllable:
			callout()
		$Act.play(ab.ActionSequence, CurrentTarget)
	else:
		end_turn()
		return

###################################################

func jump_to_target(
character: Actor, tar: Actor, offset: Vector2, time: float) -> void:
	t = create_tween()
	var target = tar.node.position + offset
	var start = character.node.position
	var jump_distance : float = start.distance_to(target)
	var jump_height : float = jump_distance * 0.5 #will need tweaking
	var midpoint = start.lerp(target, 0.5) + Vector2.UP * jump_height
	var jump_time = jump_distance * (time * 0.001)
	t.tween_method(Global._quad_bezier.bind(
		start, midpoint, target, character.node), 0.0, 1.0, jump_time)
	await t.finished
	anim_done.emit()

func return_cur(target:Actor = CurrentChar):
	var tc= create_tween()
	tc.set_trans(Tween.TRANS_QUAD)
	tc.set_ease(Tween.EASE_OUT)
	tc.tween_property(target.node, "position", initial, 0.2)
	await tc.finished

func end_turn(confirm_aoe:= false):
	Global.check_party.emit()
	if CurrentAbility.is_aoe() and not confirm_aoe:
		aoe_returns += 1
		return
	aoe_returns = 0
	if Seq.check_events():
		await Seq.call_events()
	Seq.reset_events()
	TurnOrder.sort_custom(speed_sort)
	#for i in TurnOrder:
		#print(i.Speed+i.SpeedBoost, " - ", i.FirstName)
	while lock_turn:
		await Event.wait()
	await get_tree().create_timer(0.3).timeout
	if CurrentChar.node:
		CurrentChar.node.z_index = 0
	next_turn.emit()

func damage(
target: Actor, is_magic:= CurrentAbility.Damage != Ability.D.WEAPON, elemental:= false,
x: int = Global.calc_num(), effect:= true, limiter:= false, ignore_stats:= false,
overwrite_color: Color = Color.WHITE) -> int:
	take_dmg.emit()
	if target.has_state_that_protects():
		pop_num(target, "BLOCKED")
		return 0
	var el_mod: float = 1
	var color = (CurrentAbility.WheelColor if overwrite_color == Color.WHITE else overwrite_color)
	var relation = color_relation(color, target.MainColor)
	if elemental:
		if target.has_state("AuraBreak"): relation = "op"
		if relation == "wk": pop_num(target, "WEAK")
		if relation == "op": pop_num(target, "WEAK!")
		if relation == "res": pop_num(target, "RESIST")
		print(relation)
		el_mod = relation_to_dmg_modifier(relation)
	print("Attack power: ", x, " * ", el_mod)
	var attacker = null if ignore_stats else CurrentChar
	var dmg = target.calc_dmg(x * el_mod, is_magic, attacker)
	if target.Controllable:
		Input.start_joy_vibration(0, remap(dmg, 0, target.MaxHP, 0.3, 1), remap(dmg, 0, target.MaxHP, 0, 0.5), 0.2)
	target.damage(dmg, limiter)
	if target.ClutchDmg and target.Health <= 5 and target.SeqOnClutch != "" and not limiter:
		$Act.call(target.SeqOnClutch, target)
	print(CurrentChar.FirstName + " deals " +
	str(dmg) + " damage to " + target.FirstName)
	if CurrentAbility.RecoverAura: CurrentChar.add_aura(dmg/10)
	if elemental:
		var aur_dmg = relation_to_aura_dmg(relation, dmg)
		print(target.FirstName, " takes ", aur_dmg, " aura damage")
		target.add_aura(-aur_dmg)
		pop_num(target, dmg, color)
	else: pop_num(target, dmg)
	check_party.emit()
	if target.Health == 0:
		if target.CantDie:
			target.Health = 1
		else:
			await death(target)
			if target != CurrentChar and relation == "wk": follow_up_next = true
			return dmg
	if target.Health == 0 or target.has_state("Knocked Out"): return dmg
	if target.has_state("Guarding"):
		if relation == "res": target.add_aura(dmg*2)
		else: target.add_aura(dmg)
	elif effect:
		play_sound("Hit", target)
		hit_animation(target)
		if elemental and not target.has_state("AuraBreak"):
			if el_mod > 1:
				target.node.get_node("Particle").emitting = true
			t = create_tween()
			t.set_ease(Tween.EASE_IN)
			t.set_trans(Tween.TRANS_QUART)
			target.node.material.set_shader_parameter("outline_enabled", true)
			target.node.material.set_shader_parameter("outline_color",
			target.MainColor)
			target.node.get_node("Particle"
			).process_material.gravity = Vector3(offsetize(120), 0, 0)
			target.node.get_node("Particle").process_material.color = target.MainColor
			t.tween_property(target.node.material,
			"shader_parameter/outline_color", Color.TRANSPARENT, 0.5)
			await t.finished
		target.node.material.set_shader_parameter("outline_enabled", false)
	target.DamageRecivedThisTurn += dmg
	return dmg

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
		t.tween_property($Cam, "offset",
		Vector2(randi_range(-am,am), randi_range(-am,am)), dur).as_relative()
		t.tween_property($Cam, "offset", Vector2.ZERO, dur)
	await t.finished

func play_effect(stri: String, tar, offset = Vector2.ZERO, flip_on_player_use:= false, dont_free:= false):
	if $Act/Effects.sprite_frames.has_animation(stri):
		if tar is Actor: tar = tar.node.position
		var ef:AnimatedSprite2D = $Act/Effects.duplicate()
		if flip_on_player_use and !CurrentChar.IsEnemy: ef.flip_h = true
		ef.name = stri
		$Act.add_child(ef)
		ef.position = tar + offset
		ef.play(stri)
		await ef.animation_finished
		if not dont_free: ef.queue_free()

func offsetize(num, target=CurrentChar):
	if target == null: return num
	#if CurrentAbility and CurrentAbility.Target == 0:
		#return 0
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
			randf_range(0.8,1.2), -10*randf_range(0.8,1.2)),
			0.3).as_relative().from(Vector2(-217, -36))
		tn.parallel().tween_property(number, "modulate",
			Color.WHITE, 0.3).from(Color.TRANSPARENT)
		tn.set_ease(Tween.EASE_OUT)
		tn.tween_property(number, "modulate",
			Color.TRANSPARENT, 2).from(Color.WHITE)
		tn.parallel().tween_property(number, "position",
			Vector2(offsetize(14*off)*
			randf_range(0.8,1.2), -6*randf_range(0.8,1.2)), 2).as_relative()
		await tn.finished
		if is_instance_valid(number):
			number.queue_free()

func play_sound(SoundName: String, act: Actor = null, volume: float = 1):
	$AudioListener2D.make_current()
	var player
	if act and act.node.get_node("SFX").has_node(SoundName):
		player = act.node.get_node("SFX").get_node(SoundName)
	else:
		player = $Audio/Stream0.duplicate()
		$Audio.add_child(player)
		if not FileAccess.file_exists("res://sound/SFX/Battle/"+SoundName+".ogg"): return
		player.stream = await Loader.load_res("res://sound/SFX/Battle/"+SoundName+".ogg")
		if act: player.global_position = act.node.global_position
	player.play()
	player.volume_db = volume
	await player.finished
	if player.get_parent() == $Audio: player.queue_free()

func stop_sound(SoundName: String, act: Actor):
	if act.node.get_node("SFX").has_node(SoundName):
		act.node.get_node("SFX").get_node(SoundName).stop()

func death(target:Actor):
	if target == null or target.has_state("KnockedOut"): return
	lock_turn = true
	clear_states(target)
	target.add_state("KnockedOut")
	if CurrentChar != target: CurrentChar.add_aura(target.Aura)
	target.set_aura(0)
	if target.IsEnemy:
		totalSP += target.RecivedSP
		if target.DroppedItem: ObtainedItems.append(target.DroppedItem)
	anim("KnockOut", target)
	if target.codename == &"Mira":
		await Event.wait(0.2)
		get_tree().paused = true
		CurrentChar.node.pause()
		target.node.pause()
		await screen_shake(20, 10, 0.2)
		await Event.wait(0.7, false)
		CurrentChar.node.play()
		target.node.play()
		get_tree().paused = false
		await Event.wait(1, false)
		Loader.white_fadeout(0.1, 1, 3)
		await Event.wait(4, false)
		game_over()
	target.node.get_node("Particle").emitting = true
	var td = create_tween()
	target.Health = 0
	td.set_ease(Tween.EASE_IN)
	td.set_trans(Tween.TRANS_QUART)
	target.node.material.set_shader_parameter("outline_enabled", true)
	target.node.material.set_shader_parameter("outline_color", target.MainColor)
	target.node.get_node("Particle"
	).process_material.gravity = Vector3(offsetize(120), 0, 0)
	target.node.get_node("Particle"
	).process_material.color = target.MainColor
	td.parallel().tween_property(
		target.node.get_node("Shadow"), "modulate", Color.TRANSPARENT, 0.5)
	td.parallel().tween_property(
		target.node.material, "shader_parameter/outline_color",
		Color.TRANSPARENT, 0.5)
	print(target.FirstName, " was defeated")
	await td.finished
	if target.node:
		target.node.material.set_shader_parameter("outline_enabled", false)
		if target.Disappear:
			td = create_tween()
			td.tween_property(target.node, "modulate", Color.TRANSPARENT, 0.5)
			td.tween_property(target.node.get_node("Glow"), "energy", 0, 0.5)
			await td.finished
			if target and target.node:
				target.node.queue_free()
				target.node = null
				if target.IsEnemy:
					Troop.erase(target)
					TurnOrder.erase(target)
	if target != Party.Leader:
		lock_turn = false

func slowmo(timescale = 0.5, time= 1):
	Engine.time_scale = 0.5
	await Event.wait(time * timescale)
	Engine.time_scale = 1

func get_ally_faction(act: Actor = CurrentChar) -> Array[Actor]:
	var rtn: Array[Actor]
	if act.IsEnemy: rtn = Troop
	else: rtn = PartyArray
	rtn = filter_dead(rtn)
	return rtn

func get_oposing_faction(act: Actor = CurrentChar) -> Array[Actor]:
	var rtn: Array[Actor]
	if act.IsEnemy: rtn = PartyArray
	else: rtn = Troop
	rtn = filter_dead(rtn)
	return rtn

func get_target_faction() -> Array[Actor]:
	match CurrentAbility.Target:
		Ability.T.AOE_ALLIES: return get_ally_faction()
		Ability.T.AOE_ENEMIES: return get_oposing_faction()
		_: return [CurrentTarget]

func hp_sort(a:Actor, b:Actor):
	if a.Health==0:
		return false
	if a.Health <= b.Health:
		return true
	else:
		return false

func anim(animation: String = "", chara: Actor = CurrentChar):
	if animation == "":
		if chara.DontIdle: return
		else: animation = "Idle"
	if animation not in chara.node.sprite_frames.get_animation_names(): return
	if animation in chara.GlowAnims and chara.GlowSpecial != 0:
		t=create_tween()
		chara.node.get_node("Glow").color = chara.MainColor
		t.tween_property(chara.node.get_node("Glow"), "energy", chara.GlowSpecial, 0.3)
	elif chara.node.animation in chara.GlowAnims and chara.GlowSpecial != 0:
		t.kill()
		t=create_tween()
		chara.node.get_node("Glow").color = chara.MainColor
		t.tween_property(chara.node.get_node("Glow"), "energy", chara.GlowDef, 0.3)
	chara.node.play(animation)
	pixel_perfectize(chara)
	while chara.node and chara.node.is_playing() and chara.node.animation == animation:
		await Event.wait()

func pixel_perfectize(chara: Actor, xy: int = 0):
	if int(chara.node.sprite_frames.get_frame_texture(
		chara.node.animation, chara.node.frame).get_size()[xy]) % 2 == 0:
		chara.node.offset[xy] = chara.Offset[xy]
	else: chara.node.offset[xy] = chara.Offset[xy] + 0.5
	if xy == 0: pixel_perfectize(chara, 1)

func glow(amount: float = 1, time: float = 1, chara:Actor = CurrentChar):
	t.kill()
	t=create_tween()
	t.tween_property(chara.node.get_node("Glow"), "energy", amount, time)

func focus_cam(chara:Actor, time:float=0.5, offset=30):
	if chara.node == null: return
	await move_cam(Vector2(chara.node.position.x + offsetize(offset, chara), chara.node.position.y /2), time)

func move_cam(pos: Vector2, time:float=0.5):
	var tc = create_tween()
	tc.set_ease(Tween.EASE_IN_OUT)
	tc.set_trans(Tween.TRANS_QUART)
	tc.tween_property($Cam, "position", pos, time)
	await tc.finished

func move(chara:Actor, pos:Vector2, time:float,
mode:Tween.EaseType = Tween.EASE_IN_OUT, offset:Vector2 = Vector2.ZERO):
	var tm = create_tween()
	tm.set_ease(mode)
	tm.set_trans(Tween.TRANS_QUART)
	tm.tween_property(chara.node, "position", pos + offset, time)
	await tm.finished
	anim_done.emit()

func heal(
target:Actor, amount: int = int(max(Global.calc_num(),
target.MaxHP*((Global.calc_num()*CurrentChar.Magic)*0.02)))):
	target.add_health(amount)
	$BattleUI.targetFoc.emit(target)
	check_party.emit()
	PartyUI._check_party()
	pop_aura(target)
	pop_num(target, "+"+str(amount))

func pop_aura(target: Actor, time:float=0.5):
	target.node.material.set_shader_parameter("outline_enabled", true)
	target.node.material.set_shader_parameter("outline_color", Color.WHITE)
	await get_tree().create_timer(time).timeout
	t = create_tween()
	t.parallel().tween_property(
		target.node.material, "shader_parameter/outline_color",
		Color.TRANSPARENT, 0.5)
	await t.finished
	target.node.material.set_shader_parameter("outline_enabled", false)

func escape():
	print("Escaped")
	Loader.BattleResult = 2
	end_battle()

func game_over():
	print("Game over")
	if Seq.DefeatSequence == "":
		Global.game_over()
	else: $Act.call(Seq.DefeatSequence)

func end_battle():
	AwaitVictory = false
	reset_all()
	$Canvas/Continue.hide()
	await PartyUI.preform_levelups()
	if Global.Area == null: Loader.travel_to("Debug"); queue_free(); return
	await Loader.end_battle()
	queue_free()

func reset_all():
	for i in TurnOrder:
		for j in i.States: if j.RemovedOnBattleEnd: i.States.erase(j)
		i.AttackMultiplier = 1
		i.DefenceMultiplier = 1
		i.MagicMultiplier = 1
		i.SpeedBoost = 0

func victory_anim(chara:Actor):
	$Act.process_mode = Node.PROCESS_MODE_ALWAYS
	clear_states(chara)
	await anim("Victory", chara)
	anim("VictoryLoop", chara)

func victory_count_sp():
	await Event.wait(0.7, false)
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT)
	t.set_parallel()
	$Canvas/SPGain.show()
	t.tween_property($Canvas/SPGain, "position:x", 918, 0.5).from(1000)
	t.tween_property($Canvas/SPGain, "modulate",
		Color.WHITE, 0.5).from(Color.TRANSPARENT)
	t.tween_property($Canvas/SPGain, "size:x", 260, 0.5).from(1)
	t.tween_property($Canvas/SPGain/VBoxContainer/Text,
		"custom_minimum_size:x", 140, 0.5).from(1)
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
	PartyUI._check_party()
	$Canvas.add_child(dub)
	t = create_tween()
	t.set_parallel()
	t.tween_property(dub, "scale", Vector2(1.5, 1.5), 0.3)
	t.tween_property(dub, "modulate", Color.TRANSPARENT, 0.3)
	#await Event.wait(0.3, false)
	await t.finished
	dub.queue_free()

func victory(ignore_seq:= false):
	print("Victory!")
	if Seq.VictorySequence != "" and not ignore_seq:
		$Act.call(Seq.VictorySequence)
		return
	if Seq.VictoryBanter != "":
		Global.passive("victory_banter", Seq.VictoryBanter)
	$Canvas.layer = 1
	Loader.BattleResult = 1
	for i in PartyArray:
		victory_anim(i)
	check_party.emit()
	$EnemyUI.colapse_root()
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
	Loader.battle_bars(0)
	$Canvas/DottedBack.show()
	t.tween_property($Canvas/DottedBack, "modulate",
	Color(0.188,0.188,0.188,0.8), 1).from(Color(0.188,0.188,0.188,0))
	t.tween_property($Canvas/Callout, "position",
	Vector2(700, 50), 2).from(Vector2(1200, 50))
	t.tween_property($Canvas/Callout, "modulate",
	Color.WHITE, 2).from(Color.TRANSPARENT)
	t.tween_property($Cam, "position", Vector2(-20,10), 1)
	t.tween_property($Cam, "zoom", Vector2(5,5), 1)
	if totalSP != 0: await victory_count_sp()
	if not ObtainedItems.is_empty(): await victory_show_items()
	$Canvas/TurnOrder.hide()
	$Canvas/Continue.show()
	$Canvas/Continue.icon = Global.get_controller().ConfirmIcon
	if Seq.VictoryBanter != "": await Global.textbox_close
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT)
	t.tween_property($Canvas/Continue, "position:x", 1060, 0.5).from(1500)
	$EnemyUI.colapse_root()
	AwaitVictory = true
	if is_instance_valid(Global.Player):
		Global.Player.global_position = $Act/Actor0.global_position
		if Party.check_member(1):
			Global.Area.get_node("Follower1"
			).global_position = $Act/Actor1.global_position
		if Party.check_member(2):
			Global.Area.get_node("Follower3"
			).global_position = $Act/Actor2.global_position
		if Party.check_member(3):
			Global.Area.get_node("Follower3"
			).global_position = $Act/Actor3.global_position
		Global.get_cam().global_position = Global.Player.global_position

func victory_show_items():
	for i in $Canvas/VictoryItems.get_children():
		i.modulate = Color.TRANSPARENT
	await Event.wait()
	$Canvas/VictoryItems/ItemTemp.hide()
	ObtainedItems.append_array(Seq.AdditionalItems)
	for i in ObtainedItems:
		if i:
			var dub = $Canvas/VictoryItems/ItemTemp.duplicate()
			dub.get_node("Hbox/ItemName").text = i.Name
			dub.get_node("Hbox/Icon").texture = i.Icon
			await Item.find_filename(i)
			Item.add_item(i, &"", false)
			dub.show()
			$Canvas/VictoryItems.add_child(dub)
	$Canvas/VictoryItems.show()
	for i in $Canvas/VictoryItems.get_children():
		var count:= 1
		if !(i == $Canvas/VictoryItems/ItemTemp or i is Label or not i.visible):
			for j in $Canvas/VictoryItems.get_children():
				if !(j == $Canvas/VictoryItems/ItemTemp or j is Label or j == i):
					if i.get_node("Hbox/ItemName").text == j.get_node("Hbox/ItemName").text:
						count += 1
						i.get_node("Hbox/Count").text = "x"+str(count)
						j.hide()
		if count > 1: i.get_node("Hbox/Count").show()
	for i in $Canvas/VictoryItems.get_children():
		if !(i == $Canvas/VictoryItems/ItemTemp or i == null):
			t = create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUINT)
			t.set_parallel()
			t.tween_property(i, "modulate", Color.WHITE, 0.5).from(Color.TRANSPARENT)
			t.tween_property(i, "position:x", i.position.x, 0.5).from(i.position.x+500)
			await t.finished

func miss(target:Actor = CurrentTarget):
	var tm = create_tween()
	tm.set_ease(Tween.EASE_OUT)
	tm.set_trans(Tween.TRANS_CUBIC)
	play_effect("Miss", target)
	tm.tween_property(target.node,
	"position:x", target.node.position.x + offsetize(30), 0.3)
	pop_num(target, "Miss")
	await Event.wait(0.5)
	tm = create_tween()
	tm.set_ease(Tween.EASE_OUT)
	tm.set_trans(Tween.TRANS_CUBIC)
	tm.tween_property(target.node, "position:x",
	target.node.position.x - offsetize(30), 0.3)

func _on_battle_ui_command():
	anim("Command")

func add_to_troop(en: Actor):
	en = en.duplicate()
	lock_turn = true
	Troop.append(en)
	dub = $Act/Actor0.duplicate()
	dub.name = "Enemy" + str(Troop.size() -1)
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
	dub.material.set_shader_parameter("outline_enabled", false)
	TurnOrder.sort_custom(speed_sort)
	TurnInd = TurnOrder.find(CurrentChar)
	position_sprites()
	sprite_init(en)
	focus_cam(en, 0.3)
	await Event.wait(1)
	fix_enemy_node_issues()
	position_sprites()
	turn_ui_init()
	lock_turn = false

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
	if relation == "op": base = 1.5 * value_mod
	elif relation == "wk": base = 1.25 * value_mod
	elif relation == "res": base = 0.75
	else: return 1
	return round(base*10)/10

func relation_to_aura_dmg(relation:String, dmg: int) -> int:
	print("Color value: ", CurrentChar.MainColor.v)
	if relation == "op": return int(dmg * CurrentChar.MainColor.v)
	elif relation == "wk": return int(dmg * (CurrentChar.MainColor.v / 2))
	else: return 0

func zoom(am:float = 5, time = 0.5, ease := Tween.EASE_IN_OUT):
	var tc = create_tween()
	tc.set_ease(ease)
	tc.set_trans(Tween.TRANS_QUART)
	tc.tween_property($Cam, "zoom", Vector2(am,am), time)
	await tc.finished

func _on_battle_ui_item() -> void:
	await anim("Bag")
	if CurrentChar.node.animation == "Bag": anim("BagLoop")

func shake_actor(chara := CurrentTarget, amount := 2, repeat := 5, time := 0.03):
	for i in repeat:
		t = create_tween()
		t.tween_property(chara.node, "position:x", amount, time).as_relative()
		t.tween_property(chara.node, "position:x", -amount*2, time*2).as_relative()
		t.tween_property(chara.node, "position:x", amount, time).as_relative()
		await t.finished

func stat_change(stat: StringName, amount: float,
chara := CurrentChar, turns: int = 3):
	var updown: String
	if amount > 0: updown = "Up"
	else: updown = "Down"
	match stat:
		&"Atk": chara.AttackMultiplier += amount
		&"Mag": chara.MagicMultiplier += amount
		&"Def": chara.DefenceMultiplier += amount
	chara.add_state(stat + updown)
	await Event.wait(1.2)
	pop_num(chara, stat_name(stat)
	+ " x" + str(amount+1), (await Global.get_state(stat + updown)).color)
	print(chara.FirstName, "'s ", stat, " was multiplied by ", str(amount+1))

func stat_name(stat: StringName) -> String:
	match stat:
		&"Atk": return "Attack"
		&"Def": return "Defense"
		&"Mag": return "Magic"
		_: return "Stat"

func health_precentage(chara: Actor) -> float:
	return (float(chara.Health)/float(chara.MaxHP)*100)

func on_state_add(state: State, chara: Actor):
	if chara.Health != 0:
		if not state.is_stat_change: pop_num(chara, state.name, state.color)
		add_state_effect(state, chara)
		match state.name:
			"Guarding":
				chara.DefenceMultiplier += 1
				chara.node.material.set_shader_parameter("outline_enabled", true)
				chara.node.material.set_shader_parameter("outline_color", chara.MainColor)
			"Protected":
				chara.node.material.set_shader_parameter("outline_enabled", true)
				chara.node.material.set_shader_parameter("outline_color", Color.WHITE)

func add_state_effect(state: State, chara: Actor):
	if chara.node.get_node_or_null(
	state.name) == null and chara.node.get_node(
	"State").sprite_frames.has_animation(state.name):
		var dub = chara.node.get_node("State").duplicate()
		dub.name = state.name
		chara.node.add_child(dub)
		dub.show()
		dub.play(state.name)

func remove_state_effect(statename: String, chara: Actor):
	if chara.node == null: return
	if chara.node.get_node_or_null(statename):
		chara.node.get_node(statename).queue_free()

func get_actor(codename: StringName) -> Actor:
	for i in TurnOrder:
		if i.codename == codename: return i
	return null

func random_target(ab: Ability):
	print("Target decided randomly")
	match ab.Target:
			Ability.T.SELF:
				return CurrentChar
			Ability.T.ONE_ENEMY:
				return get_oposing_faction(CurrentChar).pick_random()
			Ability.T.ONE_ALLY:
				print("a")
				return get_ally_faction(CurrentChar).pick_random()

func fix_enemy_node_issues():
	var i = 0
	for j in Troop:
		if j == null: continue
		if $Act.get_node_or_null("Enemy"+str(i)):
			j.node = $Act.get_node_or_null("Enemy"+str(i))
		i += 1

func filter_actors_by_state(input: Array[Actor], state: String) -> Array[Actor]:
	var rtn: Array[Actor] = []
	for i in input:
		if i.has_state(state):
			rtn.append(i)
	return rtn

func filter_dead(arr: Array[Actor]) -> Array[Actor]:
	var warr = arr.duplicate()
	for i in arr:
		if i.has_state("KnockedOut") or i.Health == 0: warr.erase(i)
	return warr

func clear_states(target: Actor):
	for i in target.States:
		target.remove_state(i)
