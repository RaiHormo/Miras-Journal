extends Node
@onready var Bt :Battle = get_parent()
var Char :Actor
signal ai_chosen

func ai() -> void:
	Char = Bt.CurrentChar
	if Char.has_state("KnockedOut"): Bt.end_turn(); return
	var HpSortedAllies = Bt.get_ally_faction(Char).duplicate()
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
		elif (Bt.health_precentage(HpSortedAllies[0]) <= 40 or (Bt.health_precentage(HpSortedAllies[0]) <= 75 and randi_range(0, 1) == 1)) and has_type("Healing") and HpSortedAllies[0].Health != 0:
			print(HpSortedAllies[0].FirstName, " needs healing")
			choose(find_ability("Healing").pick_random(), HpSortedAllies[0])
		elif Bt.get_ally_faction(Char).size() < 3 and randi_range(-1, Bt.get_ally_faction(Char).size()) == 0 and has_type("Summon"):
			print("I can summon an ally")
			choose(find_ability("Summon").pick_random())
		elif check_for_finishers() and not Char.IsEnemy:
			print("I can finish off")
		elif has_type("BigAttack") and (states_in_faction("", Bt.get_oposing_faction()) != null or Char.has_state("AtkUp") or Char.has_state("MagUp")):
			print("Chance for a big attack")
			choose(find_ability("BigAttack").pick_random(), states_in_faction("", Bt.get_oposing_faction()))
		elif has_type("Curse") and randi_range(0, 1) == 1 and (Char.BattleLog.is_empty() or Char.BattleLog.back().ability.Type != "Curse") and check_for_curses():
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
func find_ability(type:String, targets: Ability.T = Ability.T.ANY) -> Array[Ability]:
	#print("Chosing a ", type, " ability")
	var AblilityList:Array[Ability] = Char.Abilities.duplicate()
	AblilityList.push_front(Char.StandardAttack)
	if Char.StandardAttack == null: OS.alert(Char.FirstName + " has no standard attack.")
	for i: Ability in AblilityList.duplicate():
		if i.Damage == Ability.D.WEAPON: AblilityList.erase(i)
	var Choices:Array[Ability] = []
	if Char.NextTarget != null:
		if Char.NextTarget.IsEnemy == Char.IsEnemy:
			targets = Ability.T.ONE_ALLY
		else:
			targets = Ability.T.ONE_ENEMY
	for i in AblilityList:
		if i == null: continue
		if (i.Type == type and (targets == Ability.T.ANY or i.Target == targets)) and not (
		Char.has_state("Bound") and i.Damage == Ability.D.WEAPON):
			if (i.AuraCost < Char.Aura or i.AuraCost == 0) and i.HPCost < Char.Health:
				Choices.push_front(i)
				print(i.name, " AP: ", i.AuraCost, " Targets: ", i.Target)
			else: print("Not enough resources")
	return Choices

#Checks if they have an ability of a certain type
func has_type(type:String, targets: Ability.T = Ability.T.ANY) -> bool:
	#print("checking if i have a ", type)
	if not find_ability(type, targets).is_empty():
		return true
	else:
		return false

func choose(ab:Ability, tar:Actor=null) -> void:
	if ab == null: Bt.end_turn(); return
	if Char.NextTarget==null and tar==null:
		Char.NextTarget = Bt.random_target(ab)
	elif Char.NextTarget==null:
		Char.NextTarget = tar
	if Char.NextAction == "":
		if ab == Char.StandardAttack:
			Char.NextAction = "Attack"
		else:
			Char.NextAction = "Ability"
		Char.NextMove=ab
	if Char.has_state("Confused") and (ab.Target == Ability.T.ONE_ENEMY or ab.Target == Ability.T.ONE_ALLY or ab.Target == Ability.T.ANY):
		Char.NextTarget = Bt.TurnOrder.pick_random()
		Bt.confusion_msg()
	ai_chosen.emit()

func pick_general_ability() -> Ability:
	const n = 4
	var r: int
	var tries:= 0
	while true:
		if Char.has_state("KnockedOut") or Char.node == null or Char.Health == 0:
			Bt.death(Char)
			return null
		tries += 1
		if tries > 30:
			print("The AI got stuck in an infinite loop")
			return Char.StandardAttack
		var atk_chance = 0
		if Char.ActorClass == "Attacker": atk_chance = -1
		r = randi_range(atk_chance, n)
		match r:
			1:
				if has_type("AtkBuff") and has_class_in_faction("Attacker", Bt.get_ally_faction()):
					var tar: Actor = get_class_in_faction("Attacker", Bt.get_ally_faction()).pick_random()
					print("Found ", tar.FirstName)
					if tar.AttackMultiplier == 1 and ((tar == Char and Char.Health > 40) or tar != Char):
						Char.NextTarget = tar
						return find_ability("AtkBuff").pick_random()
					print(tar.FirstName, " is a bad target")
			2:
				if ((Char.Health < Char.MaxHP * 0.6 or Char.Aura < Char.MaxAura * 0.5) and
				(has_class_in_faction("Attacker", Bt.get_oposing_faction()) or has_class_in_faction("Boss", Bt.get_oposing_faction()))
				and (not Char.BattleLog.is_empty() and Char.BattleLog.back().ability.Type != "Defensive") and has_type("Defensive")):
					return find_ability("Defensive").pick_random()
			3:
				if has_type("BigAttack"):
					return find_ability("BigAttack").pick_random()
			4:
				if has_type("MagBuff") and has_class_in_faction("Mage", Bt.get_ally_faction()):
					var tar: Actor = get_class_in_faction("Mage", Bt.get_ally_faction()).pick_random()
					print("Found ", tar.FirstName)
					if tar.MagicMultiplier == 1 and ((tar == Char and Char.Health > 30) or tar != Char):
						Char.NextTarget = tar
						return find_ability("MagBuff").pick_random()
					print(tar.FirstName, " is a bad target")
			_:
				if has_type("CheapAttack"):
					return find_ability("CheapAttack").pick_random()
	return null

func has_class_in_faction(type: String, faction: Array[Actor]) -> bool:
	print("Checking if there's a "+ type)
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
	for i in find_ability("Curse"):
		if i.InflictsState == "": OS.alert(i.name + "is missing an InflictedState parameter")
		var inflicted = Bt.filter_actors_by_state(Bt.get_oposing_faction(), i.InflictsState)
		if randi_range(0, inflicted.size()) == 0:
			if inflicted.size() < Bt.get_oposing_faction().size():
				for j in range(0, Bt.get_oposing_faction().size()*2):
					var tar = Bt.get_oposing_faction().pick_random()
					if not tar.has_state(i.InflictsState):
						choose(i, tar)
						return true
	return false

func states_in_faction(state:String, faction: Array[Actor]) -> Actor:
	var sorted = faction.duplicate()
	sorted.sort_custom(func(a, b): return a.States.size() > b.States.size())
	for i in faction:
		if i.States.is_empty():
			sorted.erase(i)
		else:
			if state != "":
				if i.has_state(state): return i
	if sorted.is_empty():
		return null
	else: return sorted[0]

func check_for_finishers():
	for i in Bt.get_oposing_faction():
		if i.Health <= Char.WeaponPower * Char.Attack * Char.AttackMultiplier:
			choose(Char.StandardAttack, i)
			return true
	return false
