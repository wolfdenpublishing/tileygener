extends Node

# warning-ignore:unused_class_variable
export(String) var gener_name
# warning-ignore:unused_class_variable
export(String, MULTILINE) var gener_description

# warning-ignore:unused_class_variable
var gener_grid_defaults = {
	"grid_size": 2,
	"tiley_size": 256,
	"tiley_scale": 4,
	"background_color": Color.black,
}

# warning-ignore:unused_class_variable
var gener_properties = {
	"use_random_seeds": ["bool"],
	"minimum_random_seed": ["float", -1.0, 1.0, 0.1],
	"maximum_random_seed": ["float", -1.0, 1.0, 0.1],
	"upper_left_seed": ["float", -1.0, 1.0, 0.1],
	"upper_right_seed": ["float", -1.0, 1.0, 0.1],
	"lower_right_seed": ["float", -1.0, 1.0, 0.1],
	"lower_left_seed": ["float", -1.0, 1.0, 0.1],
	"minimum_passes": ["int", 1, 10],
	"maximum_passes": ["int", 1, 10],
	"random_falloff": ["float", 0.0, 1.0,0.01],
	"perform_square_step": ["bool"],
	"perform_diamond_step": ["bool"],
	"palette_smoothness": ["float", 0.0, 1.0, 0.1],
	"random_palette_colors": ["int", 1, 32],
}
var use_random_seeds:bool = true
var minimum_random_seed:float = -0.25 setget set_minimum_random_seed
var maximum_random_seed:float = 0.25 setget set_maximum_random_seed
var upper_left_seed:float = 0.0
var upper_right_seed:float = 0.0
var lower_right_seed:float = 0.0
var lower_left_seed:float = 0.0
var minimum_passes:int = 1 setget set_minimum_passes
var maximum_passes:int = 2 setget set_maximum_passes
var random_falloff:float = 0.25
var perform_square_step:bool = true
var perform_diamond_step:bool = true
var palette_smoothness:float = 0.1
var random_palette_colors:int = 16


func set_minimum_random_seed(value):
	minimum_random_seed = value
	if minimum_random_seed > maximum_random_seed:
		maximum_random_seed = minimum_random_seed
	Global.controls.GenerInspector.update_inspector()


func set_maximum_random_seed(value):
	maximum_random_seed = value
	if maximum_random_seed < minimum_random_seed:
		minimum_random_seed = maximum_random_seed
	Global.controls.GenerInspector.update_inspector()


func set_minimum_passes(value):
	minimum_passes = value
	if minimum_passes > maximum_passes:
		maximum_passes = minimum_passes
	Global.controls.GenerInspector.update_inspector()


func set_maximum_passes(value):
	maximum_passes = value
	if maximum_passes < minimum_passes:
		minimum_passes = maximum_passes
	Global.controls.GenerInspector.update_inspector()


func tiley_gener(size:Vector2, colors:Array = []) -> Image:
	var image := Image.new()
	image.create(round(size.x) as int, round(size.y) as int, false, Image.FORMAT_RGBA8)
	diamond_square(image, colors)
	return image


func diamond_square(image:Image, colors:Array) -> void:
	var map = diamond_square_map(image)
	var palette = colors.duplicate()
	if palette.size() < 1:
		palette.push_back(Color(randf(), randf(), randf(), randf()))
	while palette.size() < random_palette_colors:
		palette.push_back(Color(randf(), randf(), randf(), randf()))
	var color_count:int = palette.size()
	image.lock()
	for x in image.get_width():
		for y in image.get_height():
			# compute distance along palette
			var d:float = color_count * clamp(map[x][y], 0, 1)
			# determine current palette position
			var i:int = min(floor(d) as int, color_count - 1)
			# distance into current position
			d = d - i
			var p := Color(palette[i].r, palette[i].g, palette[i].b, palette[i].a)
			if color_count == 1:
				p.a = d
			elif palette_smoothness > 0.05 and ((d < 0.5 * palette_smoothness) or (d > 1 - 0.5 * palette_smoothness)):
				var q:Color
				if d > 0.5:
					d = 1 - d
					q = palette[i+1] if i < color_count - 2 else palette[color_count - 1]
				else:
					q = palette[i-1] if i > 0 else palette[0]
				var ap:float = 0.5 + d / palette_smoothness
				var aq:float = 0.5 - d / palette_smoothness
				p.r = ap * p.r + aq * q.r
				p.g = ap * p.g + aq * q.g
				p.b = ap * p.b + aq * q.b
			image.set_pixel(x, y, p)
	image.unlock()


func diamond_square_map(image:Image) -> Array:
	var dim = pow(2, ceil(log(image.get_size().x) / log(2))) + 1
	var seeds = [upper_left_seed, upper_right_seed, lower_right_seed, lower_left_seed]
	if use_random_seeds:
		for i in 4:
			seeds[i] = rand_range(minimum_random_seed, maximum_random_seed)
	var map := Map.new(dim, seeds)
	var passes:int = randi() % (maximum_passes - minimum_passes + 1) + minimum_passes
	for i in passes:
		var r := Vector2(rand_range(-0.25, 0.0), rand_range(0.0, 0.5))
		var step_size:int = dim - 1
		while(step_size > 1):
			var x:int = 0
			while(x < dim - 1):
				var y:int = 0
				while(y < dim - 1):
					var x1:int = x + step_size
					var y1:int = y + step_size
					var x2:int = x + step_size / 2
					var y2:int = y + step_size / 2
					# diamond step
					if perform_diamond_step:
						map.setv(x2, y2, (map.map[x][y] + map.map[x][y1] + map.map[x1][y1] + map.map[x1][y]) / 4.0 + rand_range(r.x, r.y))
					# square step
					if perform_square_step:
						var c:float = map.getv(x2, y2)
						var nw:float = map.getv(x, y)
						var ne:float = map.getv(x1, y)
						var sw:float = map.getv(x, y1)
						var se:float = map.getv(x1, y1)
						var nn:float = map.getv(x2, y - step_size / 2)
						var ss:float = map.getv(x2, y1 + step_size / 2)
						var ww:float = map.getv(x - step_size / 2, y2)
						var ee:float = map.getv(x1 + step_size / 2, y2)
						map.setv(x2, y, (c + nw + ne + nn) / 4.0 + rand_range(r.x, r.y)) #up
						map.setv(x2, y1, (c + sw + se + ss) / 4.0 + rand_range(r.x, r.y)) #down
						map.setv(x, y2, (c + nw + sw + ww) / 4.0 + rand_range(r.x, r.y)) #left
						map.setv(x1, y2, (c + ne + se + ee) / 4.0 + rand_range(r.x, r.y)) #right
					r = (1 - random_falloff) * r
					y += step_size
				x += step_size
			step_size /= 2
	map.normalize(-0.25, 1.0)
	return map.map


class Map:
	
	var dim:int
	var bound:int
	var map:Array = []
	

	func _init(dimen:int, seeds:Array = []) -> void:
		dim = dimen
		bound = dim - 1
		for i in dim:
			map.push_back([])
			for j in dim:
				map[i].push_back(0.0)
		while seeds.size() < 4:
			seeds.push_back(0.0)
		map[0][0] = seeds[0]
		map[0][bound] = seeds[1]
		map[bound][bound] = seeds[2]
		map[bound][0] = seeds[3]


	func getv(x:int, y:int) -> float:
		if x > bound:
			x -= dim
		elif x < 0:
			x += dim
		if y > bound:
			y -= dim
		elif y < 0:
			y += dim
		return map[x][y]


	func setv(x:int, y:int, v:float) -> void:
		map[x][y] = v
	
	
	func normalize(lo:float = 0.0, hi:float = 1.0) -> void:
		var map_lo:float = map[0][0]
		var map_hi:float = map[0][0]
		for i in dim:
			for j in dim:
				if map[i][j] < map_lo:
					map_lo = map[i][j]
				if map[i][j] > map_hi:
					map_hi = map[i][j]
		var scale:float = abs(hi - lo) / abs(map_hi - map_lo)
		for i in map.size():
			for j in map[i].size():
				map[i][j] = scale * (map[i][j] - map_lo) + lo
