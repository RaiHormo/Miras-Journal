extends Node2D
@export var color:Color
@export var affinity:Affinity

func _process(delta):
	draw_wheel()

func draw_wheel():
	if color.s != 0:
		affinity = Global.get_affinity(color)
		$Rangenear1.rotation_degrees = affinity.near_range[0]
		$Rangenear2.rotation_degrees = affinity.near_range[-1]
		#print(affinity.oposing_range.size())
		if affinity.oposing_range.size() > 15:
			$Rangeopose1.rotation_degrees = affinity.weak_range[-1]
			$Rangeopose2.show()
			$DoubleWeakIcon.show()
			$DoubleWeakIcon.rotation_degrees = affinity.oposing_hue
			$Rangeopose2.rotation_degrees = affinity.resist_range[0]
			$ResistIcon.rotation_degrees = avrage_dg($Rangeresist.rotation_degrees, $Rangeopose2.rotation_degrees)
		else:
			$Rangeopose2.hide()
			$DoubleWeakIcon.hide()
			$Rangeopose1.rotation_degrees = affinity.oposing_range[-1]
			$ResistIcon.rotation_degrees = avrage_dg($Rangeresist.rotation_degrees, $Rangeopose1.rotation_degrees)
		$Rangeweak.rotation_degrees = affinity.weak_range[0]
		#$Rangeweak2.rotation_degrees = affinity.weak_range[-1]
		#$Rangeresist1.rotation_degrees = affinity.resist_range[0]
		$Rangeresist.rotation_degrees = affinity.resist_range[-1]
		$WeakIcon.rotation_degrees = avrage_dg($Rangeopose1.rotation_degrees, $Rangeweak.rotation_degrees)
		$NearIcon.rotation_degrees = avrage_dg($Rangenear2.rotation_degrees, $Rangenear1.rotation_degrees)
		$NeturalIcon1.rotation_degrees = avrage_dg($Rangeweak.rotation_degrees, $Rangenear2.rotation_degrees)
		$NeturalIcon2.rotation_degrees = avrage_dg($Rangenear1.rotation_degrees, $Rangeresist.rotation_degrees)
		$ColorIndicator.rotation_degrees = affinity.hue
		var IndicatorPanel :StyleBoxFlat = $ColorIndicator.get_theme_stylebox("panel")
		IndicatorPanel.bg_color = affinity.color
	
func avrage_dg(d1, d2):
	if d1<d2: return ((359 + d1) + d2)/2
	else: return (d1 + d2)/2
