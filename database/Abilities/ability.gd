extends Resource
class_name Ability

@export var name : String
@export_multiline var description : String
@export var Icon: Texture
@export var ActionSequence : StringName = &""
@export_enum("Cheap Attack", "Big Attack", "Defensive", "Stat change", "Healing", "Curse") var Type = 0
@export var AuraCost: int
@export var HPCost: int
## 0: None, 1: Light, 2: Medium, 3: Heavy, 4: Severe
@export_enum("None", "Light", "Medium", "Heavy", "Severe") var Damage = 0
##0: Self, 1: One enemy, 2: AOE enemies, 3: One ally, 4 AOE allies
@export_enum("Self", "One enemy", "AOE enemies", "One Ally", "AOE allies") var Target = 0

@export var WheelColor :Color  
@export var Callout: bool

@export_range(0,1) var SucessChance: float = 1
@export_range(0,1) var CritChance: float = 0
