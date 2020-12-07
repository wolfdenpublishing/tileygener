extends Node

# warning-ignore:unused_class_variable
export(String) var gener_name
# warning-ignore:unused_class_variable
export(String, MULTILINE) var gener_description

# warning-ignore:unused_class_variable
var gener_grid_defaults = {
	"grid_size": 4,
	"tiley_size": 256,
	"tiley_scale": 1,
	"background_color": Color.black,
}

# warning-ignore:unused_class_variable
var gener_properties = {
	"style": ["option", ["Hypocycloid", "Epicycloid", "Random"]],
	"big_r_min": ["float", 0.1, 1.0, 0.01],
	"big_r_max": ["float", 0.1, 1.0, 0.01],
	"small_r_min": ["float", 0.1, 1.0, 0.01],
	"small_r_max": ["float", 0.1, 1.0, 0.01],
	"a_min": ["float", 0.1, 1.0, 0.01],
	"a_max": ["float", 0.1, 1.0, 0.01],
	"t_min": ["int", 1, 100000],
	"t_max": ["int", 1, 100000],
	"step_min": ["float", 0.01, 1.0, 0.01],
	"step_max": ["float", 0.01, 1.0, 0.01],
	"min_spiros": ["int", 1, 10],
	"max_spiros": ["int", 1, 10],
}
var style:String = "Random"
var big_r_min:float = 0.5 setget set_big_r_min
var big_r_max:float = 1.0 setget set_big_r_max
var small_r_min:float = 0.1 setget set_small_r_min
var small_r_max:float = 0.4 setget set_small_r_max
var a_min:float = 0.1 setget set_a_min
var a_max:float = 0.9 setget set_a_max
var t_min:int = 100 setget set_t_min
var t_max:int = 1000 setget set_t_max
var step_min:float = 0.01 setget set_step_min
var step_max:float = 0.2 setget set_step_max
var min_spiros:int = 1 setget set_min_spiros
var max_spiros:int = 4 setget set_max_spiros


func set_big_r_min(value):
	big_r_min = value
	if big_r_min > big_r_max:
		big_r_max = big_r_min
	Global.controls.GenerInspector.update_inspector()


func set_big_r_max(value):
	big_r_max = value
	if big_r_max < big_r_min:
		big_r_min = big_r_max
	Global.controls.GenerInspector.update_inspector()


func set_small_r_min(value):
	small_r_min = value
	if small_r_min > small_r_max:
		small_r_max = small_r_min
	Global.controls.GenerInspector.update_inspector()


func set_small_r_max(value):
	small_r_max = value
	if small_r_max < small_r_min:
		small_r_min = small_r_max
	Global.controls.GenerInspector.update_inspector()


func set_a_min(value):
	a_min = value
	if a_min > a_max:
		a_max = a_min
	Global.controls.GenerInspector.update_inspector()


func set_a_max(value):
	a_max = value
	if a_max < a_min:
		a_min = a_max
	Global.controls.GenerInspector.update_inspector()


func set_t_min(value):
	t_min = value
	if t_min > t_max:
		t_max = t_min
	Global.controls.GenerInspector.update_inspector()


func set_t_max(value):
	t_max = value
	if t_max < t_min:
		t_min = t_max
	Global.controls.GenerInspector.update_inspector()


func set_step_min(value):
	step_min = value
	if step_min > step_max:
		step_max = step_min
	Global.controls.GenerInspector.update_inspector()


func set_step_max(value):
	step_max = value
	if step_max < step_min:
		step_min = step_max
	Global.controls.GenerInspector.update_inspector()


func set_min_spiros(value):
	min_spiros = value
	if min_spiros > max_spiros:
		max_spiros = min_spiros
	Global.controls.GenerInspector.update_inspector()


func set_max_spiros(value):
	max_spiros = value
	if max_spiros < min_spiros:
		min_spiros = max_spiros
	Global.controls.GenerInspector.update_inspector()


func tiley_gener(size:Vector2, colors:Array = []) -> Image:
	var image := Image.new()
	image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
	for i in randi() % (max_spiros - min_spiros + 1) + min_spiros:
		spirograph(image, colors)
	return image


func spirograph(image:Image, colors:Array):
	var image_rect:Rect2 = Rect2(Vector2.ZERO, image.get_size())
	var s:float = image.get_width() / 2.0
	var R:float = s * rand_range(big_r_min, big_r_max)
	var r:float = s * rand_range(small_r_min, small_r_max)
	var a:float = s * rand_range(a_min, a_max)
	var k1:float = R - r
	var k2:float = r / R
	var k3:float = R + r
	var mode:int = 0 if style == "Hypocycloid" or (style == "Random" and randf() > 0.5) else 1
	var x:int
	var y:int
	var c := Color(randf(), randf(), randf(), rand_range(0.75, 1.0))
	if colors.size() > 0:
		c = colors[randi() % colors.size()]
	var step:float = rand_range(step_min, step_max)
	var t:float = rand_range(t_max, t_max)
	image.lock()
	while t >= 0:
		match mode:
			0: # hypocycloid
				x = round(s + k1 * cos(k2 * t) + a * cos((1 - k2) * t)) as int
				y = round(s + k1 * sin(k2 * t) - a * sin((1 - k2) * t)) as int
			1: # epicycloid
				x = round(s + k3 * cos(k2 * t) - a * cos((1 + k2) * t)) as int
				y = round(s + k3 * sin(k2 * t) - a * sin((1 + k2) * t)) as int
		if image_rect.has_point(Vector2(x, y)):
			image.set_pixel(x, y, c)
		t -= step
	image.unlock()
