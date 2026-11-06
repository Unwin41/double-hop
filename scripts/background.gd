extends Parallax2D
## Parallax sky built from Kenney's 24x24 background tiles.
## The tiles are composed into one seamless strip at startup; Parallax2D
## repeats it forever, scrolls it slower than the camera and pins it to the
## screen vertically. Menus use `autoscroll` instead of a camera.

const BG_TEXTURE := preload("res://assets/sprites/backgrounds.png")
const TILE := 24
const SHEET_COLUMNS := 8
const THEMES := [
	{"top": 0, "band": [8, 9, 8, 10, 11, 8, 10, 9], "bottom": 16},  # pale sky, clouds
	{"top": 4, "band": [12, 12, 13, 12, 13], "bottom": 20},  # warm sunset hills
	{"top": 6, "band": [14, 15, 14, 14, 15], "bottom": 22},  # green forest
]
const BOTTOM_ROWS := 3
const SCREEN_ROWS := 9  # 9 x 24 px = 216 px, the game's height

@export_range(0, 2) var theme_index := 0


func _ready() -> void:
	var strip := _build_strip()
	var sprite := Sprite2D.new()
	sprite.texture = strip
	sprite.centered = false
	add_child(sprite)
	repeat_size = Vector2(strip.get_width(), 0)
	repeat_times = 3


## One full repeat of the theme's band pattern, as tall as the screen.
func _build_strip() -> ImageTexture:
	var theme: Dictionary = THEMES[theme_index]
	var band: Array = theme["band"]
	var band_row := SCREEN_ROWS - BOTTOM_ROWS - 1
	var sheet := BG_TEXTURE.get_image()
	sheet.convert(Image.FORMAT_RGBA8)
	var image := Image.create_empty(band.size() * TILE, SCREEN_ROWS * TILE, false, Image.FORMAT_RGBA8)
	for c in band.size():
		for r in SCREEN_ROWS:
			var tile_id: int = theme["top"]
			if r == band_row:
				tile_id = band[c]
			elif r > band_row:
				tile_id = theme["bottom"]
			var src := Rect2i((tile_id % SHEET_COLUMNS) * TILE, (tile_id / SHEET_COLUMNS) * TILE, TILE, TILE)
			image.blit_rect(sheet, src, Vector2i(c * TILE, r * TILE))
	return ImageTexture.create_from_image(image)
