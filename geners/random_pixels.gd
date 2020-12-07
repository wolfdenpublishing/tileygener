extends Node

# warning-ignore:unused_class_variable
export(String) var gener_name
# warning-ignore:unused_class_variable
export(String, MULTILINE) var gener_description
# warning-ignore:unused_class_variable
var gener_grid_defaults = {
	"grid_size": 4,
	"tiley_size": 128,
	"tiley_scale": 2,
	"background_color": Color.black,
}
# warning-ignore:unused_class_variable
var gener_properties = {
	"number_of_passes": ["array", "pass_pixels", 4, "int", 1000, 0, 1000000],
	"dice_for_passes": ["array", "pass_dice", 4, "int", 1, 1, 10],
	"symmetry": ["option", ["None", "Vertical", "Horizontal", "Both"]],
	"symmetry_style": ["option", ["Full", "Slice"]],
	"color_mode": ["option", ["Per Pass (Random)", "Per Pass (Ordered)", "Per Pixel", "Intensity", "Intensity Palette"]],
	"use_random_color_alpha": ["bool"],
}
var number_of_passes:int = 1
var pass_pixels = []
var dice_for_passes:int = 1
var pass_dice = []
var symmetry:String = "None"
var symmetry_style:String = "Full"
var color_mode = "Per Pass (Random)"
var use_random_color_alpha:bool = false


func tiley_gener(size:Vector2, colors:Array = []) -> Image:
	var image := Image.new()
	image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
	match symmetry:
		"None":
			random_pixels(image, colors)
		"Vertical":
			var left_image := Image.new()
			if symmetry_style == "Full":
				left_image.create(round(size.x / 2) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
				random_pixels(left_image, colors)
			else:
				left_image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
				random_pixels(left_image, colors)
				left_image.crop(round(size.x / 2) as int, round(size.y) as int)
			image.blit_rect(left_image, Rect2(Vector2.ZERO, left_image.get_size()), Vector2.ZERO)
			left_image.flip_x()
			image.blit_rect(left_image, Rect2(Vector2.ZERO, left_image.get_size()), Vector2(left_image.get_width(), 0))
		"Horizontal":
			var top_image := Image.new()
			if symmetry_style == "Full":
				top_image.create(round(size.x) as int, round(size.y / 2) as int, false, Image.FORMAT_RGBA8)
				random_pixels(top_image, colors)
			else:
				top_image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
				random_pixels(top_image, colors)
				top_image.crop(round(size.x) as int, round(size.y / 2) as int)
			image.blit_rect(top_image, Rect2(Vector2.ZERO, top_image.get_size()), Vector2.ZERO)
			top_image.flip_y()
			image.blit_rect(top_image, Rect2(Vector2.ZERO, top_image.get_size()), Vector2(0, top_image.get_height()))
		"Both":
			var quadrant_image := Image.new()
			if symmetry_style == "Full":
				quadrant_image.create(round(size.x / 2) as int, round(size.y / 2) as int, false, Image.FORMAT_RGBA8)
				random_pixels(quadrant_image, colors)
			else:
				quadrant_image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
				random_pixels(quadrant_image, colors)
				quadrant_image.crop(round(size.x / 2) as int, round(size.y / 2) as int)
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2.ZERO)
			quadrant_image.flip_x()
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2(quadrant_image.get_width(), 0))
			quadrant_image.flip_y()
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2(quadrant_image.get_width(), quadrant_image.get_height()))
			quadrant_image.flip_x()
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2(0, quadrant_image.get_height()))
	return image


func random_pixels(image:Image, colors:Array):
	image.lock()
	for n in number_of_passes:
		var color_chooser = ColorChooser.new(colors, color_mode, use_random_color_alpha, image.get_size(), n)
		var dice_this_pass:int = pass_dice[n % dice_for_passes]
		for i in pass_pixels[n]:
			var x:int = dice(dice_this_pass, image.get_width())
			var y:int = dice(dice_this_pass, image.get_height())
			var c:Color = color_chooser.next_color(x, y)
			image.set_pixel(x, y, c)
	image.unlock()


func dice(dice:int, pixels:float) -> int:
	var roll:float = 0
	for n in dice:
		roll += randf() * (pixels / dice)
	return int(roll)


class ColorChooser:

	var palette:Array
	var mode:String
	var size:Vector2
	var layer:int
	var randomize_alpha:bool
	var base_color:Color
	var hits:Array
	

	func _init(colors:Array, color_mode:String, use_random_alpha:bool, image_size:Vector2, pass_number:int):
		palette = colors
		mode = color_mode
		randomize_alpha = use_random_alpha
		size = image_size
		layer = pass_number
		match mode:
			"Per Pass (Random)", "Intensity":
				base_color = choose_color()
			"Per Pass (Ordered)":
				base_color = choose_color(layer)
		if mode in ["Intensity", "Intensity Palette"]:
			hits = []
			hits.resize(round(size.x) as int)
			for i in size.x:
				hits[i] = []
				hits[i].resize(round(size.y) as int)
				for j in size.y:
					hits[i][j] = 0


	func next_color(x:int, y:int) -> Color:
		match mode:
			"Per Pass (Random)", "Per Pass (Ordered)":
				return base_color
			"Per Pixel":
				return choose_color()
			"Intensity":
				hits[x][y] += 1
				var alpha = min(1.0, (1.0 / 16) * hits[x][y])
				return Color(base_color.r, base_color.g, base_color.b, alpha)
			"Intensity Palette":
				if palette.size() > 0:
					var color = min(hits[x][y], palette.size() - 1)
					hits[x][y] += 1
					return palette[color]
				else:
					return Color.transparent
			_:
				return Color.transparent


	func choose_color(n:int = -1) -> Color:
		if palette.size() == 0:
			if randomize_alpha:
				return Color(randf(), randf(), randf(), randf())
			else:
				return Color(randf(), randf(), randf())
		else:
			if n == -1:
				return palette[randi() % palette.size()]
			else:
				return palette[n % palette.size()]
