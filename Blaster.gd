extends Sprite2D

enum comparisonModes {rgbDist, hsvDist, h}

var palette : Array[Color] = [
	Color("c3ff20"),
	Color("ffa800"),
	Color("ff1429"),
	Color("ffdf00"),
]

# Called when the node enters the scene tree for the first time.
func _ready():
	var img = load("res://Flame3.png")
	var out = force_image_to_palette(img, palette, comparisonModes.rgbDist)
#	out = fix_stray_pixels(out, 6)
#	for i in 2:
#		out = fix_stray_pixels(out, 7)
	out = fix_stray_pixels(out, 8)
	out.save_png("test.png")
	set_screen_to_texture(out)
	#print(compare_rgb_distance(Color.GREEN_YELLOW, Color.BROWN))

func force_image_to_palette(img : Image, pal : Array[Color], method : comparisonModes):
	var sx = img.get_size().x
	var sy = img.get_size().y
	var out = Image.create(sx, sy,false, Image.FORMAT_RGBA8)
	for x in sx:
		for y in sy:
			out.set_pixel(x, y, find_closest_color_to_palette(img.get_pixel(x,y), pal, method))
	return out

#Image must align with palette.
func fix_stray_pixels(img: Image, threshold : int) -> Image:
	var sx = img.get_size().x
	var sy = img.get_size().y
	var out = Image.create(sx, sy, false, Image.FORMAT_RGBA8)
	for x in sx:
		for y in sy:
			var colorArr : Array[Color] = []
			var colorAmount : Array[int] = []
			var currentPix = img.get_pixel(x,y)
			var counter : int = 0
			for coord in orthogonal_coords(x,y,img.get_size()):
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
	var yplus = wrapi(y+1, 1, imSize.y)
	var xplus = wrapi(x+1, 1, imSize.x)
	var ymin = wrapi(y-1, 1, imSize.y)
	var xmin = wrapi(x-1, 1, imSize.x)
	var Arr : Array[Vector2i] = [Vector2i(x, yplus)]
	Arr.push_back(Vector2i(x, ymin))
	Arr.push_back(Vector2i(xplus, y))
	Arr.push_back(Vector2i(xmin, y))
	Arr.push_back(Vector2i(xplus, yplus))
	Arr.push_back(Vector2i(xplus, ymin))
	Arr.push_back(Vector2i(xmin, yplus))
	Arr.push_back(Vector2i(xmin, ymin))
	
	return Arr



func generate_texture(image : Image):
	return ImageTexture.create_from_image(image)

func set_screen_to_texture(image : Image):
	texture = generate_texture(image)
	DisplayServer.window_set_size(image.get_size())

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
