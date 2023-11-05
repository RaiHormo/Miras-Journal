extends CanvasLayer
@onready var Troop:Array[Actor] = get_parent().Troop
@onready var CurEnemy: Actor
var t = Tween
var lock = false

func _ready():
	t = create_tween()
	t.tween_property($EnemyFocus, "position", $EnemyFocus.position, 0)

func all_enemy_ui():
	Troop = get_parent().Troop
	t.kill()
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
#	for i in Troop:
#		print(i.FirstName)
	$EnemyFocus.hide()
	if Troop.size() != 0:
		$Enemy0.show()
		make_box(Troop[0], $Enemy0)
		t.tween_property($Enemy0, "position", Vector2(1055, 25), 0.2)
	if Troop.size() >1:
		if not has_node("Enemy1"):
			var dub = get_child(0).duplicate()
			dub.name = "Enemy1"
			add_child(dub)
			dub.position.y = 190
			make_box(Troop[1], dub)
		$Enemy1.show()
		t.tween_property($Enemy1, "position", Vector2(1055, 190), 0.3)
	if Troop.size() >2:
		if not has_node("Enemy2"):
			var dub = get_child(0).duplicate()
			dub.name = "Enemy2"
			add_child(dub)
			dub.position.y = 355
			make_box(Troop[2], dub)
		$Enemy2.show()
		t.tween_property($Enemy2, "position", Vector2(1055, 355), 0.4)
	if Troop.size() != 0:
		CurEnemy= Troop[0]
		make_box(Troop[0], $Enemy0)
		make_box(Troop[0], $EnemyFocus)
		_check_party()



func _on_battle_ui_target_foc(cur):
	CurEnemy=cur
	for i in get_children().size():
		get_child(i).hide()
	make_box(cur, $EnemyFocus)
	$EnemyFocus.show()
	$EnemyFocus/Name.text = cur.FirstName
	if not lock:
		$EnemyFocus/Health.value = cur.Health
		$EnemyFocus/Health.max_value = cur.MaxHP
	$EnemyFocus/Icon.texture = cur.PartyIcon
	$EnemyFocus/Health/HpText.add_theme_color_override("font_outline_color", CurEnemy.MainColor)
	$EnemyFocus/Health/HpText.text = str(CurEnemy.Health)

func _check_party():
	PartyUI._check_party()
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	if Troop.size() >= 0:
		$Enemy0/Name.text = Troop[0].FirstName
		t.tween_property($Enemy0/Health, "value",Troop[0].Health, 0.3)
	$Enemy0/Health.max_value = Troop[0].MaxHP
	if Troop.size() >= 2:
		$Enemy1/Name.text = Troop[1].FirstName
		t.tween_property($Enemy1/Health, "value",Troop[1].Health, 0.3)
		$Enemy1/Health.max_value = Troop[1].MaxHP
	if Troop.size() >= 3:
		$Enemy2/Name.text = Troop[2].FirstName
		t.tween_property($Enemy2/Health, "value",Troop[2].Health, 0.3)
		$Enemy2/Health.max_value = Troop[2].MaxHP
	$EnemyFocus/Name.text = CurEnemy.FirstName
	$EnemyFocus/Health.max_value = CurEnemy.MaxHP
	$EnemyFocus/Health/HpText.text = str(CurEnemy.Health)
	if CurEnemy!=get_parent().CurrentChar and lock == false:
		lock = true
		t.tween_property($EnemyFocus/Health, "value",CurEnemy.Health, 0.3)
		await t.finished
		lock = false
	else:
		$EnemyFocus/Health.value = CurEnemy.Health
	$EnemyFocus/Icon.texture = CurEnemy.PartyIcon
	if Troop.size() != 0:
		make_box(Troop[0], $Enemy0)

func _on_battle_ui_ability():
	colapse_root()
	$EnemyFocus.hide()

func colapse_root():
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	t.tween_property($Enemy0, "position", Vector2(300, 0), 0.5).as_relative()
	if Troop.size()>1:
		t.tween_property($Enemy1, "position", Vector2(300, 0), 0.4).as_relative()
		if Troop.size()>2:
			t.tween_property($Enemy2, "position", Vector2(300, 0), 0.3).as_relative()

#func _process(delta):
#	if get_parent().Action:
#		_check_party()
#	pass

func make_box(en:Actor, node:Panel):
	var hbox = node.get_node("Health").get_theme_stylebox("fill")
	hbox.bg_color = en.MainColor
	node.get_node("Health").add_theme_stylebox_override("fill", hbox.duplicate())
	var bord1:StyleBoxFlat = node.get_node("Border1").get_theme_stylebox("panel")
	bord1.border_color = en.MainColor
	node.get_node("Border1").add_theme_stylebox_override("panel", bord1.duplicate())
	var bord2:StyleBoxFlat = node.get_node("Border1/Border2").get_theme_stylebox("panel")
	bord2.border_color = Color.from_hsv(en.MainColor.h, en.MainColor.s - 0.2, max(0.3, en.MainColor.v - 0.5), 1)
	node.get_node("Border1/Border2").add_theme_stylebox_override("panel", bord2.duplicate())
	var bord3:StyleBoxFlat = node.get_node("Border1/Border2/Border3").get_theme_stylebox("panel")
	bord3.border_color = Color.from_hsv(en.MainColor.h, en.MainColor.s - 0.3, max(0.2 ,en.MainColor.v - 0.7), 1)
	node.get_node("Border1/Border2/Border3").add_theme_stylebox_override("panel", bord3.duplicate())
