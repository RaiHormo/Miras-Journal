extends Resource
class_name PartyData

@export var Leader: Actor = load("res://database/Party/Mira.tres")
@export var Member1: Actor = null
@export var Member2: Actor = null
@export var Member3: Actor = null

func reset_party():
	Leader = Global.find_member("Mira")
	Member1 = null
	Member2 = null
	Member3 = null

func check_member(n) -> bool:
	if n==0: return true
	if n == 1 and Member1 != null:
		return true
	elif n == 2 and Member2 != null:
		return true
	elif n==3 and Member3 != null:
		return true
	else:
		return false

func make_unique():
	if Leader!=null: Leader = Leader.duplicate()
	if Member1!=null: Member1 = Member1.duplicate()
	if Member2!=null: Member2 = Member2.duplicate()
	if Member3!=null: Member3 = Member1.duplicate()

func set_to(p:PartyData):
	Leader = Global.find_member(p.Leader.codename)
	if p.Member1!=null: Member1 = Global.find_member(p.Member1.codename)
	else: Member1 = null
	if p.Member2!=null: Member2 = Global.find_member(p.Member2.codename)
	else: Member2 = null
	if p.Member3!=null: Member3 = Global.find_member(p.Member3.codename)
	else: Member3 = null

func set_to_strarr(p:Array[StringName]):
	if p.is_empty(): p = [&"Mira", &"", &"", &""]
	Leader = Global.find_member(p[0])
	if p[1] != &"": Member1 = Global.find_member(p[1])
	else: Member1 = null
	if p[2] != &"": Member2 = Global.find_member(p[2])
	else: Member2 = null
	if p[3] != &"": Member3 = Global.find_member(p[3])
	else: Member3 = null

func get_strarr() -> Array[StringName]:
	var arr: Array[StringName] = [&"", &"", &"", &""]
	arr[0] = Leader.codename
	if check_member(1): arr[1] = Member1.codename
	if check_member(2): arr[2] = Member2.codename
	if check_member(3): arr[3] = Member3.codename
	return arr

func get_member(num:int) -> Actor:
	match num:
		0: return Leader
		1: return Member1
		2: return Member2
		3: return Member3
	return null

func overwrite_member(num:int, actor:Actor):
	match num:
		0: Leader = actor
		1: Member1 = actor
		2: Member2 = actor
		3: Member3 = actor

func add(member: String):
	overwrite_member(Global.number_of_party_members(), Global.find_member(member))
	Global.check_party.emit()
	print(member, " joins the party at position ", Global.find_member(member))

func array() -> Array[Actor]:
	return [Leader, Member1, Member2, Member3]

func member_name(x: int) -> String:
	if check_member(x): return get_member(x).FirstName
	return "Nobody"

func has_member(mem: String):
	for i in array():
		if i != null and i.codename == mem: return true
	return false
