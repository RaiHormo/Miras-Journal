extends Resource
class_name PartyData

@export var Leader: Actor
@export var Member1: Actor
@export var Member2: Actor
@export var Member3: Actor

func reset_party():
	Leader = load("res://database/Party/Mira.tres")
	Member1 = null
	Member2 = null
	Member3 = null
	
func check_member(n):
	if n == 1 and Member1 != null:
		return true
	elif n == 2 and Member2 != null:
		return true
	elif n==3 and Member3 != null:
		return true
	else:
		return false

func make_unique():
	Leader = Leader.duplicate()
	if Member1!=null: Member1 = Member1.duplicate()
	if Member2!=null: Member2 = Member2.duplicate()
	if Member3!=null: Member3 = Member1.duplicate()

func set_to(p:PartyData):
	Leader = load("res://database/Party/"+p.Leader.FirstName+".tres")
	if p.Member1!=null: Member1 = load("res://database/Party/"+p.Member1.FirstName+".tres")
	else: Member1 = null
	if p.Member2!=null: Member2 = load("res://database/Party/"+p.Member2.FirstName+".tres")
	else: Member2 = null
	if p.Member3!=null: Member3 = load("res://database/Party/"+p.Member3.FirstName+".tres")
	else: Member3 = null

func get_member(num:int):
	match num:
		0: return Leader
		1: return Member1
		2: return Member2
		3: return Member3
