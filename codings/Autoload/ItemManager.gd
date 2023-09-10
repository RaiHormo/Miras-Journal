extends Control
@export var KeyInv : Array[ItemData]
@export var ConInv : Array[ItemData]
@export var MatInv : Array[ItemData]
var item : ItemData
var ind
@onready var panel = $Can/Panel
@onready var t :Tween
@export var HasBag = true
signal pickup

func _ready():
	panel.hide()

func get_animation(icon, named):
	Global.item_sound()
	pickup.emit()
	$Can/Panel/Con/Label.text = named
	$Can/Panel/Icon.texture = icon
	await get_tree().create_timer(0.1).timeout
	t = create_tween() 
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(panel, "position", Vector2(555,250), 0.5).from(Vector2(555,300))
	t.tween_property(panel, "modulate", Color(1,1,1,1), 0.5).from(Color(0,0,0,0))
	panel.show()
	$Can/Panel.size.x = $Can/Panel/Con.size.x + 30
	await get_tree().create_timer(1).timeout
	t = create_tween() 
	t.set_parallel()
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(panel, "position", Vector2(555,200), 0.5)
	t.tween_property(panel, "modulate", Color(0,0,0,0), 0.5)
	await t.finished
	panel.hide()
	Global.check_party.emit()

func add_key_item(ItemName: String):
	item = load("res://database/Items/KeyItems/"+ ItemName + ".tres")
	if item == null:
		OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	if item.Quantity == 0:
		KeyInv.push_front(item)
	item.Quantity += 1
	get_animation(item.Icon, item.Name)

func remove_key_item(ItemName: String):
	item = load("res://database/Items/KeyItems/"+ ItemName + ".tres")
	if item == null:
		OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	if item.Quantity == 1:
		KeyInv.erase(item)
	item.Quantity -= 1

func check_key(ItemName):
	item = load("res://database/Items/KeyItems/"+ ItemName + ".tres")
	if item in KeyInv: return true
	else: return false
	
func add_consumable(ItemName: String):
	item = load("res://database/Items/Consumables/"+ ItemName + ".tres")
	if item == null:
		OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	if item.Quantity == 0:
		ConInv.push_front(item)
	item.Quantity += 1
	get_animation(item.Icon, item.Name)

func remove_consumable(ItemName: String):
	item = load("res://database/Items/Consumables/"+ ItemName + ".tres")
	if item == null:
		OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	if item.Quantity == 1:
		ConInv.erase(item)
	item.Quantity -= 1

func check_consumable(ItemName):
	item = load("res://database/Items/Consumables/"+ ItemName + ".tres")
	if item in ConInv: return true
	else: return false

func add_material(ItemName: String):
	item = load("res://database/Items/Materials/"+ ItemName + ".tres")
	if item == null:
		OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	if item.Quantity == 0:
		MatInv.push_front(item)
	item.Quantity += 1
	get_animation(item.Icon, item.Name)

func remove_material(ItemName: String):
	item = load("res://database/Items/Materials/"+ ItemName + ".tres")
	if item == null:
		OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	if item.Quantity == 1:
		MatInv.erase(item)
	item.Quantity -= 1

func check_material(ItemName):
	item = load("res://database/Items/Materials/"+ ItemName + ".tres")
	if item in MatInv: return true
	else: return false

func use(iteme:ItemData):
	$ItemEffect.use(iteme)
