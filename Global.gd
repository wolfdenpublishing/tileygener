extends Node

# Convenience variables for accessing UI elements. We simply search for the
# needed nodes at runtime and store their references, allowing the UI tree
# to be freely manipulated, controls can be moved around whever,  but no code
# changes are ever required (assuming all the ui elements we need to access
# have unique names and we don't change them).

var tiley # root node; will be set by Tiley.gd _init()
var controls = {} # nodes of ui controls that we need to access


func _init():
	OS.window_maximized = true
	randomize()


func _ready():
	# the list of controls we want direct access to
	var global_controls = [
		"GenerOption", 
		"GenerInspector", 
		"GenerDescription", 
		"GridSize", 
		"TileySize", 
		"TileyScale", 
		"Colors", 
		"Background", 
		"PaletteOption",
		"SaveDialog",
	]
	# go find 'em all!
	for control in global_controls:
		controls[control] = tiley.find_node("*" + control)
