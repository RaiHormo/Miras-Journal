extends Resource
class_name Ability

@export var name : String
@export_multiline var description : String
@export var Icon: Texture = preload("res://art/Icons/Items.tres")
@export var ActionSequence : StringName = &""
@export_enum("CheapAttack", "BigAttack", "Defensive", "Curse", "Healing", "AtkBuff", "MagBuff", "DefBuff", "Summon") var Type: String = "CheapAttack"
@export var Group: String = ""
@export var InflictsState: String = ""
@export var AuraCost: int
@export var HPCost: int
@export var disabled:= false
## 0: None, 1: Weak, 2: Medium, 3: Heavy, 4: Severe
enum D {NONE, WEAK, MEDIUM, HEAVY, SEVERE, CUSTOM, WEAPON}
@export var Damage:D = D.NONE
@export var Parameter: float = 0
##0: Self, 1: One enemy, 2: AOE enemies, 3: One ally, 4 AOE allies
enum T {SELF, ONE_ENEMY, AOE_ENEMIES, ONE_ALLY, AOE_ALLIES, ANY}
@export var Target: T = T.SELF
@export var CanTargetDead:= false
@export var AOE_Stagger: float = 0
@export var AOE_AdditionalSeq:= true

@export var ColorSameAsActor := false
@export_color_no_alpha var WheelColor :Color  = Color(1,1,1,1)
@export var Callout: bool = true

@export_range(0,1) var SucessChance: float = 1
@export_range(0,1) var CritChance: float = 0

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
	return preload("res://database/Abilities/Attacks/Nothing.tres")
