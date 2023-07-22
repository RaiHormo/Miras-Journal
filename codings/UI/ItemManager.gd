extends Control
@export var KeyInv : Array[SlotData]
var item : ItemData
var ind
@onready var panel = $Can/Panel
@onready var t :Tween
signal pickup

func _ready():
	panel.hide()

func add_key_item(ItemName: String):
	item = load("res://database/Items/KeyItems/"+ ItemName + ".tres")
	if item == null:
		OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	ind = -1
	var Slot = SlotData.new()
	Slot.item_data = item
	Slot.quantity = 1
	for i in KeyInv.size():
		if item == KeyInv[i].item_data:
			ind = i
			continue
	if ind == -1:
		KeyInv.push_front(Slot)
		ind = KeyInv.size() -1
	else:
		KeyInv[ind].quantity += 1
		print("---------")
		print(ind)
		print(KeyInv[ind].quantity)
		print(KeyInv[ind].item_data.Name)
		print(KeyInv.size())
	get_animation(KeyInv[ind].item_data.Icon, KeyInv[ind].item_data.Name)
	
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

func check_key(ItemName):
	item = load("res://database/Items/KeyItems/"+ ItemName + ".tres")
	if item == null:
		OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	ind = -1
	for i in KeyInv.size():
		if item == KeyInv[i].item_data:
			ind = i
			continue
	if ind == -1:
		return false
	else:
		return true
	
