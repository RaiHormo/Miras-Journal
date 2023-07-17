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
