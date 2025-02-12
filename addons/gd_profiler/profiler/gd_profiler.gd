@tool
extends Panel
class_name GodotProfiler
## A Simple, yet Effective Godot Profiler.

var profiler:Panel;
var line:Line2D;
var fps:Label;

@export_category("GDProfiler - In Editor")
@export var profiler_in_editor = false;
@export_category("GDProfiler - Preferences")
@export var tick_rate = 2;
@export var highest:int = 30;


@export_category("GDProfiler - Buttons")
@export var clear_graph:bool = false;
@export var reset_highest:bool = false;

var points:PackedInt32Array;
var frame:int;
# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Created new GD Profiler")
	clip_contents = true;
	
	## Create Children ##
	
	profiler = Panel.new()
	profiler.clip_contents= true;
	
	fps = Label.new()
	fps.text = "FPS: ??"
	fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	fps.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	line = Line2D.new()
	line.default_color = Color("#11AA11")
	
	#####################
	
	## Add Children ##
	
	add_child(profiler)
	add_child(fps)
	profiler.add_child(line)
	
	##################
	
func _process(delta):
	minsize()
	
	# Position Children #
	profiler.size = size-Vector2(0,50)
	profiler.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	profiler.position = Vector2(0,50)
	
	fps.size = Vector2(size.x-10, 40)
	fps.set_anchors_preset(Control.PRESET_TOP_LEFT)
	fps.position = Vector2(5,5)
	
	if clear_graph:
		line.clear_points()
		points.clear()
		#print("Cleared Graph.")
		clear_graph = false
	
	if reset_highest:
		highest = 30
		#print("Reset Highest")
		reset_highest = false
	####################
	
	
	## Actual Script ##
	if Engine.is_editor_hint() && !profiler_in_editor:
		return 0
	if frame < tick_rate:
		frame += 1
		return
	frame=0
	var fs:int = Engine.get_frames_per_second()
	fps.text = "FPS: "+ str(fs)
	
	if fs > highest:
		#print("NEw hIGHEST")
		highest = fs
	
	points.append(fs)
	while(len(points)>size.x/10+3):
		points.remove_at(0)
		
	#Draw Points
	line.clear_points()
	var i:int = 0
	for point in points:
		#print_rich("[b]Point:[/b]" + str(point) + " [color=red]Calculated: " + str(float(point)/float(highest)) + " [/color][color=green]Highest: "+str(highest)+"[/color]")
		line.add_point(Vector2(
			i*10,
			calc_point(point)+(line.width/2)
		))
		i+=1
	#################
		
func calc_point(point):
	return profiler.size.y-(
		(float(point) / float(highest))
		*profiler.size.y
	)

func minsize():
	if size.x < 200:
		size.x = 200
	if size.y < 250:
		size.y = 250
