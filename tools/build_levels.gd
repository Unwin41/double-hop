extends Node
## Level builder. Turns the ASCII maps in tools/levels/*.txt into the TileSet
## resource and the level scenes in scenes/levels/.
##
## Run from the project folder:
##   godot --headless --path . res://tools/build_levels.tscn
##
## Map legend (one character = one 18x18 tile):
##   #  ground (auto-tiled grass/dirt)     =  cloud platform (jump through)
##   ^  floor spikes                       v  ceiling spikes
##   c  coin                               g  refill gem (gives the air jump back)
##   P  Pip's start                        F  goal flag (stands on the tile below)
##   e  walking blob                       b  flying bat
##   *  decoration plant                   1-9  hint text from the header

const TILE := 18
const ATLAS_COLUMNS := 20
const TILESET_PATH := "res://assets/tileset.tres"
const LEVEL_SOURCE_DIR := "res://tools/levels/"
const LEVEL_OUTPUT_DIR := "res://scenes/levels/"
const BAT_RANGE := 5
const HINT_WIDTH := 220.0

# Ground auto-tiling, indexed by [top_open][bottom_open] then [left_open][right_open].
const GROUND_TOP := {false: {false: 2, true: 3}, true: {false: 1, true: 20}}
const GROUND_TOP_FLOATING := {false: {false: 22, true: 23}, true: {false: 21, true: 0}}
const GROUND_FILL := {false: {false: 122, true: 123}, true: {false: 121, true: 120}}
const GROUND_BOTTOM := {false: {false: 142, true: 143}, true: {false: 141, true: 140}}
const CLOUD_SINGLE := 156
const CLOUD_LEFT := 153
const CLOUD_MIDDLE := 154
const CLOUD_RIGHT := 155
const DECOR_TILES := [124, 125, 144, 148, 124, 125]

const SCENES := {
	"c": preload("res://scenes/objects/coin.tscn"),
	"g": preload("res://scenes/objects/refill_gem.tscn"),
	"^": preload("res://scenes/objects/spike.tscn"),
	"v": preload("res://scenes/objects/spike.tscn"),
	"F": preload("res://scenes/objects/goal.tscn"),
	"e": preload("res://scenes/objects/blob.tscn"),
	"b": preload("res://scenes/objects/bat.tscn"),
}
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const LEVEL_SCRIPT := preload("res://scripts/level.gd")
const BACKGROUND_SCRIPT := preload("res://scripts/background.gd")


func _ready() -> void:
	var tile_set := _build_tile_set()
	var err := ResourceSaver.save(tile_set, TILESET_PATH)
	if err != OK:
		_fail("could not save tileset (%d)" % err)
		return
	tile_set = load(TILESET_PATH)
	var files := DirAccess.get_files_at(LEVEL_SOURCE_DIR)
	files.sort()
	for file in files:
		if file.ends_with(".txt"):
			if not _build_level(LEVEL_SOURCE_DIR + file, tile_set):
				_fail("failed on " + file)
				return
	print("build_levels: done")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("build_levels: " + message)
	get_tree().quit(1)


# --- TileSet ------------------------------------------------------------------

func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)
	var source := TileSetAtlasSource.new()
	source.texture = load("res://assets/sprites/tiles.png")
	source.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(source, 0)
	var half := TILE / 2.0
	var full_box := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	var cloud_box := PackedVector2Array([
		Vector2(-half, -half + 1), Vector2(half, -half + 1), Vector2(half, -half + 6), Vector2(-half, -half + 6)])
	var solid_ids: Array = []
	for table: Dictionary in [GROUND_TOP, GROUND_TOP_FLOATING, GROUND_FILL, GROUND_BOTTOM]:
		for row: Dictionary in table.values():
			solid_ids.append_array(row.values())
	for id: int in solid_ids:
		_add_tile(source, id, full_box, false)
	for id: int in [CLOUD_SINGLE, CLOUD_LEFT, CLOUD_MIDDLE, CLOUD_RIGHT]:
		_add_tile(source, id, cloud_box, true)
	for id: int in DECOR_TILES:
		_add_tile(source, id, PackedVector2Array(), false)
	return tile_set


func _add_tile(source: TileSetAtlasSource, id: int, polygon: PackedVector2Array, one_way: bool) -> void:
	var coords := _atlas(id)
	if source.has_tile(coords):
		return
	source.create_tile(coords)
	if polygon.is_empty():
		return
	var data := source.get_tile_data(coords, 0)
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, polygon)
	data.set_collision_polygon_one_way(0, 0, one_way)


func _atlas(id: int) -> Vector2i:
	return Vector2i(id % ATLAS_COLUMNS, id / ATLAS_COLUMNS)


# --- Level parsing ------------------------------------------------------------

func _build_level(path: String, tile_set: TileSet) -> bool:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("build_levels: empty or missing " + path)
		return false
	var parts := text.split("---\n", true, 1)
	if parts.size() != 2:
		push_error("build_levels: %s needs a header, a '---' line, then the map" % path)
		return false
	var meta := _parse_header(parts[0])
	var rows: PackedStringArray = parts[1].rstrip("\n").split("\n")
	var map := _Map.new(rows)

	var root := Node2D.new()
	root.name = "Level"
	root.set_script(LEVEL_SCRIPT)
	root.set("level_name", meta.get("name", "Level"))

	var sky := Parallax2D.new()
	sky.name = "Sky"
	sky.set_script(BACKGROUND_SCRIPT)
	sky.scroll_scale = Vector2(0.3, 0.0)
	sky.set("theme_index", int(meta.get("theme", "0")))
	_add(root, root, sky)

	var decor := _make_layer("Decor", tile_set)
	_add(root, root, decor)
	var ground := _make_layer("Ground", tile_set)
	_add(root, root, ground)
	var hints := Node2D.new()
	hints.name = "Hints"
	_add(root, root, hints)
	var objects := Node2D.new()
	objects.name = "Objects"
	_add(root, root, objects)

	var player_count := 0
	var goal_count := 0
	for y in map.height:
		for x in map.width:
			var ch := map.at(x, y)
			match ch:
				" ", ".":
					pass
				"#":
					ground.set_cell(Vector2i(x, y), 0, _atlas(_ground_tile(map, x, y)))
				"=":
					ground.set_cell(Vector2i(x, y), 0, _atlas(_cloud_tile(map, x, y)))
				"*":
					decor.set_cell(Vector2i(x, y), 0, _atlas(DECOR_TILES[(x * 7 + y * 3) % DECOR_TILES.size()]))
				"P":
					var player := PLAYER_SCENE.instantiate()
					player.position = Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE - 8)
					player_count += 1
					_add(root, root, player)
				_:
					if ch.is_valid_int():
						_add(root, hints, _make_hint(meta.get("hint " + ch, "?"), x, y))
					elif SCENES.has(ch):
						if ch == "F":
							goal_count += 1
						_add(root, objects, _make_object(ch, map, x, y))
					else:
						push_error("build_levels: unknown map character '%s' at %d,%d in %s" % [ch, x, y, path])
						return false
	# Side walls keep Pip inside the map.
	for y in range(-4, map.height):
		ground.set_cell(Vector2i(-1, y), 0, _atlas(GROUND_FILL[false][false]))
		ground.set_cell(Vector2i(map.width, y), 0, _atlas(GROUND_FILL[false][false]))
	if player_count != 1 or goal_count != 1:
		push_error("build_levels: %s needs exactly one P and one F (found %d, %d)" % [path, player_count, goal_count])
		return false

	_add(root, root, HUD_SCENE.instantiate())
	_add(root, root, PAUSE_SCENE.instantiate())

	var scene := PackedScene.new()
	var err := scene.pack(root)
	if err == OK:
		var out := LEVEL_OUTPUT_DIR + path.get_file().get_basename() + ".tscn"
		err = ResourceSaver.save(scene, out)
		print("build_levels: %s  (%dx%d, %d coins)" % [out, map.width, map.height, map.count("c")])
	root.free()
	return err == OK


func _parse_header(header: String) -> Dictionary:
	var meta := {}
	for line in header.split("\n", false):
		var kv := line.split(":", true, 1)
		if kv.size() == 2:
			meta[kv[0].strip_edges()] = kv[1].strip_edges()
	return meta


func _add(owner_node: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = owner_node


func _make_layer(layer_name: String, tile_set: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	return layer


func _make_hint(text: String, x: int, y: int) -> Label:
	var label := Label.new()
	label.name = "Hint"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(HINT_WIDTH, 10)
	label.position = Vector2(maxf(x * TILE + TILE / 2.0 - HINT_WIDTH / 2.0, 4.0), y * TILE + 4)
	return label


func _make_object(ch: String, map: _Map, x: int, y: int) -> Node2D:
	var node: Node2D = SCENES[ch].instantiate()
	node.position = Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
	match ch:
		"v":
			node.rotation = PI
		"e":
			var span := map.walk_span(x, y)
			node.set("min_x", span.x * TILE + TILE / 2.0)
			node.set("max_x", span.y * TILE + TILE / 2.0)
		"b":
			var span := map.fly_span(x, y, BAT_RANGE)
			node.set("min_x", span.x * TILE + TILE / 2.0)
			node.set("max_x", span.y * TILE + TILE / 2.0)
	return node


func _ground_tile(map: _Map, x: int, y: int) -> int:
	var top_open := not map.is_ground(x, y - 1)
	var bottom_open := not map.is_ground(x, y + 1)
	var left_open := not map.is_ground(x - 1, y)
	var right_open := not map.is_ground(x + 1, y)
	var table: Dictionary
	if top_open:
		table = GROUND_TOP_FLOATING if bottom_open else GROUND_TOP
	else:
		table = GROUND_BOTTOM if bottom_open else GROUND_FILL
	return table[left_open][right_open]


func _cloud_tile(map: _Map, x: int, y: int) -> int:
	var left := map.at(x - 1, y) == "="
	var right := map.at(x + 1, y) == "="
	if left and right:
		return CLOUD_MIDDLE
	if right:
		return CLOUD_LEFT
	if left:
		return CLOUD_RIGHT
	return CLOUD_SINGLE


class _Map:
	var rows: PackedStringArray
	var width := 0
	var height := 0

	func _init(source_rows: PackedStringArray) -> void:
		rows = source_rows
		height = rows.size()
		for row in rows:
			width = maxi(width, row.length())

	func at(x: int, y: int) -> String:
		if y < 0 or y >= height or x < 0 or x >= rows[y].length():
			return " "
		return rows[y][x]

	## Out of bounds counts as ground on the sides and below (no outlines there).
	func is_ground(x: int, y: int) -> bool:
		if y < 0:
			return false
		if x < 0 or x >= width or y >= height:
			return true
		return at(x, y) == "#"

	func is_standable(x: int, y: int) -> bool:
		var below := at(x, y + 1)
		return (below == "#" or below == "=") and not is_ground(x, y)

	func is_blocked(x: int, y: int) -> bool:
		return x < 0 or x >= width or at(x, y) == "#"

	func walk_span(x: int, y: int) -> Vector2i:
		var left := x
		while left - 1 >= 0 and is_standable(left - 1, y) and at(left - 1, y) != "^":
			left -= 1
		var right := x
		while right + 1 < width and is_standable(right + 1, y) and at(right + 1, y) != "^":
			right += 1
		return Vector2i(left, right)

	func fly_span(x: int, y: int, max_range: int) -> Vector2i:
		var left := x
		while left - 1 >= 0 and x - (left - 1) <= max_range and not is_blocked(left - 1, y):
			left -= 1
		var right := x
		while right + 1 < width and (right + 1) - x <= max_range and not is_blocked(right + 1, y):
			right += 1
		return Vector2i(left, right)

	func count(ch: String) -> int:
		var total := 0
		for row in rows:
			total += row.count(ch)
		return total
