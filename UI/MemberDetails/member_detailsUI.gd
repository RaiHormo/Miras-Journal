extends CanvasLayer

func _ready():
	hide()

func draw_character(chara: Actor):
	$Icon.texture = chara.PartyIcon
	$Name.text = chara.FirstName + " " + chara.LastName
	$StatPanel/LvBox/Vbox/LvBar/Number.text = str(chara.SkillLevel)
	$StatPanel/LvBox/Vbox/LvBar/SPNum.text = str(chara.SkillPoints)
	$StatPanel/LvBox/Vbox/ExpBar.max_value = chara.SkillPointsFor[chara.SkillLevel]
	$StatPanel/LvBox/Vbox/ExpBar.value = chara.SkillPoints
	$StatPanel/LvBox/Vbox/ToNextLv/Number.text = str(chara.SkillPointsFor[chara.SkillLevel] - chara.SkillPoints)
	$StatPanel/HPAura/HPText.text = str(chara.MaxHP)
	$StatPanel/HPAura/APText.text = str(chara.MaxAura)
	$StatPanel/HPAura/Health.max_value = 300
	$StatPanel/HPAura/Aura.max_value = 100
	$StatPanel/HPAura/Health.value = chara.MaxHP
	$StatPanel/HPAura/Aura.value = chara.MaxAura

	$StatPanel/HPAura/HPText.add_theme_color_override("font_color", chara.MainColor)
	$StatPanel/HPAura/APText.add_theme_color_override("font_color", chara.SecondaryColor)
	var hbox:StyleBoxFlat = $StatPanel/HPAura/Health.get_theme_stylebox("fill")
	hbox.bg_color = chara.MainColor
	$StatPanel/HPAura/Health.add_theme_stylebox_override("fill", hbox.duplicate())
	var abox = $StatPanel/HPAura/Aura.get_theme_stylebox("fill")
	abox.bg_color = chara.SecondaryColor
	$StatPanel/HPAura/Aura.add_theme_stylebox_override("fill", abox.duplicate())
	var bord1:StyleBoxFlat = $StatPanel/Border1.get_theme_stylebox("panel")
	bord1.border_color = chara.BoxProfile.Bord1
	$StatPanel/Border1.add_theme_stylebox_override("panel", bord1.duplicate())
	var bord2:StyleBoxFlat = $StatPanel/Border1/Border2.get_theme_stylebox("panel")
	bord2.border_color = chara.BoxProfile.Bord2
	$StatPanel/Border1/Border2.add_theme_stylebox_override("panel", bord2.duplicate())
	var bord3:StyleBoxFlat = $StatPanel/Border1/Border2/Border3.get_theme_stylebox("panel")
	bord3.border_color = chara.BoxProfile.Bord3
	$StatPanel/Border1/Border2/Border3.add_theme_stylebox_override("panel", bord3.duplicate())

	#$StatPanel/LvBox/Vbox/ExpBar.add_theme_stylebox_override("fill", hbox.duplicate())
	#var xbox = hbox.duplicate()
	#xbox.bg_color = chara.BoxProfile.Bord3
	#$StatPanel/LvBox/Vbox/ExpBar.add_theme_stylebox_override("background", xbox)

	$Line1.color = chara.BoxProfile.Bord1
	$Line1/Line2.color = chara.BoxProfile.Bord2
	$Line1/Line2/Line3.color = chara.BoxProfile.Bord3

	$StatPanel/StatBars/Attack.value = chara.Attack
	$StatPanel/StatBars/Defence.value = chara.Defence
	$StatPanel/StatBars/Magic.value = chara.Magic
	$StatPanel/Weapon/WeaponName.text = chara.Weapon
	$StatPanel/Weapon/Icon.texture = chara.StandardAttack.Icon

	$StatPanel/Wheel.color = chara.MainColor
	$StatPanel/Wheel.draw_wheel()
	$Render.texture = chara.RenderArtwork

	for i in $Line1/NameChain.get_children():
		i.text = chara.FirstName.to_upper() + " " + chara.LastName.to_upper() + " "
		#i.add_theme_color_override("font_color", chara.BoxProfile.Bord3)
	await Event.wait(0.1, false)
	var anim: Animation = $AnimationPlayer.get_animation("scrollname")
	anim.track_set_key_value(0, 1, Vector2(-$Line1/NameChain/Name3.size.x, 130))
	$StatPanel/Wheel.draw_wheel()
	show()

func _on_back_pressed():
	queue_free()
