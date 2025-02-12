@tool
extends Panel
class_name MovableProfiler
##A Simple, yet Effective and Movable Godot Profiler.
@export_category("GDProfiler - In Editor")
@export var profiler_in_editor = false;
@export_category("GDProfiler - Preferences")
@export var tick_rate = 2;
@export var highest:int = 30;


@export_category("GDProfiler - Buttons")
@export var clear_graph:bool = false;
@export var reset_highest:bool = false;

@export_category("MovableProfiler - Buttons")
@export var ui_toggle:bool = false;

@export_category("MovableProfiler - Preferences")
@export var y_size = 250;

var profiler:GodotProfiler;
var name_label:Label;
var toggle:TextureButton;

const MAXIMIZE = preload("res://addons/gd_profiler/textures/Maximize.png")
const MINIMIZE = preload("res://addons/gd_profiler/textures/Minimize.png")
# Called when the node enters the scene tree for the first time.
func _ready():
	name_label = Label.new();
	name_label.size = Vector2(200,50);
	profiler = GodotProfiler.new();
	name_label.text = "GDProfiler"
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER;
	
	toggle = TextureButton.new();
	toggle.texture_normal = MINIMIZE;
	toggle.ignore_texture_size = true;
	toggle.stretch_mode =TextureButton.STRETCH_SCALE;
	add_child(profiler);
	add_child(name_label);
	add_child(toggle);
	toggle.pressed.connect(toggle_ui)
	gui_input.connect(inputted)

func inputted(event):
	if Engine.is_editor_hint():
		return 0
	
	if !(event is InputEventMouseMotion):
		return
	
	position += event.relative
	
func toggle_ui():
	profiler.visible = !profiler.visible
	if profiler.visible:
		toggle.texture_normal = MINIMIZE;
	else:
		toggle.texture_normal = MAXIMIZE;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	min_size()
	profiler.size = Vector2(size.x,y_size)
	profiler.position = Vector2(0,50);
	name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	name_label.position=Vector2(0,0);
	toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toggle.size = Vector2(50,50)
	toggle.position = Vector2(size.x-50,0)
	
	if ui_toggle:
		toggle_ui()
		ui_toggle = false
		
	if reset_highest:
		profiler.reset_highest = true
		profiler.highest = 30
		highest = 30
		reset_highest = false
	
	if clear_graph:
		profiler.clear_graph = true
		clear_graph = false
	
	#Set Profiler Settings
	profiler.profiler_in_editor = profiler_in_editor
	profiler.tick_rate = tick_rate
	if profiler.highest > highest:
		highest = profiler.highest
	else:
		profiler.highest = highest


func min_size():
	if size.x<200:
		size.x = 200;
	if size.y!=50:
		size.y = 50
	if y_size < 250:
		y_size = 250
