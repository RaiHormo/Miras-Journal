extends Resource
class_name State

@export var name: String
@export_multiline var Description: String
@export var RemovedOnBattleEnd:= true
## If not -1, the state will be removed after the specified turns
@export var turns: int = -1
@export var icon: Texture
@export var color: Color
@export var weak_mult:= 1.0
@export var dmg_mult:= 1.0
var inflicter: Actor = null

@export var is_stat_change:= false
