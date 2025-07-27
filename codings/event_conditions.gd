extends Node

func sl_linde():
	if Event.f("sl_asteria_1") and not Event.f("sl_linde_1"):
		return 1
	return 0

func sl_maple():
	return 0

func sl_asteria():
	if Event.TimeOfDay == Event.TOD.NIGHT and Event.f("EvSwitchCastLines2") and not Event.f("sl_asteria_1"):
		return 1
	return 0
