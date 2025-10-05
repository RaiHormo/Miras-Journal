extends Resource
class_name State

@export var name: String
@export_multiline var Description: String
@export var RemovedOnBattleEnd:= true
@export var parameter:= 0.0
## If not -1, the state will be removed after the specified turns
@export var turns: int = -1
@export var icon: Texture
@export var color: Color = Color.WHITE
@export_enum("None", "Guard", "Hurt") var pose: String = "None"
@export var weak_mult:= 1.0
@export var magic_dmg_mult:= 1.0
@export var weapon_dmg_mult:= 1.0
var inflicter: Actor = null
var QueueRemove:= false
var filename:= ""

@export var is_stat_change:= false
