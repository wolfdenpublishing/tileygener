extends Node

# warning-ignore:unused_class_variable
export(String) var gener_name
# warning-ignore:unused_class_variable
export(String, MULTILINE) var gener_description

# warning-ignore:unused_class_variable
var gener_grid_defaults = {
	"grid_size": 4,
	"tiley_size": 32,
	"tiley_scale": 8,
	"background_color": Color.black,
}

# warning-ignore:unused_class_variable
var gener_properties = {
	"minimum_start_pixels": ["int", 0, 1000000],
	"maximum_start_pixels": ["int", 0, 1000000],
	"start_pixel_dice": ["int", 1, 10],
	"use_random_automata": ["bool"],
	"state_0_rules": ["string"],
	"state_1_rules": ["string"],
	"minimum_generations": ["int", 0, 1000000],
	"maximum_generations": ["int", 0, 1000000],
	"color_mode": ["option", ["Image", "Pixel", "Generation Intensity", "Generation Palette"]],
	"symmetry": ["option", ["None", "Vertical", "Horizontal", "Both"]],
}
var minimum_start_pixels:int = 500 setget set_minimum_start_pixels
var maximum_start_pixels:int = 1000 setget set_maximum_start_pixels
var start_pixel_dice:int = 2
var use_random_automata:bool = false
var state_0_rules:String = "000101000" setget set_state_0_rules
var state_1_rules:String = "001100010" setget set_state_1_rules
var minimum_generations:int = 1 setget set_minimum_generations
var maximum_generations:int = 8 setget set_maximum_generations
var color_mode:String = "Image"
var symmetry:String = "Both"

var user_rules:Array


func set_minimum_start_pixels(value):
	minimum_start_pixels = value
	if minimum_start_pixels > maximum_start_pixels:
		maximum_start_pixels = minimum_start_pixels
		Global.controls.GenerInspector.update_inspector()


func set_maximum_start_pixels(value):
	maximum_start_pixels = value
	if maximum_start_pixels < minimum_start_pixels:
		minimum_start_pixels = maximum_start_pixels
		Global.controls.GenerInspector.update_inspector()


func set_state_0_rules(value):
	state_0_rules = value
	user_rules = rules(state_0_rules, state_1_rules)


func set_state_1_rules(value):
	state_1_rules = value
	user_rules = rules(state_0_rules, state_1_rules)


func set_minimum_generations(value):
	minimum_generations = value
	if minimum_generations > maximum_generations:
		maximum_generations = minimum_generations
		Global.controls.GenerInspector.update_inspector()
		

func set_maximum_generations(value):
	maximum_generations = value
	if maximum_generations < minimum_generations:
		minimum_generations = maximum_generations
		Global.controls.GenerInspector.update_inspector()


func _init():
	user_rules = rules(state_0_rules, state_1_rules)


func rules(state_0:String = "", state_1:String = "") -> Array:
	if state_0 == "":
		state_0 = random_rule_string()
	if state_1 == "":
		state_1 = random_rule_string()
	var rules:Array = []
	rules.append([])
	for i in state_0.length():
		rules[0].append(state_0[i] == "1")
	rules.append([])
	for i in state_1.length():
		rules[1].append(state_1[i] == "1")
	return rules


func random_rule_string() -> String:
	var s:String = ""
	for i in 9:
		s += "0" if randi() % 2 == 0 else "1"
	return s
	

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


func generate_pixels(image:Image, colors:Array) -> void:
	var color_chooser = ColorChooser.new(colors, color_mode)
	random_pixels(image, color_chooser)
	var rules:Array = rules() if use_random_automata else user_rules
	var generations:int = randi() % (maximum_generations - minimum_generations + 1) + minimum_generations
	for gen in generations:
		next_generation(image, color_chooser, rules, gen, generations)


func next_generation(image:Image, color_chooser:ColorChooser, rules:Array, gen:int, generations:int) -> void:
	var generation_color = color_chooser.next_color(float(gen) / float(generations))
	var next_image := Image.new()
	next_image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	next_image.lock()
	image.lock()
	for x in image.get_width():
		for y in image.get_height():
			var p:int = 1 if image.get_pixel(x, y).a > 0.0 else 0
			var n:int = neighbor_count(image, x, y)
			if rules[p][n]:
				if color_mode == "Pixel":
					next_image.set_pixel(x, y, color_chooser.next_color())
				elif image.get_pixel(x, y).a > 0.0:
					next_image.set_pixel(x, y, image.get_pixel(x, y))
				else:
					next_image.set_pixel(x, y, generation_color)
	image.unlock()
	next_image.unlock()
	image.copy_from(next_image)


func neighbor_count(image:Image, x:int, y:int) -> int:
	var image_rect:Rect2 = Rect2(Vector2.ZERO, image.get_size())
	var n:int = 0
	for i in [x - 1, x, x + 1]:
		for j in [y - 1, y, y + 1]:
			if image_rect.has_point(Vector2(i,j)) and (i != x or j != y):
				if image.get_pixel(i,j).a > 0.0:
					n += 1
	return n


func random_pixels(image:Image, color_chooser:ColorChooser) -> void:
	image.lock()
	var start_pixels := randi() % (maximum_start_pixels - minimum_start_pixels + 1) + minimum_start_pixels
	for i in start_pixels:
		var x:int = dice(start_pixel_dice, image.get_width())
		var y:int = dice(start_pixel_dice, image.get_height())
		var c:Color = color_chooser.next_color()
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
	var base_color:Color
	

	func _init(colors:Array, color_mode:String):
		palette = colors
		mode = color_mode
		if mode in ["Image", "Generation Intensity"]:
			base_color = choose_color()


	func next_color(gen:float = 0.0) -> Color:
		match mode:
			"Image":
				return base_color
			"Pixel":
				return choose_color()
			"Generation Intensity":
				if gen > 0.0:
					return Color(base_color.r, base_color.g, base_color.b, gen)
				else:
					return base_color
			"Generation Palette":
				if palette.size() > 0:
					var color:int = round((palette.size() - 1) * gen) as int
					return palette[color]
				else:
					return Color.transparent
			_:
				return Color.transparent


	func choose_color() -> Color:
		if palette.size() == 0:
			return Color(randf(), randf(), randf())
		else:
			return palette[randi() % palette.size()]
