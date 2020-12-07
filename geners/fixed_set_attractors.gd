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
	"minimum_fixed_points": ["int", 3, 100],
	"maximum_fixed_points": ["int", 3, 100],
	"angle_style": ["option", ["Uniform", "Random"]],
	"start_angle": ["float", 0.0, 360.0, 1.0],
	"end_angle": ["float", 0.0, 360.0, 1.0],
	"radius_style": ["option", ["Fixed", "Uniform (Min to Max)", "Uniform (Max to Min)", "Random"]],
	"minimum_radius": ["float", 0.0, 1.0, 0.1],
	"maximum_radius": ["float", 0.0, 1.0, 0.1],
	"attraction_style": ["option", ["Fixed", "Uniform (Min to Max)", "Uniform (Max to Min)", "Random"]],
	"minimum_attraction": ["float", -10.0, 10.0, 0.1],
	"maximum_attraction": ["float", -10.0, 10.0, 0.1],
	"specific_attraction_values": ["array", "fixed_point_attraction", 1000, "float", 0.5, -10.0, 10.0, 0.1],
	"minimum_pixels": ["int", 0, 1000000],
	"maximum_pixels": ["int", 0, 1000000],
	"color_mode": ["option", ["Image", "Pixel", "Intensity", "Intensity Palette"]],
	"symmetry": ["option", ["None", "Vertical", "Horizontal", "Both"]],
}
var minimum_fixed_points := 3 setget set_minimum_fixed_points
var maximum_fixed_points := 9 setget set_maximum_fixed_points
var angle_style := "Uniform"
var start_angle := 0.0
var end_angle := 360.0
var radius_style := "Fixed"
var minimum_radius := 0.2 setget set_minimum_radius
var maximum_radius := 0.8 setget set_maximum_radius
var attraction_style := "Fixed"
var minimum_attraction := 0.25 setget set_minimum_attraction
var maximum_attraction := 1.50 setget set_maximum_attraction
var specific_attraction_values := 0
var fixed_point_attraction = []
var minimum_pixels := 1000 setget set_minimum_pixels
var maximum_pixels := 10000 setget set_maximum_pixels
var color_mode := "Image"
var symmetry := "None"


func set_minimum_fixed_points(value):
	minimum_fixed_points = value
	if minimum_fixed_points > maximum_fixed_points:
		maximum_fixed_points = minimum_fixed_points
	Global.controls.GenerInspector.update_inspector()


func set_maximum_fixed_points(value):
	maximum_fixed_points = value
	if maximum_fixed_points < minimum_fixed_points:
		minimum_fixed_points = maximum_fixed_points
	Global.controls.GenerInspector.update_inspector()


func set_minimum_radius(value):
	minimum_radius = value
	if minimum_radius > maximum_radius:
		maximum_radius = minimum_radius
	Global.controls.GenerInspector.update_inspector()


func set_maximum_radius(value):
	maximum_radius = value
	if maximum_radius < minimum_radius:
		minimum_radius = maximum_radius
	Global.controls.GenerInspector.update_inspector()


func set_minimum_attraction(value):
	minimum_attraction = value
	if minimum_attraction > maximum_attraction:
		maximum_attraction = minimum_attraction
	Global.controls.GenerInspector.update_inspector()


func set_maximum_attraction(value):
	maximum_attraction = value
	if maximum_attraction < minimum_attraction:
		minimum_attraction = maximum_attraction
	Global.controls.GenerInspector.update_inspector()


func set_minimum_pixels(value):
	minimum_pixels = value
	if minimum_pixels > maximum_pixels:
		maximum_pixels = minimum_pixels
	Global.controls.GenerInspector.update_inspector()


func set_maximum_pixels(value):
	maximum_pixels = value
	if maximum_pixels < minimum_pixels:
		minimum_pixels = maximum_pixels
	Global.controls.GenerInspector.update_inspector()


func tiley_gener(size:Vector2, colors:Array = []) -> Image:
	var image := Image.new()
	image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
	var fixed_points = generate_fixed_points(size)
	match symmetry:
		"None":
			generate_pixels(image, fixed_points, colors)
		"Vertical":
			var left_image := Image.new()
			left_image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
			generate_pixels(left_image, fixed_points, colors)
			left_image.crop(round(size.x / 2) as int, round(size.y) as int)
			image.blit_rect(left_image, Rect2(Vector2.ZERO, left_image.get_size()), Vector2.ZERO)
			left_image.flip_x()
			image.blit_rect(left_image, Rect2(Vector2.ZERO, left_image.get_size()), Vector2(left_image.get_width(), 0))
		"Horizontal":
			var top_image := Image.new()
			top_image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
			generate_pixels(top_image, fixed_points, colors)
			top_image.crop(round(size.x) as int, round(size.y / 2) as int)
			image.blit_rect(top_image, Rect2(Vector2.ZERO, top_image.get_size()), Vector2.ZERO)
			top_image.flip_y()
			image.blit_rect(top_image, Rect2(Vector2.ZERO, top_image.get_size()), Vector2(0, top_image.get_height()))
		"Both":
			var quadrant_image := Image.new()
			quadrant_image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
			generate_pixels(quadrant_image, fixed_points, colors)
			quadrant_image.crop(round(size.x / 2) as int, round(size.y / 2) as int)
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2.ZERO)
			quadrant_image.flip_x()
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2(quadrant_image.get_width(), 0))
			quadrant_image.flip_y()
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2(quadrant_image.get_width(), quadrant_image.get_height()))
			quadrant_image.flip_x()
			image.blit_rect(quadrant_image, Rect2(Vector2.ZERO, quadrant_image.get_size()), Vector2(0, quadrant_image.get_height()))
	return image


func generate_fixed_points(size:Vector2):
	var image_points := randi() % (maximum_fixed_points - minimum_fixed_points + 1) + minimum_fixed_points
	var image_radius := rand_range(minimum_radius, maximum_radius)
	var image_attraction := rand_range(minimum_attraction, maximum_attraction)
	var fixed_points = []
	for n in image_points:
		var a:float
		var r:float
		var t:float
		match angle_style:
			"Uniform":
				a = uniform(start_angle, end_angle, image_points, n)
			"Random":
				a = rand_range(start_angle, end_angle)
		match radius_style:
			"Fixed":
				r = image_radius
			"Uniform (Min to Max)":
				r = uniform(minimum_radius, maximum_radius, image_points, n)
			"Uniform (Max to Min)":
				r = uniform(maximum_radius, minimum_radius, image_points, n)
			"Random":
				r = rand_range(minimum_radius, maximum_radius)
		if n < specific_attraction_values:
			t = fixed_point_attraction[n]
		else:
			match attraction_style:
				"Fixed":
					t = image_attraction
				"Uniform (Min to Max)":
					t = uniform(minimum_attraction, maximum_attraction, image_points, n)
				"Uniform (Max to Min)":
					t = uniform(maximum_attraction, minimum_attraction, image_points, n)
				"Random":
					t = rand_range(minimum_attraction, maximum_attraction)
		var p:Vector2 = r * 0.5 * size.x * Vector2(cos(deg2rad(a)), sin(deg2rad(a)))
		fixed_points.push_back(Vector3(p.x + 0.5 * size.x, p.y + 0.5 * size.y, t))
	return fixed_points


func uniform(start:float, end:float, partitions:int, n:int):
	return start + n * ((end - start) / partitions)


func generate_pixels(image:Image, fixed_points:Array, colors:Array):
	var image_rect := Rect2(Vector2.ZERO, image.get_size())
	var image_pixels := randi() % (maximum_pixels - minimum_pixels + 1) + minimum_pixels
	var color_chooser = ColorChooser.new(colors, color_mode, image.get_size())
	var p3:Vector3 = fixed_points[0]
	var p2 := Vector2(p3.x, p3.y)
	image.lock()
	for n in image_pixels:
		var q3:Vector3 = choose_element(fixed_points)
		var q2 := Vector2(q3.x, q3.y)
		p2 = p2 + p2.direction_to(q2) * q3.z * p2.distance_to(q2)
		if image_rect.has_point(p2):
			image.set_pixelv(p2, color_chooser.next_color(p2.x, p2.y))
	image.unlock()


func choose_element(array:Array):
	assert(array.size() > 0)
	return array[randi() % array.size()]


class ColorChooser:

	var palette:Array
	var mode:String
	var size:Vector2
	var base_color:Color
	var hits:Array
	

	func _init(colors:Array, color_mode:String, image_size:Vector2):
		palette = colors
		mode = color_mode
		size = image_size
		if mode in ["Image", "Intensity"]:
			base_color = choose_color()
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
			"Image":
				return base_color
			"Pixel":
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


	func choose_color() -> Color:
		if palette.size() == 0:
			return Color(randf(), randf(), randf())
		else:
			return palette[randi() % palette.size()]
