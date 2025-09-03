extends Node

func sl_linde():
	if Event.f("sl_asteria_1") and not Event.f("sl_linde_1"):
		return 1
	return 0

func sl_maple():
	return 0

func sl_asteria_outside_house():
	#if Event.TimeOfDay == Event.TOD.NIGHT and Event.Day >= 3 and not Event.f("sl_asteria_1"):
		#return 1
	return 0

func sl_asteria():
	if Event.TimeOfDay == Event.TOD.NIGHT and Event.Day >= 3 and not Event.f("sl_asteria_1"):
		return 1
	return 0
