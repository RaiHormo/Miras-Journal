extends Control
@export var KeyInv : Array[ItemData]
@export var ConInv : Array[ItemData]
@export var MatInv : Array[ItemData]
@export var BtiInv : Array[ItemData]
var item : ItemData
var ind
@onready var panel = $Can/Panel
@onready var t :Tween
@export var HasBag = true
signal pickup
signal return_member(mem: Actor)
@onready var Dicon: TextureRect = $Can/Panel/HBoxContainer/Icon
@onready var label: Label = $Can/Panel/HBoxContainer/Label

func _ready():
	panel.hide()

func get_animation(icon, named, pickup_anim:= true):
	Global.item_sound()
	if pickup_anim: pickup.emit()
	label.text = named
	Dicon.texture = icon
	await get_tree().create_timer(0.1).timeout
	t = create_tween()
	t.set_parallel()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUART)
	t.tween_property(panel, "position", Vector2(555,250), 0.5).from(Vector2(555,300))
	t.tween_property(panel, "modulate", Color(1,1,1,1), 0.5).from(Color(0,0,0,0))
	panel.show()
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

func add_item(ItemName, type: StringName, animate=true):
	item = get_item(ItemName, type).duplicate()
	if item == null:
		OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	var inv: Array[ItemData] = get_inv(type)
	if not check_item(ItemName, type):
		item.Quantity = 1
		inv.append(item)
	else: for i in inv:
		if i.filename == item.filename:
			i.Quantity += 1
	overwrite_inv(inv, type)
	if animate: get_animation(item.Icon, item.Name)

func remove_item(ItemName, type):
	item = get_item(ItemName, type)
	if item == null:
		OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	var inv: Array[ItemData] = get_inv(type)
	if item.Quantity == 1:
		inv.erase(item)
	item.Quantity -= 1
	overwrite_inv(inv, type)

func check_item(ItemName, type):
	item = get_item(ItemName, type)
	if item == null: OS.alert("THERE'S NO ITEM CALLED " + ItemName, "OOPS")
	if item in get_inv(type): return true
	else: return false

func get_inv(type: String):
	match type:
		&"Key": return KeyInv
		&"Con": return ConInv
		&"Mat": return MatInv
		&"Bti": return BtiInv

func overwrite_inv(inv: Array, type: StringName):
	match type:
		&"Key": KeyInv = inv
		&"Con": ConInv = inv
		&"Mat": MatInv = inv
		&"Bti": BtiInv = inv

func get_folder(type: StringName):
	match type:
		&"Key": return "KeyItems"
		&"Con": return "Consumables"
		&"Mat": return "Materials"
		&"Bti": return "BattleItems"

func use(iteme:ItemData):
	item = iteme
	$ItemEffect.use(iteme)

func get_item(iteme, type:StringName):
	var ritem = null
	if iteme is String:
		for i in get_inv(type):
			if iteme == i.filename:
				ritem = i
		if ritem == null:
			ritem = load("res://database/Items/" + get_folder(type) + "/"+ iteme + ".tres")
			ritem.filename = iteme
	elif iteme is ItemData:
		if iteme.filename == "Invalid filename":
			OS.alert(iteme.filename)
		for i in get_inv(type):
			if iteme.filename == i.filename:
				ritem = i
		if ritem == null:
			ritem = load("res://database/Items/" + get_folder(type) + "/"+ iteme.filename + ".tres")
			ritem.filename = iteme.filename
	else: OS.alert("That's not a valid item name")
	return ritem

func find_filename(iteme: ItemData, type):
	for file in DirAccess.get_files_at("res://database/Items/" + get_folder(type)):
		if ".tres" in file:
			var ritem:ItemData = await Loader.load_res("res://database/Items/"+get_folder(type)+"/"+ file)
			if ritem.Name == iteme.Name: iteme.filename = file.erase(file.length()-5, 5)

func verify_inventory():
	for i in KeyInv:
		if i.filename == "Invalid filename": await find_filename(i, &"Key")
	for i in ConInv:
		if i.filename == "Invalid filename": await find_filename(i, &"Con")
	for i in MatInv:
		if i.filename == "Invalid filename": await find_filename(i, &"Mat")
	for i in BtiInv:
		if i.filename == "Invalid filename": await find_filename(i, &"Bti")
