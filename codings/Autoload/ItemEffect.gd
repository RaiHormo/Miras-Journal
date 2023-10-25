extends Node
var item:ItemData

func use(item_data: ItemData):
	item = item_data
	if item.Use == ItemData.U.CUSTOM:
		call(item.filename)
	elif item.Use == ItemData.U.HEALING:
		get_target()

func get_target():
	if not Loader.InBattle:
		PartyUI.choose_member()


func _on_item_manager_return_member(mem:Actor):
	if item.Use == ItemData.U.HEALING:
		mem.add_health(float(item.Parameter))
	#PartyUI._on_shrink()
	PartyUI._check_party()
	Item.remove_item(item, "Con")
