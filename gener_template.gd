extends Node

# --- DON'T CHANGE THESE - EDIT THEM IN THE INSPECTOR --------------------------
# gener_name identifies this gener to the app, used in the option button
# warning-ignore:unused_class_variable
export(String) var gener_name
# gener_description is the help info for this gener, supports bbcode
# warning-ignore:unused_class_variable
export(String, MULTILINE) var gener_description
# ------------------------------------------------------------------------------

# optional grid defaults
# warning-ignore:unused_class_variable
var gener_grid_defaults = {
	"grid_size": 4,
	"tiley_size": 128,
	"tiley_scale": 2,
	"background_color": Color.black,
}

# list of properties to add to the inspector
# supported types:
#	["bool"]
#	["int", min, max]
#	["float", min, max, step]
#	["string"]
#	["option", [Option_1, Option_2, ...]]
#	["array", array_name, array_max, "bool", default_value]
#	["array", array_name, array_max, "int", default_value, min, max]
#	["array", array_name, array_max, "float", default_value, min, max, step]
#	["array", array_name, array_max, "string", default_value]
#	["array", array_name, array_max, "option", default_value, [Option_1, Option_2, ...]]
# warning-ignore:unused_class_variable
var gener_properties = {
	"symmetry": ["option", ["None", "Vertical", "Horizontal", "Both"]],
}
# each property above must have a script variable of the same name
# and should be initialized to a default value
var symmetry:String = "None"


func generate_pixels(image:Image, colors:Array) -> void:
	image.lock()
	# --- GENERATE PIXELS HERE with image.setpixel() or image.setpixelv()
	image.unlock()


# Main function to generate a single tile. Template version handles basic
# symmetry and calls generate_pixels() to draw actual pixels into a tile
func tiley_gener(size:Vector2, colors:Array = []) -> Image:
	var image := Image.new()
	image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
	match symmetry:
		"None":
			generate_pixels(image, colors)
		"Vertical":
			var left_image := Image.new()
			left_image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
			generate_pixels(left_image, colors)
			left_image.crop(round(size.x / 2) as int, round(size.y) as int)
			image.blit_rect(left_image, Rect2(Vector2.ZERO, left_image.get_size()), Vector2.ZERO)
			left_image.flip_x()
			image.blit_rect(left_image, Rect2(Vector2.ZERO, left_image.get_size()), Vector2(left_image.get_width(), 0))
		"Horizontal":
			var top_image := Image.new()
			top_image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
			generate_pixels(top_image, colors)
			top_image.crop(round(size.x) as int, round(size.y / 2) as int)
			image.blit_rect(top_image, Rect2(Vector2.ZERO, top_image.get_size()), Vector2.ZERO)
			top_image.flip_y()
			image.blit_rect(top_image, Rect2(Vector2.ZERO, top_image.get_size()), Vector2(0, top_image.get_height()))
		"Both":
			var quadrant_image := Image.new()
			quadrant_image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
			generate_pixels(quadrant_image, colors)
			quadrant_image.crop(round(size.x / 2) as int, round(size.y / 2) as int)
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2.ZERO)
			quadrant_image.flip_x()
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2(quadrant_image.get_width(), 0))
			quadrant_image.flip_y()
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2(quadrant_image.get_width(), quadrant_image.get_height()))
			quadrant_image.flip_x()
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2(0, quadrant_image.get_height()))
	return image
