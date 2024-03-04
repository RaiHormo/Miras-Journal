extends Resource
class_name  BattleEvent

@export_group("Condition")
@export var repeatable:= false
##Check this flag
@export var flag: StringName = &""
@export var flag_should_be: bool = false
##If all other conditions are met, the event will play on this turn or after it, -1 to disable
@export var after_turn: int = -1
##The event will play if the actor's HP is lower than [member low_hp]. Leave empty to skip
@export var actor: StringName = &""
##To be used with [member actor_hp_low]
@export var low_hp: int = -1
@export_group("Result")
@export_enum("Passive dialog", "Call function", "Regular dialog", "Force move") var result = 0
##Used as text file for dialog, function name for call function, move type for force move
@export var parameter1: String = ""
##Used as node name for dialog
@export var parameter2: String = ""
@export var resource: Resource = null
##Continue to the next turn only after the event is done
@export var hold_turn := false
##set [member flag] to the oposite of [member flag_should_be] after running
@export var add_flag: bool = true
var ran_this_turn := false


func check() -> bool:
	if ran_this_turn: return false
	if Global.Bt == null: return false
	if Event.check_flag(flag) != flag_should_be: return false
	if after_turn != -1:
		if Global.Bt.Turn < after_turn: return false
	if low_hp != -1 and actor != &"":
		if Global.Bt.get_actor(actor).Health > low_hp: return false
	return true

func run() -> void:
	if ran_this_turn: return
	else: ran_this_turn = true
	if Global.Bt == null: return
	print("Running event ", resource_name)
	if hold_turn: await run_with_await()
	else:
		match result:
			0: Global.passive(parameter1, parameter2)
			1: Global.Bt.get_node("Act").call(parameter1)
			2: Global.textbox(parameter1, parameter2)
			3:
				Global.Bt.get_actor(actor).NextAction = parameter1
				Global.Bt.get_actor(actor).NextMove = resource
	if add_flag: Event.f(flag, !flag_should_be)

func run_with_await() -> void:
	match result:
		0: await Global.passive(parameter1, parameter2)
		1: await Global.Bt.get_node("Act").call(parameter1)
		2: await Global.textbox(parameter1, parameter2)
		_: OS.alert("Battle event error: This action cannot hold the turn")
