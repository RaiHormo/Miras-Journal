extends Resource
class_name State

@export var name: String
@export_multiline var Description: String
@export var RemovedAfterTurns: bool
@export var RemovedOnBattleEnd:= true
@export var turns: int
@export var icon: Texture
@export var color: Color

@export var is_stat_change:= false
