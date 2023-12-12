extends TextureRect
@export var HideOnDays: Array[int]

func _ready() -> void:
	Global.check_party.connect(_check_party)

func _check_party():
	if Event.Day not in HideOnDays:
		show()
		$Date/Day.text = str(Event.Day)
		$Date/Month.text = Global.get_mmm(Global.get_month(Event.Day))
	else:
		hide()
