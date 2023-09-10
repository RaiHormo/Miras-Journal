extends Node
var item:ItemData

func use(item_data: ItemData):
	item = item_data
	if item.Use == ItemData.U.CUSTOM:
		call(item.ActionName)
	elif item.Use == ItemData.U.HEALING:
		get_target()

func get_target():
	if not Loader.InBattle:
		PartyUI.choose_member()
