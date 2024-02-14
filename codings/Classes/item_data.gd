extends Resource

class_name ItemData


@export var Name : String = "Item Name"
@export_multiline var Description : String = "One that does not exit"
@export var Icon: AtlasTexture
@export var Artwork: Texture
@export var Quantity: int = 0
@export var QuantityMeansUses := false
@export var AmountOnAdd := 1
enum U {NONE, INSPECT, CUSTOM, HEALING, SPELL, STATE_HEAL, BUFF_ATK, DEBUFF_ATK}
@export_group("Uses")
@export var Use: U
@export var UsedInBattle = false
enum T {SELF, ONE_ENEMY, AOE_ENEMIES, ONE_ALLY, AOE_ALLIES}
@export var OvTarget: T = T.ONE_ALLY
@export var BattleEffect: Ability
@export var Parameter: String
var filename: String = "Invalid filename"

