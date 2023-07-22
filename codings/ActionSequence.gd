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

func play(nam, tar):
	TurnOrder = get_parent().TurnOrder
	CurrentChar = get_parent().CurrentChar
	target = tar
	Party = get_parent().Party
	Bt.Action=true
	CurrentChar.node.z_index = 1
	Loader.battle_bars(2)
	t = create_tween()
	t.set_trans(Tween.TRANS_QUART)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "position", position, 0)
	#t.tween_property(Cam, "position", CurrentChar.node.global_position  - Vector2(Bt.offsetize(-40),0), 0.1)
	#swdsst.parallel().tween_property(Cam, "zoom", Vector2(5,5), 0.1)
	call(nam)

################################################

func handle_states():
	for j in TurnOrder.size():
		var chara = TurnOrder[j-1]
		for i in chara.States.size():
			var state = chara.States[i-1]
			if state.RemovedAfterTurns:
				chara.States[i-1].turns -= 1
			if state.name == "Guarding" and state.turns == 0:
				chara.remove_state("Guarding")
				chara. DefenceMultiplier -= 1
				chara.node.material.set_shader_parameter("outline_enabled", false)
			

func AttackMira():
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	Bt.focus_cam(target, 0.5, 30)
	CurrentChar.node.play("Attack1")
	Bt.play_sound("Attack1", CurrentChar)
	Bt.jump_to_target(CurrentChar, target, Vector2(Bt.offsetize(-30), 0), 4)
	await Bt.anim_done
	Bt.play_sound("Attack2", CurrentChar)
	Bt.damage(target, Bt.calc_num(), CurrentChar.Attack)
	Bt.screen_shake(15, 7, 0.2)
	CurrentChar.node.play("Attack2")
	Bt.play_effect("SimpleHit", target)
	await get_tree().create_timer(0.4).timeout
	Bt.return_cur()
	CurrentChar.node.play("Idle")
	Bt.end_turn()
	
func JumpAttack():
	t.tween_property(Cam, "zoom", Vector2(5,5), 0.5)
	Bt.focus_cam(target, 0.5, 30)
	Bt.jump_to_target(CurrentChar, target, Vector2(Bt.offsetize(-30), 0), 4)
	await Bt.anim_done
	Bt.play_sound("Attack2", CurrentChar)
	Bt.damage(target, Bt.calc_num(), CurrentChar.Attack)
	Bt.screen_shake(15, 7, 0.2)
	Bt.play_effect("SimpleHit", target)
	await get_tree().create_timer(0.4).timeout
	Bt.return_cur()
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
