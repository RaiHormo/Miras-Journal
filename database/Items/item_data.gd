extends Resource

class_name ItemData


@export var Name : String = "Item Name"
@export_multiline var Description : String = "One that does not exit"
@export var Icon: AtlasTexture
@export var Artwork: Texture
enum U {NONE, INSPECT, CUSTOM, HEALING, SPELL, STATE_HEAL, BUFF_ATK, DEBUFF_ATK}
@export var Use: U
@export var UsedInBattle = false
enum T {SELF, ONE_ENEMY, AOE_ENEMIES, ONE_ALLY, AOE_ALLIES}
@export var Target: T = T.ONE_ALLY
@export var Parameter: String
@export var Quantity: int =0
var filename: String = "Invalid filename"

