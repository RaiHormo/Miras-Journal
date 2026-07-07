extends Resource
class_name BoxProfile

@export var Bord1: Color = Color(0xe4e4e4ff)
@export var Bord2: Color = Color(0x959595ff)
@export var Bord3: Color = Color(0x4e4e4eff)
@export var Inner: Color = Color(0x2b2b2bff)
@export var TextColor: Color = Color.WHITE
@export var TextSound: AudioStream = preload("res://sound/SFX/thonk.ogg")
@export var AudioFrequency: int = 4
@export var PitchVariance: float = 1.0

static func match_profile(named: String) -> BoxProfile:
	if not ResourceLoader.exists("res://database/Text/Profiles/" + named + "Box.tres"):
		return await Loader.load_res("uid://kc23d8ih5v7u") as BoxProfile
	else:
		return await Loader.load_res("res://database/Text/Profiles/" + named + "Box.tres") as BoxProfile
