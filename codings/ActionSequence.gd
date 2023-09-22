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
	call(nam)

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
			Bt.focus_cam(chara, 0.3)
			if chara.Health - chara.calc_dmg(20,1,chara)<=0:
				chara.set_health(1)
			else:
				Bt.damage(chara, 1, 20, false)
				print(chara.FirstName, chara.States)
			await get_tree().create_timer(0.8).timeout
	states_handled.emit()

func AttackMira():
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	Bt.focus_cam(target, 0.5, 30)
	CurrentChar.node.play("Attack1")
	Bt.play_sound("Attack1", CurrentChar)
	Bt.jump_to_target(CurrentChar, target, Vector2(Bt.offsetize(-30), 0), 4)
	await Bt.anim_done
	if not miss:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target, CurrentChar.Attack)
		Bt.screen_shake(15, 7, 0.2)
		CurrentChar.node.play("Attack2")
		Bt.play_effect("SimpleHit", target)
	else:
		CurrentChar.node.play("Attack2")
		Bt.miss()
	await get_tree().create_timer(0.4).timeout
	Bt.return_cur()
	CurrentChar.node.play("Idle")
	Bt.end_turn()
	
func JumpAttack():
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	Bt.focus_cam(target, 0.5, 30)
	CurrentChar.node.play("Attack1")
	Bt.jump_to_target(CurrentChar, target, Vector2(Bt.offsetize(-30), 0), 4)
	await Bt.anim_done
	if not miss:
		Bt.play_sound("Attack2", CurrentChar)
		Bt.damage(target, CurrentChar.Attack)
		Bt.screen_shake(15, 7, 0.2)
		CurrentChar.node.play("Attack2")
		Bt.play_effect("SimpleHit", target)
	else: Bt.miss()
	await get_tree().create_timer(0.4).timeout
	Bt.return_cur()
	CurrentChar.node.play("Idle")
	Bt.end_turn()

func AttackAlcine():
#	Engine.time_scale = 0.2
#	CurrentChar.set_health(90)
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	Bt.focus_cam(target, 0.5, 30)
	CurrentChar.node.play("Attack1")
	await Event.wait(0.4)
	await Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-57),0), 0.5, Tween.EASE_OUT)
	if not miss:
		Bt.damage(target, CurrentChar.Attack, Bt.calc_num())
		Bt.screen_shake(8, 5, 0.1)
		CurrentChar.node.play("Attack2")
		Bt.move(target, target.node.position + Vector2(Bt.offsetize(-10),0), 0.3, Tween.EASE_OUT)
		Bt.move(CurrentChar, target.node.position + Vector2(Bt.offsetize(-70),0), 0.3, Tween.EASE_OUT)
		await Event.wait(0.6)
		Bt.screen_shake(15, 7, 0.3)
		Bt.damage(target, CurrentChar.Magic, Bt.calc_num())
		Bt.move(target, target.node.position + Vector2(Bt.offsetize(10),0), 0.5, Tween.EASE_OUT)
		await CurrentChar.node.animation_finished
	else: Bt.miss()
	CurrentChar.node.play("Idle")
	await Event.wait(0.3)
	Bt.return_cur()
	Bt.end_turn()


func StickAttack():
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	Bt.focus_cam(target, 0.5, 30)
	CurrentChar.node.play("Attack1")
	Bt.jump_to_target(CurrentChar, target, Vector2(Bt.offsetize(-30), -30), 4)
	await Bt.anim_done
	Bt.move(CurrentChar, target.node.position, 0.5, Tween.EASE_IN)
	Bt.play_sound("Attack2", CurrentChar)
	Bt.damage(target, CurrentChar.Attack)
	Bt.screen_shake(15, 7, 0.2)
	CurrentChar.node.play("Attack2")
	Bt.play_effect("SimpleHit", target)
	await get_tree().create_timer(0.4).timeout
	Bt.return_cur()
	CurrentChar.node.play("Idle")
	Bt.end_turn()

func Guard():
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	Bt.pop_num(CurrentChar, "Guarding")
	CurrentChar.DefenceMultiplier += 1
	CurrentChar.node.play("Idle")
	Bt.focus_cam(CurrentChar)
	Bt.CurrentChar.node.material.set_shader_parameter("outline_enabled", true)
	Bt.CurrentChar.node.material.set_shader_parameter("outline_color", Bt.CurrentChar.MainColor)
	CurrentChar.add_state("Guarding")
	await t.finished
	Bt.end_turn()

func SoothingSpray():
	CurrentChar.node.play("Cast")
	t.parallel().tween_property(Cam, "zoom", Vector2(5,5), 1)
	Bt.focus_cam(target, 1)
	Bt.heal(target)
	await CurrentChar.node.animation_finished
	CurrentChar.node.play("Idle")
	Bt.end_turn()

func FlameSpark():
	t.tween_property(Cam, "zoom", Vector2(5.5,5.5), 0.5)
	Bt.focus_cam(CurrentChar, 0.3)
	CurrentChar.node.play("FlameSpark")
	await get_tree().create_timer(0.8).timeout
	Bt.play_effect("FlameSpark", target)
	Bt.focus_cam(target, 0.3, 20)
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	await get_tree().create_timer(0.2).timeout
	Bt.damage(target, CurrentChar.Magic)
	target.add_state("Burned")
	await get_tree().create_timer(1).timeout
	Bt.pop_num(target, "Burned")
	await get_tree().create_timer(1).timeout
	CurrentChar.node.play("Idle")
	Bt.end_turn()
