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
		if state.RemovedAfterTurns:
			state.turns -= 1
		if state.name == "Guarding" and state.turns == 0:
			chara.remove_state("Guarding")
			chara. DefenceMultiplier -= 1
			chara.node.material.set_shader_parameter("outline_enabled", false)
		if state.name == "Burned":
			chara.node.get_node("State").play("Burned")
			Bt.focus_cam(chara, 0.3)
			if chara.Health - chara.calc_dmg(20,1,chara)<=0:
				chara.set_health(1)
			else:
				Bt.damage(chara, 1, false, 20, false)
				#print(chara.FirstName, chara.States)
			await get_tree().create_timer(0.8).timeout

	states_handled.emit()

func AttackMira():
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
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
		await Bt.damage(target, CurrentChar.Attack, false)
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
#	Engine.time_scale = 0.2
#	CurrentChar.set_health(90)
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	Bt.focus_cam(target, 0.5, 30)
	Bt.anim("Attack1")
	await Event.wait(0.4)
	await Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-57),0), 0.5, Tween.EASE_OUT)
	if not miss:
		Bt.damage(target, CurrentChar.Attack, false, Bt.calc_num())
		Bt.screen_shake(8, 5, 0.1)
		Bt.anim("Attack2")
		Bt.move(target, target.node.position + Vector2(Bt.offsetize(-10),0), 0.3, Tween.EASE_OUT)
		Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-70),0), 0.3, Tween.EASE_OUT)
		await Event.wait(0.6)
		Bt.screen_shake(15, 7, 0.3)
		Bt.damage(target, CurrentChar.Magic, false, Bt.calc_num())
		Bt.move(target, target.node.position + Vector2(Bt.offsetize(10),0), 0.5, Tween.EASE_OUT)
		await CurrentChar.node.animation_finished
	else: Bt.miss()
	Bt.anim("Idle")
	await Event.wait(0.3)
	Bt.return_cur()
	Bt.end_turn()

func StickAttack():
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	Bt.focus_cam(target, 0.5, 30)
	Bt.anim("Attack1")
	Bt.jump_to_target(CurrentChar, target, Vector2(Bt.offsetize(-30), -30), 4)
	await Bt.anim_done
	Bt.move(CurrentChar, target.node.position, 0.5, Tween.EASE_IN)
	Bt.play_sound("Attack2", CurrentChar)
	Bt.damage(target, CurrentChar.Attack, false)
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
	CurrentChar.node.global_position = Vector2(target.node.global_position.x + Bt.offsetize(-30), target.node.global_position.y)
	Bt.move(CurrentChar, target.node.global_position + Vector2(Bt.offsetize(-20), 0), 0.8)
	Bt.anim("Attack2")
	await Event.wait(0.2)
	Bt.damage(target, CurrentChar.Attack)
	Bt.screen_shake()
	await Event.wait(0.7)
	CurrentChar.node.global_position = Bt.initial + Vector2(Bt.offsetize(-50), 0)
	Bt.return_cur()
	CurrentChar.node.get_node("Shadow").show()
	Bt.end_turn()
	var temp = CurrentChar
	temp.node.play_backwards("Attack1")
	await temp.node.animation_finished
	Bt.anim("Idle", temp)


################################################

func Guard():
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	Bt.pop_num(CurrentChar, "Guarding")
	CurrentChar.DefenceMultiplier += 1
	Bt.anim("Idle")
	Bt.focus_cam(CurrentChar)
	Bt.CurrentChar.node.material.set_shader_parameter("outline_enabled", true)
	Bt.CurrentChar.node.material.set_shader_parameter("outline_color", Bt.CurrentChar.MainColor)
	CurrentChar.add_state("Guarding")
	await t.finished
	Bt.end_turn()

func SoothingSpray():
	Bt.anim("Cast")
	t.parallel().tween_property(Cam, "zoom", Vector2(5,5), 1)
	Bt.focus_cam(target, 1)
	Bt.heal(target)
	await CurrentChar.node.animation_finished
	Bt.anim("Idle")
	Bt.end_turn()

func FlameSpark():
	t.tween_property(Cam, "zoom", Vector2(5.5,5.5), 0.5)
	Bt.focus_cam(CurrentChar, 0.3)
	Bt.anim("FlameSpark")
	await Event.wait(0.1)
	Bt.glow(0)
	await get_tree().create_timer(0.3).timeout
	Bt.play_effect("FlameSpark", target)
	Bt.focus_cam(target, 0.3, 20)
	t.stop()
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	await get_tree().create_timer(0.2).timeout
	Bt.damage(target, CurrentChar.Magic)
	target.add_state("Burned")
	await get_tree().create_timer(0.3).timeout
	Bt.pop_num(target, "Burned")
	await get_tree().create_timer(0.5).timeout
	Bt.anim("Idle")
	Bt.end_turn()

func Summon():
	Bt.add_to_troop(load("res://database/Enemies/WhiteSpawn.tres"))
	Bt.end_turn()

################################################

func Drink():
	Bt.focus_cam(CurrentChar, 0.3)
	Bt.zoom(5.5)
	if Bt.CurrentAbility.Type == Ability.TP.HEALING: Bt.heal(target, int(Bt.CurrentAbility.Parameter))
	await Bt.anim("Drink")
	Bt.end_turn()
