extends Node2D

var TurnOrder: Array[Actor]
var CurrentChar: Actor
var Party: PartyData
var Troop: Array[Actor]
var Turn: int
@onready var Cam :Camera2D = get_parent().get_child(2)
@onready var Bt :Battle = get_parent()
@onready var t: Tween
var target:Actor
var miss
var crit
signal states_handled

func play(nam, tar):
	TurnOrder = get_parent().TurnOrder
	CurrentChar = get_parent().CurrentChar
	target = tar
	Party = get_parent().Party
	Bt.Action=true
	CurrentChar.node.z_index = 1
	miss = false
	crit = false
	Loader.battle_bars(2)
	t = create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "position", position, 0)
	if randf_range(0,1)>Bt.CurrentAbility.SucessChance: miss = true
	if randf_range(0,1)<Bt.CurrentAbility.CritChance: crit = true
	#t.tween_property(Cam, "position", CurrentChar.node.global_position  - Vector2(Bt.offsetize(-40),0), 0.1)
	#swdsst.parallel().tween_property(Cam, "zoom", Vector2(5,5), 0.1)
	if has_method(nam): call(nam)
	else: OS.alert("Invalid action sequence"); Bt.end_turn()

################################################

func handle_states():
	var chara = Bt.CurrentChar
	for state in chara.States:
		if state.turns > -1:
			state.turns -= 1
			if state.turns == 0:
				match state.name:
					"Guarding":
						chara. DefenceMultiplier -= 1
						chara.node.material.set_shader_parameter("outline_enabled", false)
					"AttackUp": chara.AttackMultiplier -= 0.5
					"DefenceUp": chara.DefenceMultiplier -= 0.5
					"MagicUp": chara.MagicMultiplier -= 0.5
				chara.remove_state(state)
				continue
		match state.name:
			"Burned":
				chara.node.get_node("State").play("Burned")
				Bt.focus_cam(chara, 0.3)
				Bt.damage(chara, true, true, randi_range(3, 12), false, true, true, Global.ElementColor.get("heat"))
				await get_tree().create_timer(0.8).timeout
			"Poisoned":
				state.turns -= 1
				#chara.node.get_node("State").play("Poisoned")
				Bt.focus_cam(chara, 0.3)
				Bt.damage(chara, true, true, abs(state.turns)*6, false, true, true, Global.ElementColor.get("corruption"))
				await get_tree().create_timer(0.8).timeout
	if chara.States.is_empty(): chara.node.get_node("State").play("None")
	states_handled.emit()

#region Attacks
func AttackMira():
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
	await get_tree().create_timer(0.4).timeout
	Bt.return_cur()
	Bt.anim("Idle")
	Bt.end_turn()

func JumpAttack():
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

func AttackAlcine():
	Bt.zoom()
	Bt.focus_cam(target, 0.5, 30)
	Bt.anim("Attack1")
	await Event.wait(0.4)
	await Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-57),0), 0.5, Tween.EASE_OUT)
	if not miss:
		Bt.damage(target)
		Bt.screen_shake(8, 5, 0.1)
		Bt.anim("Attack2")
		Bt.move(target, target.node.position + Vector2(Bt.offsetize(-10),0), 0.3, Tween.EASE_OUT)
		Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-70),0), 0.3, Tween.EASE_OUT)
		await Event.wait(0.6)
		Bt.screen_shake(15, 7, 0.3)
		Bt.damage(target, CurrentChar.Magic, false)
		Bt.move(target, target.node.position + Vector2(Bt.offsetize(10),0), 0.5, Tween.EASE_OUT)
		await CurrentChar.node.animation_finished
	else: Bt.miss()
	Bt.anim("Idle")
	await Event.wait(0.3)
	Bt.return_cur()
	Bt.end_turn()

func StickAttack():
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

func WarpAttack():
	Bt.zoom()
	Bt.move(CurrentChar, Vector2(Bt.offsetize(30), Bt.initial.y), 0.4)
	Bt.focus_cam(target, 0.6, 30)
	CurrentChar.node.get_node("Shadow").hide()
	await Bt.anim("Attack1")
	CurrentChar.node.position = Vector2(target.node.position.x + Bt.offsetize(-30), target.node.position.y)
	Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-20), 0), 0.8)
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
#endregion

################################################

#region Abilities
func Guard():
	Bt.zoom()
	CurrentChar.DefenceMultiplier += 1
	Bt.anim("Idle")
	Bt.focus_cam(CurrentChar)
	Bt.CurrentChar.node.material.set_shader_parameter("outline_enabled", true)
	Bt.CurrentChar.node.material.set_shader_parameter("outline_color", Bt.CurrentChar.MainColor)
	CurrentChar.add_state("Guarding")
	Bt.pop_num(CurrentChar, "Guarding")
	await Event.wait(0.5)
	Bt.end_turn()

func SoothingSpray():
	Bt.zoom(5)
	Bt.anim("Cast")
	Bt.focus_cam(target, 1)
	Bt.heal(target)
	await CurrentChar.node.animation_finished
	Bt.anim()
	Bt.end_turn()

func FlameSpark():
	Bt.zoom(5)
	Bt.focus_cam(CurrentChar, 0.3)
	Bt.anim("FlameSpark")
	await Event.wait(0.1)
	Bt.glow(0)
	await get_tree().create_timer(0.3).timeout
	Bt.play_effect("FlameSpark", target)
	if miss: Bt.miss()
	else:
		Bt.focus_cam(target, 0.3, 20)
		await Event.wait(0.2)
		Bt.damage(target, true, true)
		target.add_state("Burned")
		await Event.wait(0.8)
		Bt.pop_num(target, "Burned")
	await Event.wait(0.8)
	Bt.anim("Idle")
	Bt.end_turn()

func Summon():
	Bt.zoom(5)
	Bt.focus_cam(CurrentChar, 0.3)
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

func SoulTap():
	Bt.zoom(5)
	Bt.focus_cam(target, 1, 0)
	Bt.anim("Cast", CurrentChar)
	Bt.play_effect("SoulTap", target)
	await Event.wait(1)
	await Bt.shake_actor(target, 1)
	Bt.screen_shake(8, 5, 0.1)
	Bt.damage(target, true, true)
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()

func Needle():
	Bt.zoom(5)
	Bt.focus_cam(target, 1, 0)
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

func AttackUp3():
	Bt.anim("Cast", CurrentChar)
	Bt.zoom(6)
	Bt.focus_cam(target)
	await Bt.stat_change(&"Atk", Bt.CurrentAbility.Parameter, target, 3)
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()

func ToxicSplash():
	Bt.anim("Cast", CurrentChar)
	Bt.zoom(6)
	Bt.focus_cam(target)
	target.add_state("Poisoned")
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()
#endregion

################################################

#region Items
func Drink():
	Bt.focus_cam(CurrentChar, 0.3)
	Bt.zoom(5.5)
	print(Bt.CurrentAbility.Type)
	if Bt.CurrentAbility.Type == "Healing":
		Bt.heal(target, int(Bt.CurrentAbility.Parameter))
	await Bt.anim("Cast")
	await Event.wait(1)
	Bt.anim()
	Bt.end_turn()

func Eat():
	Bt.focus_cam(CurrentChar, 0.3)
	Bt.zoom(5.5)
	print(Bt.CurrentAbility.Type)
	if Bt.CurrentAbility.Type == "Healing":
		Bt.heal(target, int(Bt.CurrentAbility.Parameter))
	await Bt.anim("Cast")
	await Event.wait(1)
	Bt.end_turn()
#endregion

################################################

#region Death sequences
func FlyAway(chara: Actor):
	Bt.lock_turn = true
	Bt.focus_cam(chara, 0.5, -20)
	Bt.zoom(6)
	await Event.wait(1, false)
	chara.node.flip_h = true
	Bt.anim("Fly", chara)
	Global.toast(chara.FirstName+" retreats from the battle")
	await Bt.move(chara, Vector2(150, -150), 2)
	await Event.wait(1, false)
	Bt.death(chara)
#endregion

################################################

#region Battle events
func FirstBattle1():
	while Global.Player == null: await Event.wait()
	Global.Player.position = Vector2(1470, 400)
	await Event.wait(2, false)
	Bt.Troop[0].node.position.x = 50
	Bt.focus_cam(Bt.Troop[0], 0.1, 70)
	Bt.zoom(6)
	Loader.InBattle = true
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
	await Event.wait(2)
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

func FirstBattle2():
	await Bt.move(Bt.Troop[0], Vector2(30, 0), 1, Tween.EASE_OUT)
	await Bt.move(Bt.Troop[0], Vector2(20, 0), 1, Tween.EASE_OUT)
	await Event.wait(0.5)
	CurrentChar = Bt.Troop[0]
	target = Bt.get_actor("Mira")
	Bt.CurrentChar = Bt.Troop[0]
	Bt.focus_cam(target, 0.5, 30)
	Bt.anim("Attack1")
	Loader.battle_bars(2)
	Bt.jump_to_target(CurrentChar, target, Vector2(30, 0), 4)
	await Bt.anim_done
	for i in 3:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target, CurrentChar.Attack, false)
		Bt.screen_shake(15, 7, 0.2)
		Bt.anim("Attack2")
		Bt.play_effect("SimpleHit", target)
		await Event.wait(0.5)
	Bt.get_actor("Mira").Aura = 6
	PartyUI._check_party()
	Bt.get_actor("Mira").Abilities[0].disabled = true
	Bt.get_actor("Mira").DontIdle = false
	Bt.anim("Ability", target)
	Bt.move(CurrentChar, Vector2(50, 0), 0.2, Tween.EASE_OUT)
	Bt.jump_to_target(CurrentChar, CurrentChar, Vector2(30, 0), 0.2)
	Bt.anim("Hit")
	await Event.wait(2)
	Bt.anim()
	$"../BattleUI/Ability".disabled = false
	$"../BattleUI/Attack".disabled = true
	Bt.end_turn()

func FirstBattle3():
	Bt.get_actor("Mira").Abilities[0].disabled = false
	Bt.get_actor("CS").NextAction = "Ability"
	Bt.get_actor("CS").NextMove = preload("res://database/Abilities/SoulTap.tres")

func FirstBattle4():
	$"../BattleUI/Attack".disabled = false
	Bt.get_actor("Mira").Aura = max(7, Bt.get_actor("Mira").Aura)

func AlcineWoods1():
	if Bt.get_actor("Mira").Health == 0: return
	Event.flag_progress("AlcineFollow4", 4)
	Bt.lock_turn = true
	Bt.Action = true
	await Global.passive("temple_woods_random", "going_nowhere")
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
	await Event.wait(1)
	Bt.end_turn()

func AlcineWoods3():
	await Bt.jump_to_target(Bt.get_actor("Alcine"), Bt.get_actor("Mira"), Vector2(-30, -10), 5)
	await Global.passive("temple_woods_random", "amazing")

func AlcineWoods4():
	#if Event.f("AlcineFollow", 5): return
	Event.CutsceneHandler.after_battle()
#endregion

