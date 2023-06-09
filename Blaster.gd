extends Sprite2D

enum comparisonModes {rgbDist, hsvDist, h}
var image = preload("res://Flame3.png")
var output : Image
var palette : Array[Color] = [
	Color("c3ff20"),
	Color("ffa800"),
	Color("ff1429"),
	Color("ffdf00"),
]
@onready var count = 0

## Called when the node enters the scene tree for the first time.
#func _ready():
#	print(xcoords(2, 5, Vector2i(8,6), 2))

func _process(_delta):
	var processed : bool = true
	match count:
		0:
			output = force_image_to_palette(image, palette, comparisonModes.rgbDist)
		1:
			output = fix_stray_pixels(output, 8, 1)
		2:
			output = fix_stray_pixels(output, 19, 2)
		3:
			basic_fix(output, 1)
		4:
			basic_fix(output, 1)
		5:
			output = fix_stray_pixels(output, 7, 1)
		6:
			output = fix_stray_pixels(output, 5, 1)
		7:
			output = fix_stray_pixels(output, 5, 1)
		8:
			basic_fix(output, 1)
		9:
			output = fix_stray_pixels(output, 20, 2)
		10:
			basic_fix(output, 1)
		11:
			basic_fix(output, 1)
		12:
			output = fix_stray_pixels(output, 20, 2)
		13:
			output = fix_stray_pixels(output, 20, 2)
		14:
			basic_fix(output, 1)
		15:
			print("finished")
		_:
			processed = false
			
	if processed:
		print("Step: " + str(count))
		output.save_png("test.png")
		set_screen_to_texture(output)
		count = count + 1

func force_image_to_palette(img : Image, pal : Array[Color], method : comparisonModes):
	var sx = img.get_size().x
	var sy = img.get_size().y
	var out = Image.create(sx, sy,false, Image.FORMAT_RGBA8)
	for x in sx:
		for y in sy:
			out.set_pixel(x, y, find_closest_color_to_palette(img.get_pixel(x,y), pal, method))
	return out

func basic_fix(out : Image, iterations : int):
	for i in iterations:
		out = fix_stray_pixels(out, 5, 1)
		out = fix_stray_pixels(out, 6, 1)
		out = fix_stray_pixels(out, 7, 1)
		out = fix_stray_pixels(out, 8, 1)

#Image must align with palette.
func fix_stray_pixels(img: Image, threshold : int, radius : int) -> Image:
	var sx = img.get_size().x
	var sy = img.get_size().y
	var out = Image.create(sx, sy, false, Image.FORMAT_RGBA8)
	for x in sx:
		for y in sy:
			var colorArr : Array[Color] = []
			var colorAmount : Array[int] = []
			var currentPix = img.get_pixel(x,y)
			var counter : int = 0
			for coord in xcoords(x,y,img.get_size(),radius):
				var pixCoord : Color = img.get_pixel(coord.x, coord.y)
				if is_zero_approx(pixCoord.a):
					counter += 1
				elif !is_rgb_equal_approx(pixCoord, currentPix):
					pixCoord.a = 1.0
					counter += 1
					var index = colorArr.find(pixCoord)
					if index == -1:
						colorArr.push_back(pixCoord)
						colorAmount.push_back(1)
					else:
						colorAmount[index] += 1
				
			var getPix : Color = img.get_pixel(x,y)
			if counter < threshold:
				out.set_pixel(x,y,getPix)
			else:
				if colorAmount.size() == 0:
					out.set_pixel(x,y, Color.TRANSPARENT)
				else:
					var index = 0
					var finalIndex = 0
					var value : float = 0
					for i in colorAmount:
						if i > value:
							value = i
							finalIndex = index
						index += 1
					var outColor : Color = colorArr[finalIndex]
					outColor.a = getPix.a
					out.set_pixel(x,y, outColor)
	return out

func is_rgb_equal_approx(col1 : Color, col2 : Color) -> bool:
	return is_equal_approx(col1.r, col2.r) && is_equal_approx(col1.g, col2.g) && is_equal_approx(col1.b, col2.b)


#Returns the 8 coordinates around a pixel
func orthogonal_coords(x : int, y: int, imSize : Vector2i) -> Array[Vector2i]:
	var yplus = wrapi(y+1, 0, imSize.y)
	var xplus = wrapi(x+1, 0, imSize.x)
	var ymin = wrapi(y-1, 0, imSize.y)
	var xmin = wrapi(x-1, 0, imSize.x)
	var Arr : Array[Vector2i] = [Vector2i(x, yplus)]
	Arr.push_back(Vector2i(x, ymin))
	Arr.push_back(Vector2i(xplus, y))
	Arr.push_back(Vector2i(xmin, y))
	Arr.push_back(Vector2i(xplus, yplus))
	Arr.push_back(Vector2i(xplus, ymin))
	Arr.push_back(Vector2i(xmin, yplus))
	Arr.push_back(Vector2i(xmin, ymin))
	return Arr

#Returns the coordinates of the surrounding square of pixels
func xcoords(x : int, y: int, imSize : Vector2i, radius : int) -> Array[Vector2i]:
	if radius == 0:
		return []
	if radius == 1:
		return orthogonal_coords(x,y,imSize)
	var Arr : Array[Vector2i] = []
	var xPoints : Array[int] = []
	var yPoints : Array[int] = []
	for i in range(-radius, radius + 1):
		xPoints.push_back(wrapi(x+i, 0, imSize.x))
		yPoints.push_back(wrapi(y+i, 0, imSize.y))
	for xi in xPoints:
		for yi in yPoints:
			if xi != x || yi != y:
				Arr.push_back(Vector2i(xi,yi))
	return Arr


func generate_texture(img : Image):
	return ImageTexture.create_from_image(img)

func set_screen_to_texture(img : Image):
	texture = generate_texture(img)
	DisplayServer.window_set_size(img.get_size())

func find_closest_color_to_palette(col : Color, pal : Array[Color], method : comparisonModes) -> Color:
	if col.a <= 0.035:
		return Color(1.0, 1.0, 1.0, 0.0)
	var val : float = -1.0
	var ret : Color
	for c in pal:
		var comparison : float = compare_colors(col, c, method)
		if val == -1.0 || comparison < val:
			val = comparison
			#print(val)
			ret = c
	ret.a = col.a
	return ret

func compare_rgb_distance(col1 : Color, col2 : Color) -> float:
	return Vector3(col1.r-col2.r,col1.g-col2.g,col1.b-col2.b).length_squared()

func compare_hsv_distance(col1 : Color, col2 : Color) -> float:
	return Vector3((col1.h-col2.h)*3.0,col1.s-col2.s,col1.v-col2.v).length_squared()

func compare_h(col1 : Color, col2 : Color) -> float:
	return abs(col1.h-col2.h)

func compare_colors(col1 : Color, col2 : Color, method : comparisonModes) -> float:
	match method:
		comparisonModes.rgbDist:
			return compare_rgb_distance(col1, col2)
		comparisonModes.hsvDist:
			return compare_hsv_distance(col1, col2)
		comparisonModes.h:
			return compare_h(col1, col2)
	return compare_rgb_distance(col1, col2)
