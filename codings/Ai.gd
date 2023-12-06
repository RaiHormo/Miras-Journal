extends Node
@onready var Bt :Battle = get_parent()
var Char :Actor
signal ai_chosen

func ai():
	Char = Bt.CurrentChar
	var HpSortedAllies = Bt.get_ally_faction(Char).duplicate()
	HpSortedAllies.sort_custom(Bt.hp_sort)
	for i in HpSortedAllies:
		print(i.FirstName, " - ", i.Health)
	if Char.NextAction == "":
		print("AI")
		#Checks if they have any abilities
		if Char.Abilities.size() == 0:
			print("No abilities, using standard attack")
			choose(Char.StandardAttack)
		#Checks if they can take out the enemy
		#Checks if anyone needs healing
		elif (float(HpSortedAllies[0].Health)/float(HpSortedAllies[0].MaxHP)*100) <= 50 and HpSortedAllies[0].Health != 0 and has_type(4):
			print(HpSortedAllies[0].FirstName, " needs healing")
			#4: Healing
			choose(find_ability(4), HpSortedAllies[0])
		else:
			print("Nothing else to do, using random move")
			choose(random_ability())

#Finds an ability of a certain type
func find_ability(type:int):
	print("Chosing a ", type, " ability")
	var AblilityList:Array[Ability] = Char.Abilities
	AblilityList.push_front(Char.StandardAttack)
	var Choices:Array[Ability] = []
	for i in AblilityList:
		if i.Type == type:
			Choices.push_front(i)
			print(i.name)
	if Choices.is_empty():
		print("I have no ", type,", using standard attack")
		choose(Char.StandardAttack)
	else:
		return Choices.pick_random()

#Checks if they have an ability of a certain type
func has_type(type:int):
	print("checking if i have a ", type)
	var AblilityList:Array[Ability] = Char.Abilities
	AblilityList.push_back(Char.StandardAttack)
	var Choices:Array[Ability]
	for i in AblilityList:
		if i.Type == type:
			print("I do")
			return true
	print("i do not")
	return false

func choose(ab:Ability, tar:Actor=null):
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

func random_ability():
	var r = randi_range(0, 1)
	while true:
		match r:
			0:
				return Char.StandardAttack
			1:
				if has_type(2):
					return find_ability(2)
				else: r-=1

