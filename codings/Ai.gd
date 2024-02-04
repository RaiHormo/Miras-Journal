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
		elif Bt.health_precentage(HpSortedAllies[0]) <= 40 and has_type("Healing") and HpSortedAllies[0].Health != 0:
			print(HpSortedAllies[0].FirstName, " needs healing")
			choose(find_ability("Healing").pick_random(), HpSortedAllies[0])
		else:
			#print(Bt.health_precentage(HpSortedAllies[0]))
			print("Nothing specific to do")
			choose(pick_general_ability())
	else:
		print("Forced move")
		match Char.NextAction:
			"Ability":
				choose(Char.NextMove, Char.NextTarget)

#Finds an ability of a certain type
func find_ability(type:String, targets: Ability.T = Ability.T.ANY) -> Array[Ability]:
	#print("Chosing a ", type, " ability")
	var AblilityList:Array[Ability] = Char.Abilities.duplicate()
	AblilityList.push_front(Char.StandardAttack)
	var Choices:Array[Ability] = []
	for i in AblilityList:
		if (i.Type == type and (targets == Ability.T.ANY or i.Target == targets)):
			if (i.AuraCost < Char.Aura or i.AuraCost == 0) and i.HPCost < Char.Health:
				Choices.push_front(i)
				print(i.name, " AP: ", i.AuraCost, " Targets: ", i.Target)
			else: print("Not enough resources")
	return Choices

#Checks if they have an ability of a certain type
func has_type(type:String, targets: Ability.T = Ability.T.ANY) -> bool:
	print("checking if i have a ", type)
	if not find_ability(type, targets).is_empty():
		print("i do")
		return true
	else:
		print("i do not")
		return false

func choose(ab:Ability, tar:Actor=null) -> void:
	if ab == null: Bt.end_turn(); return
	if Char.NextTarget==null and tar==null:
		match ab.Target:
			0:
				Char.NextTarget = Char
			1:
				Char.NextTarget = Bt.get_oposing_faction(Char).pick_random()
			3:
				Char.NextTarget = Bt.get_ally_faction(Char).pick_random()
	elif Char.NextTarget==null:
		Char.NextTarget = tar
	if ab == Char.StandardAttack:
		Char.NextAction = "Attack"
	else:
		Char.NextAction = "Ability"
	Char.NextMove=ab
	print("Using ", ab.name, " on ", Char.NextTarget.FirstName)
	ai_chosen.emit()

func pick_general_ability() -> Ability:
	const n = 1
	var r: int
	var tries:= 0
	while true:
		tries += 1
		if tries > 99:
			OS.alert("The AI got stuck in an infinite loop, the dev might want to check on that")
			return Char.StandardAttack
		r = randi_range(0, n)
		match r:
			0:
				if has_type("CheapAttack"):
					return find_ability("CheapAttack").pick_random()
			1:
				if Char.Health < Char.MaxHP * 0.7 and has_type("Defensive"):
					return find_ability("Defensive").pick_random()
				if has_type("AtkBuff") and has_class_in_faction("Attacker", Bt.get_ally_faction()):
					var tar: Actor = get_class_in_faction("Attacker", Bt.get_ally_faction()).pick_random()
					print("Found ", tar.FirstName)
					if tar.AttackMultiplier == 1 and ((tar == Char and Char.Health > 40) or tar != Char):
						Char.NextTarget = tar
						return find_ability("AtkBuff").pick_random()
					print(tar.FirstName, " is a bad target")
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
