extends Node2D

var TurnOrder: Array[Actor]
var CurrentChar: Actor
var Party: PartyData
var Troop: Array[Actor]
var Turn: int
@onready var Cam :Camera2D = get_parent().get_child(2)
@onready var Bt :Battle = get_parent()
@onready var t: Tween
#var target:Actor
var miss
var crit
signal states_handled
signal additional_done

func play(nam, tar):
	TurnOrder = get_parent().TurnOrder
	CurrentChar = get_parent().CurrentChar
	Party = get_parent().Party
	Bt.Action=true
	CurrentChar.node.z_index = 1
	Loader.battle_bars(2)
	t = create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "position", position, 0)
	if not has_method(nam): OS.alert("Invalid action sequence"); Bt.end_turn(); return
	if Bt.CurrentAbility.is_aoe():
		play_aoe(nam)
	else:
		roll_rng(tar)
		call(nam, tar)

## To make an AOE action sequence there needs to be a conditional for if the target is the CurrentChar.
## After the current char does their stuff, the additional_done signal needs to be emmited for the rest of the targets to act
func play_aoe(nam):
	if Bt.CurrentAbility.AOE_AdditionalSeq:
		print("AOE additional sequence")
		roll_rng(CurrentChar)
		call(nam, CurrentChar)
		await additional_done
	var fact =  Bt.get_target_faction().duplicate()
	var required_returns = fact.size()
	if Bt.CurrentAbility.AOE_AdditionalSeq: required_returns += 1
	if CurrentChar in fact: 
		fact.erase(CurrentChar)
		required_returns -= 1
	for i in fact:
		roll_rng(i)
		call(nam, i)
		print("AOE sequence on ", i.FirstName)
		await Event.wait(Bt.CurrentAbility.AOE_Stagger)
	while Bt.aoe_returns != required_returns: await Event.wait()
	Bt.end_turn(true)

func roll_rng(tar: Actor):
	miss = false
	crit = false
	if not tar.CantDodge:
		if randf_range(0,1)>Bt.CurrentAbility.SucessChance and not Bt.no_misses: miss = true
	if randf_range(0,1)<Bt.CurrentAbility.CritChance and not Bt.no_crits: crit = true

################################################

func handle_states():
	var chara = Bt.CurrentChar
	for state: State in chara.States:
		print("Handling ", state.name)
		if state.turns > -1:
			state.turns -= 1
			if state.turns == 0:
				match state.name:
					"Guarding", "Protected":
						chara.node.material.set_shader_parameter("outline_enabled", false)
					"AttackUp": chara.AttackMultiplier -= 0.5
					"DefenceUp": chara.DefenceMultiplier -= 0.5
					"MagicUp": chara.MagicMultiplier -= 0.5
					"Aura Change": 
						chara.MainColor = chara.AuraDefault
						chara.node.material.set_shader_parameter("outline_enabled", false)
				state.QueueRemove = true
			else:
				match state.name:
					"Aura Break":
						if chara.Aura != 0:
							state.QueueRemove = true
					"Burned":
						chara.node.get_node("State").play("Burned")
						Bt.focus_cam(chara, 0.3)
						Bt.play_sound("BurnWoosh", chara)
						Bt.damage(chara, true, true, randi_range(3, 12), false, true, true, Global.ElementColor.get("heat"))
						await get_tree().create_timer(0.8).timeout
					"Poisoned":
						state.turns += 2
						chara.node.get_node("State").play("Poisoned")
						Bt.focus_cam(chara, 0.3)
						Bt.damage(chara, true, true, abs(state.turns)*2, false, true, true, Global.ElementColor.get("corruption"))
						await get_tree().create_timer(0.8).timeout
					"Confused":
						var luck := randi_range(state.turns, 1)
						print("Confusion dice roll: ", luck)
						if luck < -1:
							chara.remove_state(state.name)
							Global.toast(chara.FirstName+" snaps out of Confusion!")
						elif luck == -1 or not chara.Controllable:
							var choices: Array[Ability] = chara.Abilities.duplicate()
							choices.append(chara.StandardAttack)
							chara.NextMove = choices.pick_random()
							chara.NextAction = "Ability"
							chara.NextTarget = TurnOrder.pick_random()
							if chara.Controllable:
								Global.toast(chara.FirstName+" looses control in Confusion!")
							else:
								if chara == chara.NextTarget and chara.NextMove.Target == Ability.T.ONE_ENEMY:
									Global.toast(chara.FirstName+" hits "+chara.Pronouns[3]+" in Confusion!")
								elif chara.NextTarget in Bt.get_ally_faction(chara) and chara.NextMove.Target == Ability.T.ONE_ENEMY:
									Global.toast(chara.FirstName+" hits an ally in confusion!")
						state.turns -= 1
					"Leeched":
						if state.inflicter in TurnOrder:
							Bt.play_effect("LeechGrab1", chara, Vector2.ZERO, false, true)
							Bt.focus_cam(chara, 0.3)
							if chara.DamageRecivedThisTurn == 0:
								Bt.damage(chara, true, true, 4, false, true, true, Global.ElementColor.get("natural"))
							var dmg = chara.DamageRecivedThisTurn
							await $LeechGrab1.animation_finished
							var t = create_tween()
							t.set_ease(Tween.EASE_OUT)
							t.set_trans(Tween.TRANS_QUART)
							$LeechGrab1.play("LeechGrab2")
							t.tween_property($LeechGrab1, "global_position", state.inflicter.node.global_position, 0.5)
							Bt.focus_cam(state.inflicter, 0.5, 40)
							await t.finished
							Bt.heal(state.inflicter, dmg)
							$LeechGrab1.play("LeechGrab3")
							await $LeechGrab1.animation_finished
							$LeechGrab1.queue_free()
						else: chara.remove_state(state)
					"Aggro":
						if state.inflicter not in TurnOrder or state.inflicter.has_state("KnockedOut"):
							chara.remove_state(state)
							chara.NextTarget = null
	for i in range(chara.States.size() -1, -1, -1):
		var state = chara.States[i]
		if state.QueueRemove:
			chara.remove_state(state)
	if chara.States.is_empty(): chara.node.get_node("State").play("None")
	chara.DamageRecivedThisTurn = 0
	states_handled.emit()

#region Attacks
func AttackMira(target: Actor):
	Bt.zoom()
	Bt.focus_cam(target, 0.5, 30)
	Bt.anim("Attack1")
	Bt.play_sound("Attack1", CurrentChar)
	Bt.jump_to_target(CurrentChar, target, Vector2(Bt.offsetize(-30), 0), 4)
	await Bt.anim_done
	if not miss:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.screen_shake(15, 7, 0.2)
		Bt.anim("Attack2")
		Bt.play_effect("SimpleHit", target)
		Bt.damage(target)
	else:
		Bt.anim("Attack2")
		Bt.miss()
	if crit:
		Bt.damage(target, CurrentChar.Attack, true)
		Bt.pop_num(target, "CRITICAL", Bt.CurrentAbility.WheelColor)
	await get_tree().create_timer(0.4).timeout
	Bt.return_cur()
	Bt.anim("Idle")
	Bt.end_turn()

func JumpAttack(target: Actor):
	Bt.zoom(5)
	Bt.focus_cam(target, 0.5, 30)
	Bt.anim("Attack1")
	Bt.jump_to_target(CurrentChar, target, Vector2(Bt.offsetize(-30), 0), 4)
	await Bt.anim_done
	if not miss:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target, CurrentChar.Attack, false)
		Bt.screen_shake(15, 7, 0.2)
		Bt.anim("Attack2")
		Bt.play_effect("SimpleHit", target)
	else: Bt.miss()
	await Event.wait(0.4)
	Bt.return_cur()
	Bt.anim("Idle")
	Bt.end_turn()

func AttackAlcine(target: Actor):
	Bt.zoom()
	Bt.focus_cam(target, 0.5, 30)
	Bt.anim("Attack1")
	await Event.wait(0.2)
	await Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-57),0), 0.4, Tween.EASE_OUT)
	if not miss:
		Bt.damage(target)
		Bt.screen_shake(8, 5, 0.1)
		Bt.anim("Attack2")
		Bt.move(target, target.node.position + Vector2(Bt.offsetize(-10),0), 0.3, Tween.EASE_OUT)
		Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-70),0), 0.3, Tween.EASE_OUT)
		await Event.wait(0.6)
		if crit:
			Bt.damage(target, CurrentChar.Magic, true)
			Bt.screen_shake(15, 7, 0.3)
			Bt.pop_num(target, "CRITICAL", Bt.CurrentAbility.WheelColor)
		else: 
			Bt.damage(target, CurrentChar.Attack, false)
			Bt.screen_shake(10, 7, 0.3)
		Bt.move(target, target.node.position + Vector2(Bt.offsetize(10),0), 0.5, Tween.EASE_OUT)
		await CurrentChar.node.animation_finished
	else: Bt.miss()
	Bt.anim("Idle")
	await Event.wait(0.3)
	Bt.return_cur()
	Bt.end_turn()

func AttackDaze(target: Actor):
	Bt.zoom(5)
	Bt.focus_cam(target, 0.5, 30)
	Bt.anim("Attack1")
	Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-30), 0), 0.3)
	await Bt.anim_done
	if not miss:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target, CurrentChar.Attack, false)
		Bt.screen_shake(5, 7, 0.2)
		Bt.shake_actor()
		Bt.anim("Attack2")
		Bt.play_effect("SimpleHit", target)
		if crit:
			await Event.wait(0.3)
			Bt.anim("Attack3")
			Bt.play_effect("SimpleHit", target)
			Bt.screen_shake(10, 7, 0.2)
			Bt.damage(target, CurrentChar.Attack, true)
			Bt.pop_num(target, "CRITICAL", Bt.CurrentAbility.WheelColor)
	else: Bt.miss()
	await Event.wait(0.4)
	Bt.return_cur()
	Bt.anim("Idle")
	Bt.end_turn()

func AttackAsteria(target: Actor):
	Bt.zoom()
	Bt.focus_cam(CurrentChar, 0.5, 30)
	Bt.anim("Attack1")
	await Bt.focus_cam(target, 1, 30)
	Bt.play_effect("RemoteHit", target)
	if not miss:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target)
		Bt.screen_shake()
	else: Bt.miss()
	await Event.wait(0.3)
	roll_rng(target)
	Bt.play_effect("RemoteHit", target)
	if not miss:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target)
		Bt.screen_shake()
	else: Bt.miss()
	await Event.wait(0.5)
	Bt.play_effect("RemoteHit", target)
	if crit:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target, CurrentChar.Attack, true)
		Bt.screen_shake()
		Bt.pop_num(target, "CRITICAL", Bt.CurrentAbility.WheelColor)
	await Event.wait(0.5)
	Bt.anim()
	Bt.end_turn()

func StickAttack(target: Actor):
	Bt.zoom()
	Bt.focus_cam(target, 0.5, 30)
	Bt.anim("Attack1")
	Bt.jump_to_target(CurrentChar, target, Vector2(Bt.offsetize(-30), -30), 4)
	await Bt.anim_done
	Bt.move(CurrentChar, target.node.position, 0.5, Tween.EASE_IN)
	Bt.play_sound("Attack2", CurrentChar)
	Bt.damage(target)
	Bt.screen_shake(15, 7, 0.2)
	Bt.anim("Attack2")
	Bt.play_effect("SimpleHit", target)
	await get_tree().create_timer(0.4).timeout
	Bt.return_cur()
	Bt.anim()
	Bt.end_turn()

func WarpAttack(target: Actor):
	Bt.zoom()
	Bt.move(CurrentChar, Vector2(Bt.offsetize(30), Bt.initial.y), 0.4)
	Bt.focus_cam(target, 0.6, 30)
	CurrentChar.node.get_node("Shadow").hide()
	await Bt.anim("Attack1")
	CurrentChar.node.position = Vector2(target.node.position.x + Bt.offsetize(-30), target.node.position.y)
	Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-5), 0), 0.8)
	Bt.anim("Attack2")
	await Event.wait(0.2)
	if not miss:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target)
		Bt.screen_shake()
	else: Bt.miss()
	await Event.wait(0.7)
	CurrentChar.node.position = Bt.initial + Vector2(Bt.offsetize(-50), 0)
	Bt.return_cur()
	CurrentChar.node.get_node("Shadow").show()
	Bt.end_turn()
	var temp = CurrentChar
	temp.node.play_backwards("Attack1")
	await temp.node.animation_finished
	Bt.anim("Idle", temp)

func RemoteAttack(target: Actor):
	Bt.zoom()
	Bt.focus_cam(CurrentChar, 0.5, 30)
	Bt.anim("Attack1")
	await Event.wait(0.6)
	await Bt.screen_shake(7, 5, 0.2)
	await Bt.focus_cam(target, 1, 30)
	Bt.play_effect("RemoteHit", target)
	await Event.wait(0.4)
	if not miss:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target)
		Bt.screen_shake()
	else: Bt.miss()
	await Event.wait(0.5)
	Bt.anim()
	Bt.end_turn()

func CloseupAttack(target: Actor):
	Bt.zoom()
	Bt.focus_cam(target)
	Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-20), 0), 0.8)
	await Bt.anim("Attack1")
	Bt.anim("Attack2")
	await Event.wait(0.2)
	if not miss:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target)
		Bt.play_effect("SimpleHit", target)
		Bt.screen_shake(18)
	else: Bt.miss()
	await Event.wait(0.5)
	Bt.return_cur()
	Bt.anim()
	Bt.end_turn()

func AOEAttack(target: Actor):
	if target == CurrentChar:
		Bt.focus_cam(CurrentChar)
		Bt.anim("Attack1")
		Bt.move(CurrentChar, Vector2(Bt.offsetize(-20), 0), 0.5, Tween.EASE_OUT)
		await Event.wait(0.5)
		Bt.move_cam(Vector2(Bt.offsetize(20), 0), 1)
		Bt.zoom(4.5, 1)
		await Bt.anim("Attack2")
		additional_done.emit()
		await Event.wait(1)
		Bt.return_cur()
		Bt.anim()
	else:
		if miss: Bt.miss(target)
		else:
			Bt.play_sound("Attack2", CurrentChar)
			Bt.damage(target)
			Bt.play_effect("SimpleHit", target)
			Bt.screen_shake(18)
	Bt.end_turn()
#endregion

################################################

#region Abilities
func Guard(target: Actor):
	Bt.zoom()
	Bt.anim("Idle")
	Bt.focus_cam(CurrentChar)
	await CurrentChar.add_state("Guarding")
	await Event.wait(0.5)
	Bt.end_turn()

func PhantomGuard(target: Actor):
	Bt.zoom()
	Bt.anim("Idle")
	Bt.focus_cam(CurrentChar)
	Bt.aura_overwrite(target, Bt.CurrentAbility.WheelColor)
	await Event.wait(0.5)
	await CurrentChar.add_state("Guarding")
	await Event.wait(0.5)
	Bt.end_turn()

func SoothingSpray(target: Actor):
	Bt.zoom(5)
	Bt.anim("Cast")
	Bt.focus_cam(target, 1)
	Bt.heal(target)
	await CurrentChar.node.animation_finished
	Bt.anim()
	Bt.end_turn()

func SoothingRain(target: Actor):
	if target == CurrentChar:
		Bt.zoom(4)
		Bt.move_cam(Vector2(-30, 0))
		await Bt.anim("Cast")
		additional_done.emit()
	Bt.heal(target)
	if crit:
		Bt.stat_change("Mag", 0.5, target)
	Bt.anim()
	Bt.end_turn()

func FlameSpark(target: Actor):
	Bt.zoom(5)
	Bt.focus_cam(CurrentChar, 0.3)
	Bt.anim("FlameSpark")
	await Event.wait(0.1)
	Bt.glow(0)
	await get_tree().create_timer(0.3).timeout
	Bt.play_effect("FlameSpark", target)
	if miss: Bt.miss()
	else:
		Bt.focus_cam(target, 0.3)
		await Event.wait(0.2)
		Bt.damage(target, true, true)
		await Event.wait(0.8)
		await target.add_state("Burned")
	await Event.wait(0.8)
	Bt.anim("Idle")
	Bt.end_turn()

func RagingFire(target: Actor):
	Bt.zoom(5)
	Bt.focus_cam(CurrentChar, 0.3, 20)
	Bt.anim("FlameSpark")
	await Event.wait(0.1)
	Bt.glow(0)
	await get_tree().create_timer(0.3).timeout
	Bt.play_effect("FlameSpark", target)
	Bt.focus_cam(target, 0.3)
	await Event.wait(0.2)
	Bt.screen_shake()
	Bt.damage(target, true, true)
	await Event.wait(0.8)
	if crit:
		await target.add_state("Burned")
	await Event.wait(0.8)
	Bt.anim("Idle")
	Bt.end_turn()

func Summon(target: Actor):
	Bt.zoom(5)
	Bt.focus_cam(CurrentChar, 0.3, 0)
	await Bt.anim("Cast")
	if CurrentChar.SummonedAllies.is_empty(): Global.toast("But " + CurrentChar.FirstName + " has no friends.")
	elif miss:
		Global.toast("But nobody came.")
		await Event.wait(1)
	else:
		Loader.white_fadeout(1, 0.5, 1)
		await Event.wait(1)
		Bt.add_to_troop(CurrentChar.SummonedAllies.pick_random())
		await Event.wait(2)
	Bt.anim()
	Bt.end_turn()

func SoulTap(target: Actor):
	Bt.zoom(6)
	Bt.focus_cam(target, 1)
	Bt.anim("Cast", CurrentChar)
	Bt.play_effect("SoulTap", target)
	await Event.wait(1)
	if crit: target.add_state("Confused")
	await Bt.shake_actor(target, 1)
	Bt.screen_shake(8, 5, 0.1)
	Bt.damage(target, true, true)
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()

func Needle(target: Actor):
	Bt.zoom(5)
	Bt.focus_cam(target, 1)
	Bt.anim("Cast", CurrentChar)
	Bt.play_effect("Needle", target, Vector2(Bt.offsetize(-15), -15), true)
	if !miss:
		await Event.wait(0.3)
		Bt.screen_shake(12, 5, 0.1)
		Bt.damage(target, true, true)
	else: Bt.miss()
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()

func AttackUp3(target: Actor):
	Bt.anim("Cast", CurrentChar)
	Bt.zoom(6)
	Bt.focus_cam(target)
	await Bt.stat_change(&"Atk", Bt.CurrentAbility.Parameter, target, 3)
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()

func MagicUp3(target: Actor):
	Bt.anim("Cast", CurrentChar)
	Bt.zoom(6)
	Bt.focus_cam(target)
	await Bt.stat_change(&"Mag", Bt.CurrentAbility.Parameter, target, 3)
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()

func ToxicSplash(target: Actor):
	Bt.anim("Cast", CurrentChar)
	Bt.zoom(6)
	Bt.focus_cam(target, 1)
	Bt.play_effect("ToxicSplash", target)
	await Event.wait(0.8)
	Bt.damage(target, true, true)
	Bt.screen_shake(8, 5, 0.1)
	await Event.wait(1)
	if crit: await target.add_state("Poisoned")
	Bt.anim()
	Bt.end_turn()

func IcyDrizzle(target: Actor):
	if target == CurrentChar:
		Bt.focus_cam(CurrentChar)
		Bt.anim("Cast")
		await Event.wait(0.5)
		Bt.move_cam(Vector2(Bt.offsetize(20), 0), 1)
		Bt.zoom(4.5, 1)
		additional_done.emit()
		await Event.wait(1)
		Bt.return_cur()
		Bt.anim()
	else:
		if miss: Bt.miss(target)
		else:
			Bt.damage(target, CurrentChar.Magic, true)
			Bt.screen_shake(5)
			if crit: await target.add_state("Frozen")
	Bt.end_turn()

func LeechSeeds(target: Actor):
	Bt.anim("Cast", CurrentChar)
	Bt.zoom(6)
	Bt.focus_cam(target, 1)
	Bt.play_effect("LeechSeeds", target)
	await Event.wait(1)
	if miss: Bt.miss()
	else:
		await target.add_state("Leeched")
	await Event.wait(0.5)
	Bt.anim()
	Bt.end_turn()

func Tighten(target: Actor):
	Bt.anim("Cast", CurrentChar)
	Bt.zoom(6)
	Bt.focus_cam(target, 1)
	#Bt.play_effect("Tighten", target)
	await Event.wait(1)
	if miss: Bt.miss()
	else:
		await target.add_state("Bound")
	await Event.wait(0.5)
	Bt.anim()
	Bt.end_turn()

func HeatWave(target: Actor):
	if target == CurrentChar:
		Bt.focus_cam(CurrentChar)
		Bt.zoom(6, 0.3)
		Bt.anim("Cast")
		await Event.wait(1)
		Bt.play_effect("HeatWave", Vector2(50, 0))
		Bt.play_sound("WindShort")
		Bt.move_cam(Vector2(40, 0), 1)
		Bt.zoom(5, 1)
		await Event.wait(1)
		additional_done.emit()
		await Event.wait(1)
		if Bt.filter_actors_by_state(Bt.get_oposing_faction(), "Burned").is_empty():
			Global.toast("Nothing happened.")
			await Event.wait(1)
		Bt.anim()
	else:
		if target.has_state("Burned"):
			await Bt.shake_actor(target)
			Bt.screen_shake(5)
			Bt.play_sound("BurnWoosh", target)
			Bt.damage(target, true, true)
		elif crit:
			target.add_state("Burned")
	Bt.end_turn()

func ProtectiveField(target: Actor):
	Bt.anim("Cast")
	Bt.focus_cam(target)
	await target.add_state("Protected")
	Bt.anim()
	Bt.end_turn()

func Attention(target: Actor):
	Bt.zoom()
	Bt.focus_cam(CurrentChar)
	Global.passive("BT_Daze", "attention")
	await Event.wait(1)
	Bt.focus_cam(target)
	target.add_state("Aggro")
	await Event.wait(0.5)
	Bt.anim()
	Bt.end_turn()
#endregion

################################################

#region Items
func Drink(target: Actor):
	Bt.focus_cam(CurrentChar, 0.3)
	Bt.zoom(5.5)
	print(Bt.CurrentAbility.Type)
	if Bt.CurrentAbility.Type == "Healing":
		Bt.heal(CurrentChar, int(Bt.CurrentAbility.Parameter))
	await Bt.anim("Cast")
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()

func Eat(target: Actor):
	Bt.focus_cam(CurrentChar, 0.3)
	Bt.zoom(5.5)
	print(Bt.CurrentAbility.Type)
	if Bt.CurrentAbility.Type == "Healing":
		Bt.heal(CurrentChar, int(Bt.CurrentAbility.Parameter))
	await Bt.anim("Cast")
	await Event.wait(1)
	Bt.end_turn()

func ItemCure(target: Actor):
	Bt.focus_cam(CurrentChar, 0.3)
	Bt.zoom(5.5)
	print(Bt.CurrentAbility.Type)
	if Bt.CurrentAbility.Type == "Healing":
		Bt.heal(CurrentChar, int(Bt.CurrentAbility.Parameter))
	CurrentChar.remove_state(Bt.CurrentAbility.InflictsState)
	await Bt.anim("Cast")
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()

func ItemThrow(target: Actor):
	Bt.zoom(5.5)
	Bt.focus_cam(CurrentChar, 0.2)
	Bt.anim("Cast")
	await Event.wait(0.3)
	Bt.focus_cam(target)
	Bt.play_effect("Hit", target)
	Bt.screen_shake()
	Bt.damage(target, false, true, Global.calc_num(), true, false, true)
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()
#endregion

################################################

#region Death sequences
func FlyAway(chara: Actor):
	Bt.lock_turn = true
	Bt.focus_cam(chara, 0.5)
	Bt.zoom(6)
	await Event.wait(1, false)
	chara.node.flip_h = true
	Bt.anim("Fly", chara)
	Global.toast(chara.FirstName+" retreats from the battle")
	Bt.move(chara, Vector2(150, -150), 2)
	await Event.wait(2.5, false)
	Bt.death(chara)
#endregion

################################################

#region Battle events
func FirstBattle1():
	while !Global.Player: await Event.wait()
	Bt.no_misses = true
	Bt.no_crits = true
	Global.Player.position = Vector2(1470, 400)
	await Event.wait(2, false)
	Bt.Troop[0].node.position.x = 50
	Bt.focus_cam(Bt.Troop[0], 0.1, 70)
	Bt.zoom(6)
	Bt.Action = true
	Loader.InBattle = true
	Loader.get_node("Can").layer = 3
	await Global.textbox("story_events", "first_cutscene")
	Loader.battle_bars(4)
	Global.Player.hide()
	$"../EnemyUI"._on_battle_ui_target_foc(Bt.Troop[0])
	PartyUI.battle_state()
	await Event.wait(0.5, false)
	Loader.ungray.emit()
	await Event.wait(0.3, false)
	Loader.battle_bars(3)
	Bt.get_actor("Mira").node.animation = "Entrance"
	Bt.get_actor("Mira").node.frame = 2
	Bt.focus_cam(Bt.Troop[0], 2, 40)
	await Event.wait(1)
	Global.passive("story_events", "sstay_back")
	await Event.wait(1)
	Loader.InBattle = true
	await Bt.move(Bt.Troop[0], Vector2(40, 0), 1, Tween.EASE_OUT)
	await Bt.move(Bt.Troop[0], Vector2(40, 0), 1, Tween.EASE_OUT)
	$"../BattleUI/Ability".disabled = true
	$"../BattleUI/Command".disabled = true
	$"../BattleUI/Item".disabled = true
	$"../EnemyUI".all_enemy_ui()
	$"../EnemyUI/AllEnemies".show()
	Event.flag_progress("FirstBattle", 3)
	Bt.get_actor("Mira").DontIdle = true
	Bt.end_turn()

func FirstBattle2(target: Actor):
	await Bt.move(Bt.Troop[0], Vector2(30, 0), 1, Tween.EASE_OUT)
	await Bt.move(Bt.Troop[0], Vector2(20, 0), 1, Tween.EASE_OUT)
	await Event.wait(0.5)
	CurrentChar = Bt.Troop[0]
	target = Bt.Party.Leader
	Bt.CurrentChar = Bt.Troop[0]
	Bt.focus_cam(target, 0.5, 0)
	Bt.zoom(6, 3)
	Bt.anim("Attack1")
	Loader.battle_bars(2)
	Bt.jump_to_target(CurrentChar, target, Vector2(30, 0), 4)
	await Bt.anim_done
	Bt.screen_shake(10)
	Bt.anim("FirstBattle", Bt.Party.Leader)
	CurrentChar.node.hide()
	Bt.play_sound("Attack2", CurrentChar)
	Bt.damage(target, CurrentChar.Attack, false, 12, false)
	Global.passive("story_events", "gahh")
	await Event.wait(2)
	for i in 3:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target, CurrentChar.Attack, false, randi_range(1,5), false)
		await Event.wait(0.5)
	await Event.wait(1.8)
	target.Aura = 6
	PartyUI._check_party()
	Bt.glow(1.5, 0.5, Bt.Party.Leader)
	Bt.zoom(7, 1)
	await Event.wait(4)
	Bt.glow(1, 2, Bt.Party.Leader)
	Global.passive("story_events", "my_aura")
	await Event.wait(6)
	Bt.zoom(5, 3)
	Bt.move_cam(Vector2(-15,0), 3)
	Bt.anim()
	CurrentChar.node.position.x = 60
	CurrentChar.node.show()
	Bt.move(CurrentChar, Vector2(40, CurrentChar.node.position.y), 0.5)
	await target.node.animation_finished
	target.Abilities[0].disabled = true
	target.DontIdle = false
	Bt.anim("", target)
	$"../BattleUI/Ability".disabled = false
	$"../BattleUI/Attack".disabled = true
	CurrentChar.IgnoreStates = true
	await Event.wait(2)
	Event.pop_tutorial("ability")
	Bt.end_turn()

func FirstBattle22():
	Bt.lock_turn = true
	Event.pop_tutorial("aura1")
	Bt.get_actor("CS").NextAction = "Ability"
	Bt.get_actor("CS").NextMove = preload("res://database/Abilities/InnerFocus.tres")

func FirstBattle3():
	Bt.get_actor("Mira").Abilities[0].disabled = false
	Bt.get_actor("CS").NextAction = "Ability"
	Bt.get_actor("CS").NextMove = preload("res://database/Abilities/SoulTap.tres")
	Bt.lock_turn = true
	Event.pop_tutorial("aura2")

func FirstBattle4():
	$"../BattleUI/Attack".disabled = false
	Bt.get_actor("Mira").Aura = max(7, Bt.get_actor("Mira").Aura)
	Bt.lock_turn = true
	Event.pop_tutorial("aura3")

func FirstBattle5():
	Bt.focus_cam(Global.Party.Leader)
	Bt.zoom(6)
	$"../EnemyUI".hide()
	get_tree().paused = false
	Loader.InBattle = false
	Bt.get_actor("Mira").DontIdle = false
	Global.Party.Leader.node.get_node("Glow").hide()
	Loader.battle_bars(0)
	Bt.victory_anim(Global.Party.Leader)
	await Global.textbox("story_events", "what_this")
	Global.heal_party()
	Bt.ObtainedItems.clear()
	Bt.victory(true)

func AlcineWoods1():
	if Bt.get_actor("Mira").Health == 0: return
	Event.flag_progress("AlcineFollow4", 4)
	Bt.lock_turn = true
	Bt.Action = true
	await Global.passive("story_events", "going_nowhere")
	Event.CutsceneHandler.alcine_helps()

func AlcineWoods2():
	for i in Bt.TurnOrder:
		Bt.anim("Idle", i)
	Bt.focus_cam(Bt.get_actor("Alcine"))
	Bt.get_actor("Alcine").SpeedBoost =+ 10
	Bt.TurnOrder.sort_custom(Bt.speed_sort)
	Bt.get_actor("Alcine").NextAction = "Ability"
	Bt.get_actor("Alcine").NextMove = preload("res://database/Abilities/SoothingSpray.tres")
	Bt.get_actor("Alcine").NextTarget = Bt.get_actor("Mira")
	Bt.get_actor("Alcine").node.show()
	await Event.wait(2)
	Bt.end_turn()

func AlcineWoods3():
	await Bt.jump_to_target(Bt.get_actor("Alcine"), Bt.get_actor("Mira"), Vector2(-30, -10), 5)
	await Global.passive("story_events", "amazing")

func AlcineWoods4():
	#if Event.f("AlcineFollow", 5): return
	Event.CutsceneHandler.after_battle()

func ArenaGameOver():
	Global.textbox("testbush", "arena_over")
#endregion
