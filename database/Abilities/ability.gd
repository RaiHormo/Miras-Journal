extends Resource
class_name Ability

@export var name : String
@export_multiline var description : String
@export var Icon: Texture
@export var ActionSequence : StringName = &""
enum TP {CHEAP_ATTACK, BIG_ATTACK, DEFENSIVE, STAT_CHANGE, HEALING, CURSE} 
@export var Type:TP = TP.CHEAP_ATTACK
@export var AuraCost: int
@export var HPCost: int
## 0: None, 1: Light, 2: Medium, 3: Heavy, 4: Severe
enum D {NONE, LIGHT, MEDIUM, HEAVY, SEVERE}
@export var Damage:D = D.NONE
##0: Self, 1: One enemy, 2: AOE enemies, 3: One ally, 4 AOE allies
enum T {SELF, ONE_ENEMY, AOE_ENEMIES, ONE_ALLY, AOE_ALLIES}
@export var Target: T = T.SELF

@export var WheelColor :Color  
@export var Callout: bool

@export_range(0,1) var SucessChance: float = 1
@export_range(0,1) var CritChance: float = 0
