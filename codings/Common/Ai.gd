extends Node

@onready var Bt: Battle = get_parent()
var Char: Actor
signal ai_chosen


func ai() -> void:
	Char = Bt.CurrentChar
	if Char.has_state("KnockedOut") or Char.Health == 0:
		Bt.end_turn()
		return

	if Char.NextAction != "":
		print("Forced move")
		choose(Char.NextMove, Char.NextTarget)
		return

	var best_ability: Ability = null
	var best_target: Actor = null
	var highest_score: float = -1.0

	var available_abilities: Array[Ability] = Char.Abilities.duplicate()
	if Char.StandardAttack: available_abilities.append(Char.StandardAttack)

	for ability in available_abilities:
		if not is_instance_valid(ability) or not can_afford(ability):
			continue

		var valid_targets := get_valid_targets(ability)
		for target in valid_targets:
			var score := evaluate_action(ability, target)

			# Add slight variance to break ties and prevent predictable loops
			score += randf_range(0.0, 5.0)

			if score > highest_score:
				highest_score = score
				best_ability = ability
				best_target = target

	if best_ability == null:
		print("No optimal move, defaulting to Standard Attack")
		best_ability = Char.StandardAttack
		best_target = Bt.random_target(best_ability)

	choose(best_ability, best_target)


func evaluate_action(ab: Ability, tar: Actor) -> float:
	var score := 0.0

	for type in ab.Types:
		match type:
			Ability.TP.HEALING:
				if is_ally(tar):
					var hp_pct = Bt.health_precentage(tar)
					# Scales up as HP gets lower
					if hp_pct <= 40:
						score += (1 - hp_pct / 100)
					elif hp_pct <= 75:
						score += 0.3
			Ability.TP.SUMMON:
				if Bt.get_ally_faction(Char).size() < 3: score += 60.0
			Ability.TP.CHEAP_ATTACK:
				if is_enemy(tar):
					# Prioritize an attack that will finish off the enemy
					if tar.Health <= (Char.WeaponPower * Char.Attack * Char.AttackMultiplier):
						score = 1
					else:
						score += 0.2
			Ability.TP.BIG_ATTACK:
				if is_enemy(tar):
					if Char.Aura > Char.MaxAura / 2.0 or Char.has_state("AtkUp") or Char.has_state("MagUp"):
						score += 0.7
			Ability.TP.CURSE:
				if not tar.has_state(ab.InflictsState): score += 0.55
			Ability.TP.ATK_BUFF:
				if tar.ActorClass == "Attacker" and tar.AttackMultiplier <= 1.0: score += 0.5
			Ability.TP.MAG_BUFF:
				if tar.ActorClass == "Mage" and tar.MagicMultiplier <= 1.0:
					score += 0.5
			Ability.TP.DEF_BUFF:
				if tar.DefenceMultiplier <= 1.0:
					score += 0.5
			Ability.TP.AGGRO:
				if tar.ActorClass in ["Attacker", "Boss"]:
					score += 0.6
			Ability.TP.DEFENSIVE:
				if Char.Health < Char.MaxHP * 0.6 or Char.Aura < Char.MaxAura * 0.6:
					score += 0.65

	return score


func can_afford(ab: Ability) -> bool:
	if Char.has_state("Bound") and ab.Damage == Ability.D.WEAPON: return false
	return (ab.AuraCost == 0 or ab.AuraCost <= Char.Aura) and ab.HPCost < Char.Health


func get_valid_targets(ab: Ability) -> Array[Actor]:
	var targets: Array[Actor] = []
	match ab.Target:
		Ability.T.SELF:
			targets.append(Char)
		Ability.T.ONE_ALLY:
			targets.append_array(Bt.get_ally_faction(Char))
		Ability.T.ONE_ENEMY:
			targets.append_array(Bt.get_oposing_faction())
		Ability.T.ANY:
			targets.append_array(Bt.get_ally_faction(Char))
			targets.append_array(Bt.get_oposing_faction())
	return targets


func is_ally(tar: Actor) -> bool:
	return Char.IsEnemy == tar.IsEnemy


func is_enemy(tar: Actor) -> bool:
	return not is_ally(tar)


func choose(ab: Ability, tar: Actor = null) -> void:
	if ab == null:
		Bt.end_turn()
		return

	if Char.NextTarget == null and tar == null:
		Char.NextTarget = Bt.random_target(ab)

	if ab.Target == Ability.T.SELF: tar = Char
	elif Char.NextTarget == null: Char.NextTarget = tar

	if Char.NextAction == "":
		Char.NextAction = "Attack" if ab == Char.StandardAttack else "Ability"
		Char.NextMove = ab

	if Char.has_state("Confused") and ab.Target in [Ability.T.ONE_ENEMY, Ability.T.ONE_ALLY, Ability.T.ANY]:
		Char.NextTarget = Bt.TurnOrder.pick_random()
		Bt.confusion_msg()

	ai_chosen.emit()
