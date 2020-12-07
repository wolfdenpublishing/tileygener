extends Node

var sprites = [] # array of generated Sprite instances
var active_gener # keep track of currently active gener node

# references to nodes we need often (i.e. generally meaning more than once)
onready var sprites_container:PanelContainer = $Sprites
onready var palettes:Node = $Palettes
onready var gener_option:OptionButton = Global.controls.GenerOption
onready var gener_inspector:MarginContainer = Global.controls.GenerInspector
onready var gener_description:RichTextLabel = Global.controls.GenerDescription
onready var grid_size:SpinBox = Global.controls.GridSize
onready var tiley_size:SpinBox = Global.controls.TileySize
onready var tiley_scale:SpinBox = Global.controls.TileyScale
onready var background:ColorPickerButton = Global.controls.Background


func _init():
	Global.tiley = self


func _ready():
	# build the UI control that shows the list of geners
	set_gener_options()
	# build the UI controls that shows the available palettes
	palettes.set_palette_options()
	# build the controls for the active (default in this case) palette
	palettes.build_active_palette_controls()
	# build the controls for the active (default in this case) gener
	set_active_gener()
	# set optional default grid options
	set_grid_defaults()
	# generate an initial set of Sprites from the default settings
	generate()


func set_gener_options(): # build the GenerOption UI control
	for gener in $Gener.get_children():
		gener_option.add_item(gener.gener_name, gener.get_index())
		gener_option.set_item_metadata(gener.get_index(), gener)


func set_active_gener(): # build the UI for the active gener
	active_gener = gener_option.get_selected_metadata()
	gener_inspector.create_inspector(active_gener)
	gener_description.bbcode_text = active_gener.gener_description


func set_grid_defaults():
	var d:Dictionary = active_gener.gener_grid_defaults if active_gener.gener_grid_defaults else {}
	grid_size.value = d.grid_size if d.has("grid_size") else 4
	tiley_size.value = d.tiley_size if d.has("tiley_size") else 128
	tiley_scale.value = d.tiley_scale if d.has("tiley_scale") else 2.0
	background.color = d.background_color if d.has("background_color") else Color.black
	sprites_container.get("custom_styles/panel").bg_color = background.color
	adjust_scale()
	

func generate():
	# create the Sprite instances
	sprites = []
	while sprites_container.get_child_count() > 0:
		sprites_container.get_child(0).free()
	for n in pow(grid_size.value, 2 ):
		var sprite := Sprite.new()
		sprites_container.add_child(sprite)
		sprites.push_back(sprite)
	var cell_size:Vector2 = (1.0 / grid_size.value) * sprites_container.rect_size
	var start_position:Vector2 = 0.5 * cell_size
	for n in sprites_container.get_child_count():
		var r:int = n / int(grid_size.value)
		var c:int = n % int(grid_size.value)
		var p:Vector2 = start_position + Vector2(c * cell_size.x, r * cell_size.y)
		sprites[n].position = p
	# call the active gener's tiley_gener() for each Sprite
	var active_colors = palettes.active_color_list()
	for n in sprites.size():
		sprites[n].texture = ImageTexture.new()
		sprites[n].texture.create_from_image(active_gener.tiley_gener(Vector2(tiley_size.value, tiley_size.value), active_colors), 0)
		sprites[n].scale = Vector2(tiley_scale.value, tiley_scale.value)


func adjust_scale(): # make sure the images fit nicely in the window
	var pixel_count = (tiley_size.value / 32) + grid_size.value * (tiley_size.value + (tiley_size.value / 32))
	var max_scale = stepify(sprites_container.rect_size.x / pixel_count, 0.1)
	if tiley_scale.value > max_scale:
		tiley_scale.value = max_scale
		

func _on_Generate_pressed():
	generate()


func _on_GridSize_value_changed(_value):
	adjust_scale()


func _on_TileySize_value_changed(_value):
	adjust_scale()


func _on_TileyScale_value_changed(_value):
	adjust_scale()


# todo - something other than hardcode these defaults?
func _on_Reset_pressed():
	set_grid_defaults()


func _on_Background_color_changed(color):
	sprites_container.get("custom_styles/panel").bg_color = color


# call the OS to handle clicked links in the gener descriptions
func _on_GenerDescription_meta_clicked(meta):
	var err = OS.shell_open(meta)
	assert(err == OK)


func _on_GenerOption_item_selected(_index):
	set_active_gener()
	set_grid_defaults()
	generate()


# "reset" active gener by instancing a new one
func _on_ResetGener_pressed():
	# we'll need our script path and our position in the tree
	var active_script = active_gener.script.resource_path
	var active_index = active_gener.get_index()
	# preserve export properties
	var active_name = active_gener.gener_name
	var active_description = active_gener.gener_description
	# remove current gener from the tree and free it
	$Gener.remove_child(active_gener)
	active_gener.free()
	# instance a new one and restore export properties
	active_gener = load(active_script).new()
	active_gener.gener_name = active_name
	active_gener.gener_description = active_description
	# put it back in the tree at the same location
	$Gener.add_child(active_gener)
	$Gener.move_child(active_gener, active_index)
	# rebuild the controls and go
	gener_option.set_item_metadata(active_gener.get_index(), active_gener)
	set_active_gener()
	generate()
