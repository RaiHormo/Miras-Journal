extends CanvasLayer
@onready var Troop:Array[Actor] = get_parent().Troop
@onready var CurEnemy: Actor
var t: Tween
var lock = false

func _ready():
	$AllEnemies.hide()
	$EnemyFocus.hide()

func all_enemy_ui():
	Troop = get_parent().Troop
	if Troop.size() < $AllEnemies.get_child_count():
		$AllEnemies.get_child($AllEnemies.get_child_count()-1).free()
		all_enemy_ui()
		return
	$EnemyFocus.hide()
	$AllEnemies.show()
	for enemy in Troop:
		var panel: Panel
		if get_node_or_null("AllEnemies/Enemy" + str(Troop.find(enemy))) != null:
			panel = get_node("AllEnemies/Enemy" + str(Troop.find(enemy)))
		else:
			panel = $AllEnemies/Enemy0.duplicate()
			panel.name = "Enemy" + str(Troop.find(enemy))
			$AllEnemies.add_child(panel)
		make_box(enemy, panel)
		panel.show()
		if panel.position.x != 0:
			t = create_tween()
			t.set_ease(Tween.EASE_OUT)
			t.set_trans(Tween.TRANS_QUART)
			t.tween_property(panel, "position:x", 0, 0.2)
			await Event.wait(0.05)
	if Troop.size() != 0:
		CurEnemy= Troop[0]
		make_box(Troop[0], $AllEnemies/Enemy0)
		make_box(Troop[0], $EnemyFocus)
		_check_party()

func _on_battle_ui_target_foc(cur: Actor):
	CurEnemy = cur
	_check_party()
	$AllEnemies.hide()
	make_box(cur, $EnemyFocus)
	$EnemyFocus.show()
	$EnemyFocus/Name.text = cur.FirstName
	$EnemyFocus/Health.value = cur.Health
	$EnemyFocus/Health.max_value = cur.MaxHP
	$EnemyFocus/Aura.value = cur.Aura
	$EnemyFocus/Aura.max_value = cur.MaxAura
	$EnemyFocus/Icon.texture = cur.PartyIcon
	$EnemyFocus/Health/HpText.add_theme_color_override("font_outline_color", CurEnemy.MainColor)
	$EnemyFocus/Health/HpText.text = str(CurEnemy.Health)

func _check_party():
	PartyUI._check_party()
	Troop = get_parent().Troop
	if t != null: t.stop()
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	for i in Troop:
		check_panel(i, get_node_or_null("AllEnemies/Enemy" + str(Troop.find(i))))
	$EnemyFocus/Name.text = CurEnemy.FirstName
	for i in $EnemyFocus/States.get_children():
		if i.name != "State": i.queue_free()
	for i in CurEnemy.States:
		var dub = $EnemyFocus/States/State.duplicate()
		dub.texture = i.icon
		dub.show()
		dub.tooltip_text = i.name + "\n" + i.Description
		dub.name = i.name
		$EnemyFocus/States.add_child(dub)
	$EnemyFocus/Health.max_value = CurEnemy.MaxHP
	$EnemyFocus/Aura.max_value = CurEnemy.MaxAura
	$EnemyFocus/Health/HpText.text = str(CurEnemy.Health)
	if CurEnemy!=get_parent().CurrentChar and lock == false and get_parent().Action:
		lock = true
		remap($EnemyFocus/Health.value, 0, $EnemyFocus/Health.max_value, 0, CurEnemy.MaxHP)
		remap($EnemyFocus/Aura.value, 0, $EnemyFocus/Aura.max_value, 0, CurEnemy.MaxAura)
		t.tween_property($EnemyFocus/Health, "value", CurEnemy.Health, 0.3)
		if CurEnemy.Health == 0: t.tween_property($EnemyFocus/Aura, "value", 0, 0.3)
		else: t.tween_property($EnemyFocus/Aura, "value", CurEnemy.Aura, 0.3)
		await t.finished
		lock = false
	else:
		$EnemyFocus/Health.value = CurEnemy.Health
		$EnemyFocus/Aura.value = CurEnemy.Aura
	$EnemyFocus/Icon.texture = CurEnemy.PartyIcon
	if Troop.size() != 0:
		make_box(Troop[0], $AllEnemies/Enemy0)

func check_panel(chara: Actor, panel: Panel):
	if panel == null: return
	if chara.FirstName.length() > 16: panel.get_node("Name").add_theme_font_size_override("font_size", 12)
	elif chara.FirstName.length() > 12	: panel.get_node("Name").add_theme_font_size_override("font_size", 14)
	elif chara.FirstName.length() > 6: panel.get_node("Name").add_theme_font_size_override("font_size", 18)
	else: panel.get_node("Name").add_theme_font_size_override("font_size", 20)
	panel.get_node("Name").text = chara.FirstName
	t.tween_property(panel.get_node("Health"), "value", chara.Health, 0.3)
	panel.get_node("Health").max_value = chara.MaxHP
	if panel.get_node_or_null("Aura") != null:
		t.tween_property(panel.get_node("Aura"), "value", chara.Aura, 0.3)
		panel.get_node("Aura").max_value = chara.MaxAura

func _on_battle_ui_ability():
	colapse_root()
	$EnemyFocus.hide()

func colapse_root():
	t = create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	for i in $AllEnemies.get_children():
		t.tween_property(i, "position", Vector2(300, 0), 0.5).as_relative()

#func _process(delta):
#	if get_parent().Action:
#		_check_party()
#	pass

func make_box(en:Actor, node:Panel):
	var hbox = node.get_node("Health").get_theme_stylebox("fill")
	hbox.bg_color = en.MainColor
	node.get_node("Health").add_theme_stylebox_override("fill", hbox.duplicate())
	if node.get_node_or_null("Aura") != null:
		var abox = node.get_node("Aura").get_theme_stylebox("fill")
		if en.SecondaryColor == Color.BLACK:
			en.SecondaryColor = en.MainColor
			en.SecondaryColor.h += 0.83
		abox.bg_color = en.SecondaryColor
		node.get_node("Aura").add_theme_stylebox_override("fill", abox.duplicate())
	var bord1:StyleBoxFlat = node.get_node("Border1").get_theme_stylebox("panel")
	bord1.border_color = en.MainColor
	node.get_node("Border1").add_theme_stylebox_override("panel", bord1.duplicate())
	var bord2:StyleBoxFlat = node.get_node("Border1/Border2").get_theme_stylebox("panel")
	bord2.border_color = Color.from_hsv(en.MainColor.h, en.MainColor.s - 0.2, max(0.3, en.MainColor.v - 0.5), 1)
	node.get_node("Border1/Border2").add_theme_stylebox_override("panel", bord2.duplicate())
	var bord3:StyleBoxFlat = node.get_node("Border1/Border2/Border3").get_theme_stylebox("panel")
	bord3.border_color = Color.from_hsv(en.MainColor.h, en.MainColor.s - 0.3, max(0.2 ,en.MainColor.v - 0.7), 1)
	node.get_node("Border1/Border2/Border3").add_theme_stylebox_override("panel", bord3.duplicate())
