extends Resource
class_name Ability

## Ability type
enum TP {
	Unset = 0,
	CheapAttack = 1,
	BigAttack = 2,
	Defensive = 3,
	Curse = 4,
	Healing = 5,
	Summon = 6,
	Aggro = 7,
	AtkBuff = 8,
	MagBuff = 9,
	DefBuff = 10,
	AtkNerf = 11,
	MagNerf = 12,
	DefNerf = 13,
	SpeedChange = 14,
	FollowUp = 15,
	ColorChange = 16,
	StateRecovery = 17,
}

## Damage type
enum D { NONE = 0, WEAK = 1, MEDIUM = 2, HEAVY = 3, SEVERE = 4, CUSTOM = 5, WEAPON = 6 }

##0: Target range
enum T { SELF = 0, ONE_ENEMY = 1, AOE_ENEMIES = 2, ONE_ALLY = 3, AOE_ALLIES = 4, ANY = 5 }

@export var name: String
@export_multiline var description: String
@export var Icon: Texture = preload("res://art/Icons/Items.tres")
@export var ActionSequence: StringName = &"Default"
@export var Types: Array[TP] = [TP.Unset]
@export var Group: String = ""
@export var InflictsState: String = ""
@export var AuraCost: int
@export var HPCost: int
@export var disabled: = false
@export var Damage: D = D.NONE
@export var Parameter: float = 0
@export var Target: T = T.SELF
@export var CanTargetDead: = false
@export var AOE_Stagger: float = 0
@export var AOE_AdditionalSeq: = true

@export var ColorSameAsActor: = false
@export_color_no_alpha var WheelColor: Color = Color(1, 1, 1, 1)
@export var Callout: bool = true

@export_range(0, 1) var SucessChance: float = 1
@export_range(0, 1) var CritChance: float = 0

@export var RecoverAura: bool = false
@export var DmgVarience: bool = false

var filename: String = "":
	get():
		if filename == "":
			filename = resource_path.replace(".tres", "").replace("res://database/Abilities/", "").replace("Attacks/", "")
		return filename
var remove_item_on_use: ItemData = null


func is_aoe() -> bool:
	if Target == T.AOE_ALLIES or Target == T.AOE_ENEMIES: return true
	else: return false


static func nothing() -> Ability:
	return ResourceLoader.load("res://database/Abilities/Nothing.tres")
