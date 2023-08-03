extends Control
class_name Battle
@export var Party: PartyData
@export var Seq: BattleSequence= Loader.Seq
@export var Troop: Array[Actor]
@export var TurnOrder: Array[Actor]
@export var Turn: int = 0
@export var CurrentChar: Actor
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

func _ready():
	$Cam.make_current()
	Loader.InBattle = true
	TurnInd= -1
	Turn = 0
	Seq = Loader.Seq
	Party = preload("res://database/Party/CurrentParty.tres")
	for i in Seq.Enemies.size():
		Seq.Enemies[i-1] = Seq.Enemies[i-1].duplicate(true)
	Troop = Seq.Enemies
	Party.Leader.node = $Act/Actor0
	TurnOrder.push_front(Party.Leader)
	PartyArray.push_back(Party.Leader)
	$Act/Actor0.sprite_frames = Party.Leader.BT
	$Act/Actor0.animation = &"Entrance"
	$Act/Actor0.frame = 0
	$Act/Actor0/Shadow.modulate = Color.WHITE
	$Canvas/Callout.modulate = Color.TRANSPARENT
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
	TurnOrder.sort_custom(speed_sort)
	$Act/Actor0.add_child(Party.Leader.SoundSet.instantiate())
	for i in TurnOrder.size():
		print(TurnOrder[i].Speed, " - ", TurnOrder[i].FirstName)
	for i in TurnOrder:
		if not i.Shadow:
				i.node.get_child(0).hide()
	position_sprites()
	if Seq.Transition:
		await entrance()
	else:
		next_turn.emit()
	

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
	$Cam.zoom = Vector2(5,5)
	$Cam.position = Vector2(90,10)
	PartyUI.UIvisible = false
	t = create_tween()
	#t.set_parallel()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUART)
	if Troop.size()<3:
		Loader.battle_bars(3)
	else:
		Loader.battle_bars(2)
	t.tween_property($Cam, "zoom", Vector2(5.5,5.5), 0.5)
	t.parallel().tween_property($Cam, "position", Vector2(90,10), 0.5)
	t.tween_property($Cam, "position", Vector2(-50,10), 0.5).set_delay(0.5)
	await get_tree().create_timer(0.3).timeout
	$EnemyUI.all_enemy_ui()
	await get_tree().create_timer(0.5).timeout
	for i in Global.number_of_party_members():
		entrance_anim(i)
	Loader.battle_bars(2)
	await get_tree().create_timer(0.5).timeout
	$PartyUI.battle_state()
	await get_tree().create_timer(0.7).timeout
	next_turn.emit()
	
func entrance_anim(i):
	$Act.get_node("Actor" + str(i)).play("Entrance")
	play_sound("Entrance", PartyArray[i])
	await $Act.get_node("Actor" + str(i)).animation_finished
	$Act.get_node("Actor" + str(i)).play("Idle")

func _on_next_turn():
	if Troop.size() == 0:
		victory()
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
	$Act.handle_states()
	if CurrentChar.has_state("Knocked Out"):
		end_turn()
	elif CurrentChar.Controllable:
		print("Control")
		GetControl.emit()
	else:
		$AI.ai()

func _on_ai_chosen():
	if CurrentChar.NextAction == "Ability":
			t = create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUART)
			t.tween_property($Cam, "zoom", Vector2(5,5), 0.3)
			t.parallel().tween_property($Cam, "zoom", Vector2(5.5,5.5), 0.3)
			callout(CurrentChar.NextMove)
			focus_cam(CurrentChar)
			
			CurrentChar.node.play("Ability")
			await CurrentChar.node.animation_finished
	_on_battle_ui_ability_returned(CurrentChar.NextMove, CurrentChar.NextTarget)

func _input(event):
	if Input.is_key_pressed(KEY_R):
		end_battle()


func _on_battle_ui_ability():
	play_sound("Ability", CurrentChar)
	CurrentChar.node.play("Ability")
	await CurrentChar.node.animation_finished
	CurrentChar.node.play("AbilityLoop")

func _on_battle_ui_root():
	stop_sound("Ability", CurrentChar)

func callout(ab:Ability = CurrentAbility):
	if not ab.Callout:
		return
	t.kill()
	t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUINT)
	$Canvas/Callout.text = ab.name
	$Canvas/Callout.add_theme_color_override("font_color", CurrentAbility.WheelColor)
	t.tween_property($Canvas/Callout, "position", Vector2(37, 636), 2).from(Vector2(400, 636))
	t.parallel().tween_property($Canvas/Callout, "modulate", Color.WHITE, 2).from(Color.TRANSPARENT)
	#await t.finished
	t.set_ease(Tween.EASE_IN)
	t.tween_property($Canvas/Callout, "position", Vector2(-200, 636), 0.5).set_delay(4)
	t.parallel().tween_property($Canvas/Callout, "modulate", Color.TRANSPARENT, 0.5)

func _on_battle_ui_ability_returned(ab :Ability, tar:Actor):
	CurrentChar.NextAction = ""
	CurrentChar.NextMove = null
	CurrentChar.NextTarget = null
	CurrentAbility = ab
	CurrentTarget = tar
	if ab == null:
		end_turn()
		return
	if ab.Target == 1:
		if tar.has_state("Knocked Out"):
				var i = -1 
				var oldtar = CurrentTarget.FirstName
				while CurrentTarget.FirstName == oldtar or CurrentTarget.has_state("Knocked Out") or CurrentTarget.node == null:
					i += 1
					if i>get_ally_faction(CurrentTarget).size():
						print("The party was wiped out")
						end_battle()
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
		if CurrentAbility.Callout and CurrentChar.Controllable:
			callout()
		CurrentChar.add_aura(-CurrentAbility.AuraCost)
		$Act.play(ab.ActionSequence, CurrentTarget)
	else:
		end_turn()
		return

func end_battle():
	Loader.end_battle()
	if Seq.Transition:
		await get_tree().create_timer(0.5).timeout
	queue_free()

###################################################

func jump_to_target(character, tar, offset, time):
	t = create_tween()
	var target = tar.node.position + offset
	var start = character.node.global_position
	var jump_distance : float = start.distance_to(target)
	var jump_height : float = jump_distance * 0.5 #will need tweaking
	var midpoint = start.lerp(target, 0.5) + Vector2.UP * jump_height
	var jump_time = jump_distance * (time * 0.001) #will also need tweaking, this controls how fast the jump is
	t.tween_method(Global._quad_bezier.bind(start, midpoint, target, character.node), 0.0, 1.0, jump_time)
	await t.finished
	anim_done.emit()
	
func return_cur():
	t= create_tween()
	t.set_trans(Tween.TRANS_QUAD)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(CurrentChar.node, "position", initial, 0.2)
	
func end_turn():
	await get_tree().create_timer(0.3).timeout
	if CurrentChar.node != null:
		CurrentChar.node.z_index = 0
	next_turn.emit()
	
func damage(target:Actor, x:int, stat:float):
	take_dmg.emit()
	target.damage(x, stat, target)
	check_party.emit()
	
	pop_num(target, target.calc_dmg(x, stat, target))
	if target.Health == 0:
		death(target)
		return
	if target.has_state("Guarding"):
		pass
	else:
		play_sound("Hit", target)
		target.node.get_child(3).emitting = true
		t = create_tween()
		t.set_ease(Tween.EASE_IN)
		t.set_trans(Tween.TRANS_QUART)
		target.node.material.set_shader_parameter("outline_enabled", true)
		target.node.material.set_shader_parameter("outline_color", target.MainColor)
		hit_animation(target)
		target.node.get_child(3).process_material.gravity = Vector3(offsetize(120), 0, 0)
		target.node.get_child(3).process_material.color = target.MainColor
		t.parallel().tween_property(target.node.material, "shader_parameter/outline_color", Color.TRANSPARENT, 0.5)
		await t.finished
		target.node.material.set_shader_parameter("outline_enabled", false)
	

func hit_animation(tar):
	tar.node.play("Hit")
	await tar.node.animation_finished
	tar.node.play("Idle")
	

func screen_shake(amount:float, times:float, ShakeDuration:float):
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
	match CurrentAbility.Damage:
		0:
			return 0
		1:
			return 12
		2:
			return 24
		3:
			return 32
		4:
			return 48
	
func play_effect(stri: String, tar):
	tar.node.get_child(2).play(stri)
	
func offsetize(num, target=CurrentChar):
	if CurrentAbility != null and CurrentAbility.Target == 0:
		return 0
	if target.IsEnemy:
		return -num
	else:
		return num
		

func pop_num(target:Actor, text):
		target.node.get_child(1).show()
		t = create_tween()
		t.set_ease(Tween.EASE_IN)
		t.set_trans(Tween.TRANS_QUART)
		target.node.get_child(1).text = str(text)
		t.tween_property(target.node.get_child(1), "position", Vector2(offsetize(20), -10), 0.3).as_relative().from(Vector2(-217, -36))
		t.parallel().tween_property(target.node.get_child(1), "modulate", Color.WHITE, 0.3).from(Color.TRANSPARENT)
		t.set_ease(Tween.EASE_OUT)
		t.tween_property(target.node.get_child(1), "modulate", Color.TRANSPARENT, 2).from(Color.WHITE)
		t.parallel().tween_property(target.node.get_child(1), "position", Vector2(offsetize(14), -6), 2).as_relative()

func play_sound(SoundName: String, act: Actor):
	if act.node.get_node("SFX").has_node(SoundName):
		act.node.get_node("SFX").get_node(SoundName).play()
		
func stop_sound(SoundName: String, act: Actor):
	if act.node.get_node("SFX").has_node(SoundName):
		act.node.get_node("SFX").get_node(SoundName).stop()

func death(target:Actor):
	target.add_state("KnockedOut")
	target.node.play("KnockOut")
	target.node.get_child(3).emitting = true
	t = create_tween()
	
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	target.node.material.set_shader_parameter("outline_enabled", true)
	target.node.material.set_shader_parameter("outline_color", target.MainColor)
	target.node.get_child(3).process_material.gravity = Vector3(offsetize(120), 0, 0)
	target.node.get_child(3).process_material.color = target.MainColor
	t.parallel().tween_property(target.node.get_node("Shadow"), "modulate", Color.TRANSPARENT, 0.5)
	t.parallel().tween_property(target.node.material, "shader_parameter/outline_color", Color.TRANSPARENT, 0.5)
	await t.finished
	target.node.material.set_shader_parameter("outline_enabled", false)
	if target.Disappear:
		t = create_tween()
		t.tween_property(target.node, "modulate", Color.TRANSPARENT, 0.5)
		await t.finished
		target.node.queue_free()
		target.node = null
		if target.IsEnemy:
			Troop.erase(target)
			TurnOrder.erase(target)

func get_ally_faction(act: Actor = CurrentChar):
	if act.IsEnemy: return Troop
	else: return PartyArray

func get_oposing_faction(act: Actor = CurrentChar):
	if act.IsEnemy: return PartyArray
	else: return Troop


func hp_sort(a:Actor, b:Actor):
	if a.Health <= b.Health:
		return true
	else:
		return false
		
func focus_cam(chara:Actor, time:float=0.5, offset=-40):
	t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property($Cam, "position", Vector2(chara.node.global_position.x - offsetize(offset),chara.node.position.y /2), time)

func move(chara:Actor, pos:Vector2, time:float, mode:Tween.EaseType = Tween.EASE_IN_OUT, offset:Vector2 = Vector2.ZERO):
	t = create_tween()
	t.set_ease(mode)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(chara.node, "position", pos + offset, time)
	anim_done.emit()

func heal(target:Actor):
	target.add_health(int(max(calc_num(), target.MaxHP*((calc_num()*CurrentChar.Magic)*0.02))))
	pop_aura(target)
	pop_num(target, str("+",int(max(calc_num(), target.MaxHP*((calc_num()*CurrentChar.Magic)*0.02)))))

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
	end_battle()
	
