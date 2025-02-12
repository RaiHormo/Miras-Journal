@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("GodotProfiler", "Panel", preload("res://addons/gd_profiler/profiler/gd_profiler.gd"), preload("res://addons/gd_profiler/textures/Minimize.png"))
	add_custom_type("MovableProfiler", "Panel", preload("res://addons/gd_profiler/profiler/movable_profiler.gd"), preload("res://addons/gd_profiler/textures/Maximize.png"))
	# Initialization of the plugin goes here.
	print_rich("[b]Godot Profiler has Loaded![/b]")


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("GodotProfiler")
	remove_custom_type("MovableProfiler")

	print_rich("[b]Godot Profiler was Stopped.[/b]")
