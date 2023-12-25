extends Resource
class_name PartyData

@export var Leader: Actor = preload("res://database/Party/Mira.tres")
@export var Member1: Actor
@export var Member2: Actor
@export var Member3: Actor

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
	Leader = Global.find_member(p.Leader.FirstName)
	if p.Member1!=null: Member1 = Global.find_member(p.Member1.FirstName)
	else: Member1 = null
	if p.Member2!=null: Member2 = Global.find_member(p.Member2.FirstName)
	else: Member2 = null
	if p.Member3!=null: Member3 = Global.find_member(p.Member3.FirstName)
	else: Member3 = null

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

func array() -> Array[Actor]:
	return [Leader, Member1, Member2, Member3]
