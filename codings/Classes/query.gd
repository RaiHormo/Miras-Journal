extends Node
#class_name Query


func get_direction(v: Vector2 = Global.PlayerDir, allow_zero = false) -> Vector2:
	if v == Vector2.ZERO and allow_zero: return Vector2.ZERO
	if abs(v.x) > abs(v.y):
		if v.x >0:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT
	else:
		if v.y >0:
			return Vector2.DOWN
		else:
			return Vector2.UP

func str_length(str: String):
	return str.length()

func get_mmm(month: int) -> String:
	match month:
		1: return "Jan"
		2: return "Feb"
		3: return "Mar"
		4: return "Apr"
		5: return "May"
		6: return "Jun"
		7: return "Jul"
		8: return "Aug"
		9: return "Sep"
		10: return "Oct"
		11: return "Nov"
		12: return "Dec"
	return "???"

func get_month_name(month: int) -> String:
	match month:
		1: return "January"
		2: return "February"
		3: return "March"
		4: return "April"
		5: return "May"
		6: return "June"
		7: return "July"
		8: return "August"
		9: return "September"
		10: return "October"
		11: return "November"
		12: return "December"
	return "Unknown"

func get_month(day: int) -> int:
	if day>0 and day<=30: return 11
	if day<=0: return 10
	else: return 0

func get_dir_letter(d: Vector2 = Global.PlayerDir) -> String:
	match  get_direction(d):
		Vector2.RIGHT:
			return "R"
		Vector2.LEFT:
			return "L"
		Vector2.UP:
			return "U"
		Vector2.DOWN:
			return "D"
		_: return "C"

func get_dir_from_letter(d: String) -> Vector2:
	match d:
		"R", "Right":
			return Vector2.RIGHT
		"L", "Left":
			return Vector2.LEFT
		"U", "Up":
			return Vector2.UP
		"D", "Down":
			return Vector2.DOWN
		_:
			return Vector2.ZERO


func tilemapize(pos: Vector2) -> Vector2:
	return Global.Area.local_to_map(pos)

func globalize(coords :Vector2i) -> Vector2:
	return Global.Area.map_to_local(coords)

func get_state(stat: StringName) -> State:
	return await Loader.load_res("res://database/States/" + stat + ".tres")

func get_dir_name(d: Vector2 = Global.PlayerDir) -> String:
	if get_direction(d) == Vector2.RIGHT:
		return "Right"
	elif get_direction(d) == Vector2.LEFT:
		return "Left"
	elif get_direction(d) == Vector2.UP:
		return "Up"
	elif get_direction(d) == Vector2.DOWN:
		return "Down"
	else: return "Center"

func in_360(nm) -> int:
	return wrapi(nm, 0, 359)

func find_member(Name: StringName) -> Actor:
	for i in Global.Members:
		if i.codename == Name: return i
	#push_error("No party member with the name "+ Name + " was found")
	return null

func calc_num(ab: Ability = Global.Bt.CurrentAbility, chara: Actor = null):
	var base: int
	match ab.Damage:
		Ability.D.NONE: base = 0
		Ability.D.WEAK: base = 12
		Ability.D.MEDIUM: base = 24
		Ability.D.HEAVY: base = 48
		Ability.D.SEVERE: base = 96
		Ability.D.CUSTOM: base = int(ab.Parameter)
		Ability.D.WEAPON: base = chara.WeaponPower if chara else Global.Bt.CurrentChar.WeaponPower
	if ab.DmgVarience:
		base = int(base * randf_range(0.8, 1.2))
	return base

func get_complimentaries() -> Array[Ability]:
	var rtn: Array[Ability]
	for i in Global.Complimentaries:
		rtn.append(await get_ability(i))
	return rtn

func get_ability(ab: String) -> Ability:
	if ResourceLoader.exists("res://database/Abilities/"+ab+".tres"):
		return await Loader.load_res("res://database/Abilities/"+ab+".tres")
	if ResourceLoader.exists("res://database/Abilities/Attacks/"+ab+".tres"):
		return await Loader.load_res("res://database/Abilities/Attacks/"+ab+".tres")
	return null

func to_tod_text(x: Event.TOD) -> String:
	match x:
		Event.TOD.MORNING: return "Morning"
		Event.TOD.DAYTIME: return "Daytime"
		Event.TOD.AFTERNOON: return "Afternoon"
		Event.TOD.EVENING: return "Evening"
		Event.TOD.NIGHT: return "Night"
	return "Dark hour"

func to_tod_icon(x: Event.TOD) -> Texture:
	if ResourceLoader.exists("res://UI/Calendar/" + to_tod_text(x) + ".png"):
		return await Loader.load_res("res://UI/Calendar/" + to_tod_text(x) + ".png")
	else: return null

func range_360(n1, n2) -> Array:
	if n2 > 359:
		var range1 = range(n1, 359)
		var range2 = range(0, n2 - 359)
		range1.append_array(range2)
		return range1
	elif n1 < 0:
		var range1 = range(0, n2)
		var range2 = range(359 + n1, 359)
		range2.append_array(range1)
		return range2
	else: return range(n1, n2)

func make_array_unique(arr: Array):
	for i in range(-1, arr.size() - 1):
		arr[i] = arr[i].duplicate()

func mem(Name: StringName) -> Actor:
	return Query.find_member(Name)

func number_of_party_members() -> int:
	var num = 0
	if check_member(0):
		num+=1
	if check_member(1):
		num+=1
	if check_member(2):
		num+=1
	if check_member(3):
		num+=1
	return num

func check_member(n: Variant) -> bool:
	if n is int:
		return Global.Party.check_member(n)
	elif n is String: return Global.Party.has_member(n)
	else: return false

func get_member_name(n:int) -> String:
	if Global.Party.check_member(0) and n==0:
		return Global.Party.Leader.codename
	elif Global.Party.check_member(1) and n==1:
		return Global.Party.Member1.codename
	elif Global.Party.check_member(2) and n==2:
		return Global.Party.Member2.codename
	elif Global.Party.check_member(3) and n==2:
		return Global.Party.Member3.codename
	else:
		return "Null"

func _quad_bezier(ti : float, p0 : Vector2, p1 : Vector2, p2: Vector2, target : Node2D) -> void:
	var q0 = p0.lerp(p1, ti)
	var q1 = p1.lerp(p2, ti)
	var r = q0.lerp(q1, ti)

	if target.has_method("is_on_wall") and target.is_on_wall(): return
	else: target.position = r

func global_quad_bezier(ti : float, p0 : Vector2, p1 : Vector2, p2: Vector2, target : Node2D) -> void:
	var q0 = p0.lerp(p1, ti)
	var q1 = p1.lerp(p2, ti)
	var r = q0.lerp(q1, ti)

	target.global_position = r

#Finds an ability of a certain type
func find_abilities(Char: Actor, type:String, ignore_cost:= false, targets: Ability.T = Ability.T.ANY) -> Array[Ability]:
	#print("Chosing a ", type, " ability")
	var AblilityList:Array[Ability] = Char.Abilities.duplicate()
	AblilityList.push_front(Char.StandardAttack)
	var Choices:Array[Ability] = []
	for i in AblilityList:
		if (i.Type == type and (targets == Ability.T.ANY or i.Target == targets)):
			if ((i.AuraCost < Char.Aura or i.AuraCost == 0) and i.HPCost < Char.Health) or ignore_cost:
				Choices.push_front(i)
				print(i.name, " AP: ", i.AuraCost, " Targets: ", i.Target)
			else: print("Not enough resources")
	return Choices

func find_ability(Char: Actor, type:String, ignore_cost:= false, targets: Ability.T = Ability.T.ANY) -> Ability:
	return find_abilities(Char, type, ignore_cost, targets)[0]

func is_everyone_fully_healed() -> bool:
	for i in Global.Party.array():
		if !is_instance_valid(i): continue
		if not i.is_fully_healed(): return false
	return true

func is_mem_healed(chara: Actor):
	if !is_instance_valid(chara): return true
	return chara.is_fully_healed()

func is_in_party(n:String) -> bool:
	if Global.Party.Leader.codename == n:
		return true
	elif Global.Party.check_member(1) and Global.Party.Member1.codename == n:
		return true
	elif Global.Party.check_member(2) and Global.Party.Member2.codename == n:
		return true
	elif Global.Party.check_member(3) and Global.Party.Member3.codename == n:
		return true
	else:
		return false

func replace_occurence(from: String, what: String, forwhat: String, occurence = 1):
	var idx = -1
	for i in occurence:
		idx = from.find(what, idx+1)
	if idx == -1: return from
	return from.substr(0, idx) + forwhat + from.substr(idx + what.length())

func get_affinity(attacker:Color) -> Affinity:
	var aff = Affinity.new()
	var pres = round(remap(attacker.s, 0, 1, 10, 75))
	var hue = round(remap(attacker.h, 0, 1, 0, 359))
	#print(in_360(hue-pres/4)," ", in_360(hue+pres/4))
	aff.hue = hue
	aff.color = attacker
	aff.oposing_hue = in_360(hue + 180)
	aff.oposing_range = range_360(aff.oposing_hue-pres/4, aff.oposing_hue+pres/4)
	aff.weak_range = range_360(aff.oposing_range[0]-1-pres, aff.oposing_range[0]+1)
	aff.resist_range = range_360(aff.oposing_range[-1]+1, aff.oposing_range[-1]+1+max(pres, 15))
	aff.near_range = range_360(hue-max(pres/3, 10), hue+max(pres/3, 10))
	return aff

func get_power_rating(power: int) -> String:
	if power < 6: return "Useless"
	if power < 12: return "Very weak"
	if power < 18: return "Weak"
	if power < 24: return "Servicable"
	if power < 30: return "Avrage"
	if power < 36: return "Fine"
	if power < 42: return "Kinda good"
	if power < 48: return "Pretty good"
	if power < 54: return "Sharp"
	if power < 60: return "Pretty strong"
	if power < 66: return "Excellent"
	if power < 72: return "Powerful"
	if power < 78: return "Very powerful"
	if power < 84: return "Formidable"
	if power < 90: return "Overpowered"
	if power < 96: return "Godly"
	return "Illegal"
