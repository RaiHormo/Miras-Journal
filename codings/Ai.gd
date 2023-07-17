extends Node
@onready var Bt :Battle = get_parent()

func ai():
	if Bt.CurrentChar.NextAction == "":
		#if Bt.CurrentChar.Abilities.size() == 0:
			Bt._on_battle_ui_ability_returned(Bt.CurrentChar.StandardAttack, random_target())
				

func random_target():
	if Bt.CurrentChar.IsEnemy:
		return Bt.PartyArray[randi_range(0, Global.number_of_party_members() -1)]
	else:
		return Bt.Troop[randi_range(0, Bt.Troop.size() -1)]
