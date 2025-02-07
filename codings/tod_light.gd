extends Light2D
class_name TODLight

const defsun = Color(0.6, 0.8, 0.8)
const defmoon = Color(0.9, 0.8, 0.5)

##0: Morning, 1: Daytime, 2: Afternoon, 3: Evening, 4: Night
@export var Colors: Array[Color] = [
	defsun, defsun, defsun, defmoon, defmoon
]
@export var Energy: Array[float] = [
	0.5, 0, 0.2, 0.8, 1
	]

func _ready() -> void:
	Global.check_party.connect(update)

func update():
	energy = Energy[Event.TimeOfDay-1]
	color = Colors[Event.TimeOfDay-1]
