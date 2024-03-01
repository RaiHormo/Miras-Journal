extends Resource
class_name Setting

@export_category("Gameplay")
@export var AutoHideHUD: int = 0
@export_category("Input")
@export var ControlSchemeAuto: bool = true
@export var ControlSchemeEnum: int = 0
@export var ControlSchemeOverride:ControlScheme = null
@export_category("Display")
@export var Fullscreen = false
@export var FPS: int = 0
@export var VSync: bool = true
@export_category("Audio")
@export var MasterVolume: float = 0
@export var MusicVolume: float = 0
@export var EnvSFXVolume: float = 0
@export var BtSFXVolume: float = 0
@export var UIVolume: float = 0
@export var VoicesVolume: float = 0
@export_category("System")
@export var DebugMode: bool = false
