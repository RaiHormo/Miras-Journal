extends Node
var item:ItemData


func use(item_data: ItemData, battle_target: Actor = null):
	item = item_data
	if not Loader.InBattle:
		if item.Use == ItemData.U.CUSTOM:
			call(item.filename)
		elif item.Use == ItemData.U.HEALING:
			PartyUI.choose_member()
	elif item.UsedInBattle:
		if battle_target == null: battle_target = Global.Bt.CurrentChar
		battle_target.NextMove = item.BattleEffect


func _on_item_manager_return_member(mem:Actor):
	if item.Use == ItemData.U.HEALING:
		mem.add_health(float(item.Parameter))
	#PartyUI._on_shrink()
	PartyUI._check_party()
	Item.remove_item(item, "Con")
