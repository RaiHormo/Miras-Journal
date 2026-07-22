class_name MJActionSequenceParser
extends SequenceGraphParser

var Bt: Battle
var CurrentChar: Actor
var Target: Actor
var CurrentAbility: Ability
enum Roll {HIT, CRIT, MISS}


func _execute_node(node_data: SequenceGraphNodeData) -> void:
	var data := node_data.data
	var type := node_data.type
	var output := node_data.outputs

	if not Bt:
		push_error("BT unset")
		return

	var dice := roll_rng()

	match type:
		"wait":
			var time: float = data.get("Time", 0.0)
			await Event.wait(time)

		"RNGCondition":
			if data["Reroll"]: dice = roll_rng()
			await execute_conditional(node_data, dice as int)

		"damage":
			await Bt.damage(
				Bt.get_actor(data["Actor"]) as Actor,
				data["Magic"] as bool if data.has("Magic") else CurrentAbility.Damage != Ability.D.WEAPON,
				data["Elemental"] as bool if data.has("Limiter") else false,
				data["Actor"] as int if data.has("Power") else Query.calc_num(),
				data["Effect"] if data.has("Effect") else true,
				data["Limiter"] as bool if data.has("Limiter") else false,
				data["IgnoreStats"] as bool if data.has("IgnoreStats") else false,
				data["Color"] as Color if data.has("Color") else Color.WHITE
			)

		"anim":
			await Bt.anim(
				data["Radio"] as String if data["Radio"] != "Reset" else "", data["Actor"]
			)

		"move":
			Bt.move(
				data["Actor"] as Actor,
				data["Position"] as Vector2,
				data["Time"] as float if data.has("time") else -1.0,
				data["TweenMode"] as Tween.EaseType if data.has("TweenMode") else Tween.EASE_IN_OUT,
				data["Offset"] as Vector2 if data.has("Offset") else Vector2.ZERO,
			)

		"jump_to_target":
			await _process_jump(node_data.data)

		"play_sound":
			_process_sound(node_data.data)

		"play_effect":
			_process_effect(node_data.data)


func roll_rng() -> Roll:
	if (
		not(Target.CantDodge or Target.has_state("Bound") or Target.has_state("Soaked"))
		and randf_range(0, 1) > Bt.CurrentAbility.SucessChance
		and not Bt.no_misses
	):
			return Roll.MISS
	elif randf_range(0, 1) < CurrentAbility.CritChance and not Bt.no_crits:
		return Roll.CRIT
	else:
		return Roll.HIT


func _process_jump(data: Dictionary) -> void:
	pass


func _process_sound(data: Dictionary) -> void:
	pass


func _process_effect(data: Dictionary) -> void:
	pass
