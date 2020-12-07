extends Node

# The pallete control generator will look for exported arrays of Color objects.

# Default pallete from  http://alumni.media.mit.edu/~wad/color/palette.html
# warning-ignore:unused_class_variable
export(Array, Color) var Default:Array = [
	Color.black, Color.darkgray, Color.blue, Color.red,
	Color.green, Color.brown, Color.purple, Color.lightgray,
	Color.lightgreen, Color.lightblue, Color.cyan, Color.orange,
	Color.yellow, Color.tan, Color.pink, Color.white
]

# Simple
# warning-ignore:unused_class_variable
export(Array, Color) var Simple = [
	Color.black, Color.red, Color.green, Color.blue, Color.white
]

# These "Scale" palettes are actually generated at run-time, but they are
# exported here to the palette control generator will see them
export(Array, Color) var Gray_Scale:Array
export(Array, Color) var Red_Scale:Array
export(Array, Color) var Green_Scale:Array
export(Array, Color) var Blue_Scale:Array

# Rainbow colors from R rainbow color() ramp
# warning-ignore:unused_class_variable
export(Array, Color) var Rainbow:Array = [
	Color("#FF0000"), Color("#FF5500"), Color("#FFAA00"), Color("#FFFF00"),
	Color("#AAFF00"), Color("#55FF00"), Color("#00FF00"), Color("#00FF55"),
	Color("#00FFAA"), Color("#00FFFF"), Color("#00AAFF"), Color("#0055FF"),
	Color("#0000FF"), Color("#5500FF"), Color("#AA00FF"), Color("#FF00FF")
]

# Terrain colors from R terrain.colors() ramp
# warning-ignore:unused_class_variable
export(Array, Color) var Terrain:Array = [
	Color("#00A600"), Color("#19AF00"), Color("#35B800"), Color("#53C100"),
	Color("#74CA00"), Color("#97D300"), Color("#BDDC00"), Color("#E6E600"),
	Color("#E7CE1D"), Color("#E9BD3A"), Color("#EAB358"), Color("#ECB176"),
	Color("#EDB694"), Color("#EFC2B3"), Color("#F1D6D3"), Color("#F2F2F2")
]

# Topographic colors from R topo.colors() ramp
# warning-ignore:unused_class_variable
export(Array, Color) var Topographic:Array = [
	Color("#4C00FF"), Color("#0F00FF"), Color("#002EFF"), Color("#006BFF"),
	Color("#00A8FF"), Color("#00E5FF"), Color("#00FF4D"), Color("#00FF00"),
	Color("#4DFF00"), Color("#99FF00"), Color("#E6FF00"), Color("#FFFF00"),
	Color("#FFEA2D"), Color("#FFDE59"), Color("#FFDB86"), Color("#FFE0B3")
]


func _init(): # fill in the "Scale" palettes
	var step:float = 1.0 / 16.0
	for n in 16:
		var intensity:float = step * (n + 1)
		Gray_Scale.push_back(Color(intensity, intensity, intensity, 1.0))
		Red_Scale.push_back(Color(intensity, 0.0, 0.0, 1.0))
		Green_Scale.push_back(Color(0.0, intensity, 0.0, 1.0))
		Blue_Scale.push_back(Color(0.0, 0.0, intensity, 1.0))


func set_palette_options(): # populate the PaletteOption UI button
	var flags = PROPERTY_USAGE_SCRIPT_VARIABLE + PROPERTY_USAGE_DEFAULT
	var id:int = 0
	for property in get_property_list():
		if property.usage & flags == flags:
			Global.controls["PaletteOption"].add_item(property.name.capitalize(), id)
			Global.controls["PaletteOption"].set_item_metadata(id, self[property.name])
			id += 1


func build_active_palette_controls():
	# "Colors" is a VBoxContainer that will hold all the palette controls
	var colors:VBoxContainer = Global.controls["Colors"]
	# Remove any controls already in the container
	while colors.get_child_count() > 0:
		colors.get_child(0).free()
	# Get the active palette and append 8 transparent colors (user colors)
	var palette_colors:Array = Global.controls["PaletteOption"].get_selected_metadata().duplicate()
	for n in 8:
		palette_colors.push_back(Color.transparent)
	# For each color build an HBoxContainer with a checkbox, a number, and a color picker
	var n:int = 0
	for color in palette_colors:
		var hbox = HBoxContainer.new()
		hbox.set("custom_constants/separation", 8)
		colors.add_child(hbox)
		var check_box = CheckBox.new()
		hbox.add_child(check_box)
		var label = Label.new()
		label.text = "%3s:" % [n]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = 0.3
		n += 1
		hbox.add_child(label)
		var color_picker_button = ColorPickerButton.new()
		color_picker_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		color_picker_button.color = color
		color_picker_button.get_picker().add_preset(color)
		hbox.add_child(color_picker_button)


func active_color_list():
	var colors:VBoxContainer = Global.controls["Colors"]
	var color_list = []
	for hbox in colors.get_children():
		if hbox.get_child(0).pressed:
			color_list.push_back(hbox.get_child(2).color)
	return color_list


func _on_PaletteOption_item_selected(_index):
	build_active_palette_controls()
	var colors:VBoxContainer = Global.controls["Colors"]
	for n in colors.get_child_count() - 8:
		colors.get_child(n).get_child(0).pressed = true


var previous_selected:int = -1


func _on_PaletteOption_button_up():
	previous_selected = Global.controls["PaletteOption"].selected


func _on_PaletteOption_toggled(_button_pressed):
	var colors:VBoxContainer = Global.controls["Colors"]
	if Global.controls["PaletteOption"].selected == previous_selected:
		var new_state:bool = not colors.get_child(0).get_child(0).pressed
		for n in colors.get_child_count() - 8:
			colors.get_child(n).get_child(0).pressed = new_state
		previous_selected = -1
