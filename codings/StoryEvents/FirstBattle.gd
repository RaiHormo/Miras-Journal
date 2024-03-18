extends "res://codings/transfer_zone.gd"

func _on_entered(body):
	if body == Global.Player and Global.Controllable:
		if not Event.f("FirstBattle", 1):
			Event.flag_progress("FirstBattle", 1)
			Loader.gray_out(1)
			proceed()
		else:
			proceed()

func _ready() -> void:
	if not Event.f("FirstBattle", 2) and Event.f("FirstBattle1"):
		Loader.start_battle("FirstBattle")
		Event.f("DisableMenus", false)
		PartyUI.disabled = false
