extends Resource

class_name ItemData

@export var Name: String = " - None - "
@export_storage var filename: String = "Invalid filename":
	get():
		if not resource_path.is_empty():
			filename = resource_path.get_file().replace(".tres", "")

		return filename
@export_multiline var Description: String = "One that does not exit"
@export_enum("Key", "Con", "Mat", "Bti") var ItemType: String = ""
@export var Icon: Texture = load("res://art/Icons/Items.tres")
@export var QuantityMeansUses := false
@export var AmountOnAdd := 1
enum U {NONE, INSPECT, CUSTOM, HEALING, SPELL, STATE_HEAL, BUFF_ATK, DEBUFF_ATK}
@export_group("Uses")
@export var Use: U
@export var UsedInBattle := false
enum T {SELF, ONE_ENEMY, AOE_ENEMIES, ONE_ALLY, AOE_ALLIES}
@export var OvTarget: T = T.ONE_ALLY
@export var BattleEffect: Ability
@export var Parameter: String


func get_artwork() -> Texture:
	var path := "res://art/Items/"+filename+".png"

	if ResourceLoader.exists(path):
		return await Loader.load_res(path)
	else:
		return null
