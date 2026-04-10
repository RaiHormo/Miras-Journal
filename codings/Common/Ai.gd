extends Node
@onready var Bt: Battle = get_parent()
var Char: Actor
signal ai_chosen


func ai() -> void:
	Char = Bt.CurrentChar
	if Char.has_state("KnockedOut") or Char.Health == 0: Bt.end_turn(); return
	var HpSortedAllies := Bt.get_ally_faction(Char).duplicate()
	HpSortedAllies.sort_custom(Bt.hp_sort)
	#for i in HpSortedAllies:
		#print(i.FirstName, " - ", i.Health)
	if Char.NextAction == "":
		print("AI")
		#Checks if they have any abilities
		if Char.Abilities.size() == 0:
			print("No abilities, using standard attack")
			choose(Char.StandardAttack)
		#Checks if they can take out the enemy
		#Checks if anyone needs healing
		elif (
			(Bt.health_precentage(HpSortedAllies[0]) <= 40
			or (Bt.health_precentage(HpSortedAllies[0]) <= 75 and randi_range(0, 1) == 1))
			and has_type(Ability.TP.Healing) and HpSortedAllies[0].Health != 0
		):
			print(HpSortedAllies[0].FirstName, " needs healing")
			choose(find_ability(Ability.TP.Healing).pick_random(), HpSortedAllies[0])
		elif (
			Bt.get_ally_faction(Char).size() < 3 and
			randi_range(-1, Bt.get_ally_faction(Char).size()) == 0 and
			has_type(Ability.TP.Summon)
		):
			print("I can summon an ally")
			choose(find_ability(Ability.TP.Summon).pick_random())
		elif check_for_finishers() and not Char.IsEnemy:
			print("I can finish off")
		elif has_type(Ability.TP.BigAttack) and ((states_in_faction("", Bt.get_oposing_faction()) != null and Char.Aura > Char.MaxAura / 2) or Char.has_state("AtkUp") or Char.has_state("MagUp")):
			print("Chance for a big attack")
			choose(find_ability(Ability.TP.BigAttack).pick_random(), states_in_faction("", Bt.get_oposing_faction()))
		elif has_type(Ability.TP.Curse) and randi_range(0, 1) == 1 and (Char.BattleLog.is_empty() or Char.BattleLog.back().ability.Type != "Curse") and check_for_curses():
			print("Can use a curse")
		else:
			#print(Bt.health_precentage(HpSortedAllies[0]))
			print("Nothing specific to do")
			choose(pick_general_ability())
	else:
		print("Forced move")
		match Char.NextAction:
			"Ability":
				choose(Char.NextMove, Char.NextTarget)
			"Attack":
				choose(Char.NextMove, Char.NextTarget)


#Finds an ability of a certain type
func find_ability(type: Ability.TP, targets: Ability.T = Ability.T.ANY) -> Array[Ability]:
	#print("Chosing a ", type, " ability")
	var AblilityList: Array[Ability] = Char.Abilities.duplicate()
	if Char.StandardAttack == null: OS.alert(Char.FirstName + " has no standard attack.")
	AblilityList.append(Char.StandardAttack)
	for i: Ability in AblilityList.duplicate():
		if not is_instance_valid(i): AblilityList.erase(i)
	var Choices: Array[Ability] = []
	if Char.NextTarget != null:
		if Char.NextTarget.IsEnemy == Char.IsEnemy:
			targets = Ability.T.ONE_ALLY
		else:
			targets = Ability.T.ONE_ENEMY
	for i in AblilityList:
		if i == null: continue
		if (type in i.Types and (targets == Ability.T.ANY or i.Target == Ability.T.ANY or i.Target == targets)) and not(
		Char.has_state("Bound") and i.Damage == Ability.D.WEAPON):
			if (i.AuraCost == 0 or i.AuraCost < Char.Aura) and i.HPCost < Char.Health:
				Choices.append(i)
				print(i.name, " AP: ", i.AuraCost, " Targets: ", i.Target)
			else: print("Not enough resources")
	return Choices


#Checks if they have an ability of a certain type
func has_type(type: Ability.TP, targets: Ability.T = Ability.T.ANY) -> bool:
	#print("checking if i have a ", type)
	if not find_ability(type, targets).is_empty():
		return true
	else:
		return false


func choose(ab: Ability, tar: Actor = null) -> void:
	if ab == null: Bt.end_turn(); return
	if Char.NextTarget == null and tar == null:
		Char.NextTarget = Bt.random_target(ab)
	if ab.Target == Ability.T.SELF:
		tar = Char
	elif Char.NextTarget == null:
		Char.NextTarget = tar
	if Char.NextAction == "":
		if ab == Char.StandardAttack:
			Char.NextAction = "Attack"
		else:
			Char.NextAction = "Ability"
		Char.NextMove = ab
	if Char.has_state("Confused") and (ab.Target == Ability.T.ONE_ENEMY or ab.Target == Ability.T.ONE_ALLY or ab.Target == Ability.T.ANY):
		Char.NextTarget = Bt.TurnOrder.pick_random()
		Bt.confusion_msg()
	ai_chosen.emit()


##FIXME do not use magic numbers, don't loop over the same list at random, don't handle decision logic in the rng function
func pick_general_ability() -> Ability:
	const n = 7
	var r: int
	var tries := 0

	while true:
		if Char.has_state("KnockedOut") or Char.node == null or Char.Health == 0:
			Bt.death(Char)
			return null
		tries += 1
		if tries > 99:
			print("The AI got stuck in an infinite loop")
			return Char.StandardAttack
		var atk_chance := 0
		if Char.ActorClass == "Attacker": atk_chance = -1
		r = randi_range(atk_chance, n)
		#match r:
			#1:
				#if has_type("AtkBuff") and has_class_in_faction("Attacker", Bt.get_ally_faction()):
					#var tar: Actor = get_class_in_faction("Attacker", Bt.get_ally_faction()).pick_random()
					#print("Found ", tar.FirstName)
					#if tar.AttackMultiplier == 1 and ((tar == Char and Char.Health > 40) or tar != Char):
						#Char.NextTarget = tar
						#return find_ability("AtkBuff").pick_random()
					#print(tar.FirstName, " is a bad target")
			#2:
				#if has_type("Defensive"):
					#if ((Char.Health < Char.MaxHP * 0.6 or Char.Aura < Char.MaxAura * 0.6) or
						#(has_class_in_faction("Attacker", Bt.get_oposing_faction()) or has_class_in_faction("Boss", Bt.get_oposing_faction()))
						#and (not Char.BattleLog.is_empty() and Char.BattleLog.back().ability.Type != "Defensive")
					#):
						#return find_ability("Defensive").pick_random()
			#3:
				#if has_type("BigAttack") and (not Char.BattleLog.is_empty() and Char.BattleLog.back().ability.Type != "BigAttack"):
					#return find_ability("BigAttack").pick_random()
			#4:
				#if has_type("MagBuff") and has_class_in_faction("Mage", Bt.get_ally_faction()):
					#var tar: Actor = get_class_in_faction("Mage", Bt.get_ally_faction()).pick_random()
					#print("Found ", tar.FirstName)
					#if tar.MagicMultiplier <= 1 and ((tar == Char and Char.Health > 30) or tar != Char):
						#Char.NextTarget = tar
						#return find_ability("MagBuff").pick_random()
					#print(tar.FirstName, " is a bad target")
			#5:
				#if has_type("DefBuff"):
					#var tar: Actor = Bt.get_ally_faction().pick_random()
					#print("Found ", tar.FirstName)
					#if tar.DefenceMultiplier <= 1:
						#Char.NextTarget = tar
						#return find_ability("DefBuff").pick_random()
					#print(tar.FirstName, " is a bad target")
			#6:
				#if has_type("Aggro") and (has_class_in_faction("Attacker", Bt.get_oposing_faction()) or has_class_in_faction("Boss", Bt.get_oposing_faction())):
					#var targets := get_class_in_faction("Attacker", Bt.get_oposing_faction()).duplicate()
					#targets.append_array(get_class_in_faction("Boss", Bt.get_oposing_faction()))
					#var tar: Actor = targets.pick_random()
					#print("Found ", tar.FirstName)
					#if tar.ActorClass == "Attacker" or tar.ActorClass == "Boss":
						#Char.NextTarget = tar
						#return find_ability("Aggro").pick_random()
					#print(tar.FirstName, " is a bad target")
			#7:
				#if has_type("Curse"):
					#var ab: Ability = find_ability("Curse").pick_random()
					#var targets := Bt.filter_actors_by_state(Bt.get_oposing_faction(), ab.InflictsState)
					#if not targets.is_empty():
						#return ab
			#_:
				#if has_type("CheapAttack"):
					#return find_ability("CheapAttack").pick_random()
	return null


func get_available_ability_types(from: Array[Ability]) -> Array[String]:
	var result: Array[String] = []
	for ab in from:
		for type in ab.Types:
			if type not in result:
				result.append(ab.Type)
	return result


func is_good_choice(ab: Ability) -> bool:
	var result := false
	for type: Ability.TP in ab.types:
		match type:
			Ability.TP.AtkBuff:
				if has_class_in_faction("Attacker", Bt.get_ally_faction()):
					var tar: Actor = get_class_in_faction("Attacker", Bt.get_ally_faction()).pick_random()
					print("Found ", tar.FirstName)
					if tar.AttackMultiplier == 1 and ((tar == Char and Char.Health > 40) or tar != Char):
						Char.NextTarget = tar
						result = true
					print(tar.FirstName, " is a bad target")
			Ability.TP.Defensive:
				if ((Char.Health < Char.MaxHP * 0.6 or Char.Aura < Char.MaxAura * 0.6) or
						(has_class_in_faction("Attacker", Bt.get_oposing_faction()) or has_class_in_faction("Boss", Bt.get_oposing_faction()))
						and (not Char.BattleLog.is_empty() and Char.BattleLog.back().ability.Type != "Defensive")
					):
						result = true
			Ability.TP.BigAttack:
				if (not Char.BattleLog.is_empty() and Char.BattleLog.back().ability.Type != "BigAttack"):
					result = true
			Ability.TP.MagBuff:
				if has_class_in_faction("Mage", Bt.get_ally_faction()):
					var tar: Actor = get_class_in_faction("Mage", Bt.get_ally_faction()).pick_random()
					print("Found ", tar.FirstName)
					if tar.MagicMultiplier <= 1 and ((tar == Char and Char.Health > 30) or tar != Char):
						Char.NextTarget = tar
						result = true
					print(tar.FirstName, " is a bad target")
			Ability.TP.DefBuff:
				var tar: Actor = Bt.get_ally_faction().pick_random()
				print("Found ", tar.FirstName)
				if tar.DefenceMultiplier <= 1:
					Char.NextTarget = tar
					result = true
				print(tar.FirstName, " is a bad target")
			Ability.TP.Aggro:
				if (has_class_in_faction("Attacker", Bt.get_oposing_faction()) or has_class_in_faction("Boss", Bt.get_oposing_faction())):
					var targets := get_class_in_faction("Attacker", Bt.get_oposing_faction()).duplicate()
					targets.append_array(get_class_in_faction("Boss", Bt.get_oposing_faction()))
					var tar: Actor = targets.pick_random()
					print("Found ", tar.FirstName)
					if tar.ActorClass == "Attacker" or tar.ActorClass == "Boss":
						Char.NextTarget = tar
						result = true
					print(tar.FirstName, " is a bad target")
			Ability.TP.Curse:
				var targets := Bt.filter_actors_by_state(Bt.get_oposing_faction(), ab.InflictsState)
				if not targets.is_empty():
					result = true
			_:
				result = true
	return result


func has_class_in_faction(type: String, faction: Array[Actor]) -> bool:
	print("Checking if there's a " + type)
	for i in faction:
		if i.ActorClass == type:
			return true
	"There's not"
	return false


func get_class_in_faction(type: String, faction: Array[Actor]) -> Array[Actor]:
	var rtn: Array[Actor] = []
	for i in faction:
		if i.ActorClass == type:
			rtn.append(i)
	return rtn


func check_for_curses() -> bool:
	for i in find_ability(Ability.TP.Curse):
		if i.InflictsState == "": OS.alert(i.name + "is missing an InflictedState parameter")
		var inflicted := Bt.filter_actors_by_state(Bt.get_oposing_faction(), i.InflictsState)
		if randi_range(0, inflicted.size()) == 0:
			if inflicted.size() < Bt.get_oposing_faction().size():
				for j in range(0, Bt.get_oposing_faction().size() * 2):
					var tar: Actor = Bt.get_oposing_faction().pick_random()
					if (not tar.has_state(i.InflictsState)
					and (not i.InflictsState == "Aggro" or tar.StandardAttack.Target == Ability.T.ONE_ENEMY)):
						choose(i, tar)
						return true
	return false


func states_in_faction(state: String, faction: Array[Actor]) -> Actor:
	var sorted := faction.duplicate()
	sorted.sort_custom(func(a: Actor, b: Actor) -> bool: return a.States.size() > b.States.size())
	for i in faction:
		if i.States.is_empty():
			sorted.erase(i)
		else:
			if state != "":
				if i.has_state(state): return i
	if sorted.is_empty():
		return null
	else: return sorted[0]


func check_for_finishers() -> bool:
	for i in Bt.get_oposing_faction():
		if i.Health <= Char.WeaponPower * Char.Attack * Char.AttackMultiplier:
			choose(Char.StandardAttack, i)
			return true
	return false
