extends CanvasLayer
## Map HUD overlay built from extracted PS2 UI sprite assets.
## Uses AtlasTexture regions from story_sys01.png, story_sys02.png, dp_font00.png.
## Reference: /tmp/hud_reference.png (PS2 gameplay capture)

const SYS01 := preload("res://assets/tagforce/backgrounds/field/base/story_sys01.png")
const SYS02 := preload("res://assets/tagforce/backgrounds/field/base/story_sys02.png")
const DP_FONT := preload("res://assets/tagforce/backgrounds/field/base/dp_font00.png")

# UI scale — sprites are PSP native, viewport is 640x480 (1:1 native pixel scale)
const S := 1.0

# -- Atlas regions: story_sys02.png (date/calendar text) --

# Day names [0=Sun .. 6=Sat]
const R_DAYS: Array[Rect2] = [
	Rect2(6, 0, 57, 20), Rect2(88, 0, 62, 20), Rect2(170, 0, 64, 20),
	Rect2(244, 0, 72, 20), Rect2(6, 20, 71, 20), Rect2(87, 20, 53, 20),
	Rect2(170, 20, 70, 20),
]
# Month names [0=May .. 3=August]
const R_MONTHS: Array[Rect2] = [
	Rect2(9, 81, 43, 22), Rect2(89, 81, 47, 20),
	Rect2(9, 105, 43, 22), Rect2(90, 105, 60, 22),
]
# Teal digits 0-9
const R_DIGITS: Array[Rect2] = [
	Rect2(242, 82, 17, 21), Rect2(265, 82, 11, 21), Rect2(282, 82, 17, 21),
	Rect2(301, 82, 18, 21), Rect2(321, 82, 18, 21), Rect2(342, 83, 17, 20),
	Rect2(361, 82, 18, 21), Rect2(381, 83, 18, 20), Rect2(401, 82, 18, 21),
	Rect2(421, 82, 17, 21),
]
# Ordinal suffixes [0=st, 1=nd, 2=rd, 3=th]
const R_SUFFIXES: Array[Rect2] = [
	Rect2(164, 107, 24, 19), Rect2(196, 105, 25, 21),
	Rect2(228, 105, 24, 21), Rect2(259, 105, 25, 21),
]
const R_DAYS_TEXT := Rect2(101, 41, 44, 18)
const R_UNTIL_TOURNAMENT := Rect2(3, 61, 143, 18)

# -- Atlas regions: story_sys01.png (time/icons) --

const R_CLOCK_FACE := Rect2(0, 50, 60, 53)
const R_CLOCK_HAND_HOUR := Rect2(66, 61, 4, 16)
const R_DP_LABEL := Rect2(10, 3, 30, 20)
const R_COLON := Rect2(147, 7, 9, 16)
# Gold digits 0-9 (for time display)
const R_GOLD: Array[Rect2] = [
	Rect2(160, 3, 16, 20), Rect2(179, 3, 11, 20), Rect2(192, 3, 16, 20),
	Rect2(208, 3, 16, 20), Rect2(224, 3, 16, 20), Rect2(240, 3, 16, 20),
	Rect2(256, 3, 16, 20), Rect2(272, 3, 16, 20), Rect2(288, 3, 16, 20),
	Rect2(304, 3, 16, 20),
]
# Teal bar backgrounds
const R_BAR_TOP := Rect2(242, 73, 270, 29)
const R_BAR_BTM := Rect2(279, 103, 233, 23)

# -- Node references (built in _build_hud) --

var _location_name: String = ""
var _loc_label: Label  # Label for dynamic location text
var _day_spr: Sprite2D
var _month_spr: Sprite2D
var _suffix_spr: Sprite2D
var _days_text_spr: Sprite2D
var _until_spr: Sprite2D
var _dp_label_spr: Sprite2D
var _clock_pivot: Node2D  # rotate for hour hand
var _date_digits: Array[Sprite2D] = []
var _time_digits: Array[Sprite2D] = []
var _time_colon: Sprite2D
var _dp_digits: Array[Sprite2D] = []
var _countdown_digits: Array[Sprite2D] = []


func _ready() -> void:
	_build_hud()
	_update_display()
	TimeManager.time_changed.connect(_on_time_changed)


func set_location(loc_name: String) -> void:
	_location_name = loc_name
	if _loc_label:
		_loc_label.text = loc_name


# -- Sprite helpers --

func _atlas(tex: Texture2D, region: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = region
	return a


func _spr(tex: Texture2D, region: Rect2, pos: Vector2, parent: Node) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = _atlas(tex, region)
	sp.centered = false
	sp.scale = Vector2(S, S)
	sp.position = pos
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(sp)
	return sp


func _set_region(sp: Sprite2D, tex: Texture2D, region: Rect2) -> void:
	sp.texture = _atlas(tex, region)


## Lay out a number as digit sprites. Returns the x position after the last digit.
func _lay_digits(digits_arr: Array[Sprite2D], value: int, regions: Array[Rect2],
		tex: Texture2D, x0: float, y: float) -> float:
	var s := str(value)
	var x := x0
	for i in range(digits_arr.size()):
		if i < s.length():
			var d := int(s[i])
			_set_region(digits_arr[i], tex, regions[d])
			digits_arr[i].position = Vector2(x, y)
			digits_arr[i].visible = true
			x += regions[d].size.x * S + 1
		else:
			digits_arr[i].visible = false
	return x


# -- Build the HUD --

func _build_hud() -> void:
	var root := Node2D.new()
	add_child(root)

	# === Location panel (top-left) ===
	# Use a PanelContainer with olive/gold style + Label for dynamic text
	var loc_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.08, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.78, 0.68, 0.22, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	loc_panel.add_theme_stylebox_override("panel", style)
	loc_panel.offset_left = 6
	loc_panel.offset_top = 4
	loc_panel.offset_right = 120
	loc_panel.offset_bottom = 22
	add_child(loc_panel)

	_loc_label = Label.new()
	_loc_label.add_theme_font_size_override("font_size", 11)
	_loc_label.add_theme_color_override("font_color", Color.WHITE)
	loc_panel.add_child(_loc_label)

	# === Right HUD panel ===
	var rp := Node2D.new()
	add_child(rp)

	# Teal bar backgrounds (right-aligned for 640x480 viewport)
	_spr(SYS01, R_BAR_TOP, Vector2(370, 3), rp)
	_spr(SYS01, R_BAR_BTM, Vector2(407, 22), rp)

	# Clock face
	var clock_center := Vector2(608, 22)
	var clock_face := _spr(SYS01, R_CLOCK_FACE, Vector2.ZERO, rp)
	clock_face.centered = true
	clock_face.position = clock_center

	# Clock hour hand (rotates around clock center)
	_clock_pivot = Node2D.new()
	_clock_pivot.position = clock_center
	rp.add_child(_clock_pivot)
	var hand_spr := Sprite2D.new()
	hand_spr.texture = _atlas(SYS01, R_CLOCK_HAND_HOUR)
	hand_spr.scale = Vector2(S, S)
	hand_spr.centered = false
	hand_spr.offset = Vector2(-2, -16)  # pivot at bottom-center, extends up
	hand_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_clock_pivot.add_child(hand_spr)

	# Date digits (max 2: e.g. "31")
	for i in 2:
		_date_digits.append(_spr(SYS02, R_DIGITS[0], Vector2.ZERO, rp))
	# Ordinal suffix (st/nd/rd/th)
	_suffix_spr = _spr(SYS02, R_SUFFIXES[0], Vector2.ZERO, rp)
	# Month name
	_month_spr = _spr(SYS02, R_MONTHS[0], Vector2.ZERO, rp)

	# Day name
	_day_spr = _spr(SYS02, R_DAYS[0], Vector2.ZERO, rp)

	# Time digits (4) + colon
	for i in 4:
		_time_digits.append(_spr(SYS01, R_GOLD[0], Vector2.ZERO, rp))
	_time_colon = _spr(SYS01, R_COLON, Vector2.ZERO, rp)

	# DP digits (max 5) + "DP" label
	for i in 5:
		_dp_digits.append(_spr(SYS01, R_GOLD[0], Vector2.ZERO, rp))
	_dp_label_spr = _spr(SYS01, R_DP_LABEL, Vector2.ZERO, rp)

	# Countdown digits (max 3) + "Days" label
	for i in 3:
		_countdown_digits.append(_spr(SYS02, R_DIGITS[0], Vector2.ZERO, rp))
	_days_text_spr = _spr(SYS02, R_DAYS_TEXT, Vector2.ZERO, rp)

	# "Until Tournament"
	_until_spr = _spr(SYS02, R_UNTIL_TOURNAMENT, Vector2.ZERO, rp)


func _update_display() -> void:
	if not is_inside_tree():
		return

	# Location
	if _loc_label:
		_loc_label.text = _location_name

	var day_num: int = TimeManager.day_number if TimeManager else 1
	var day_of_month := ((day_num - 1) % 30) + 1
	var month_idx: int = clampi((day_num - 1) / 30, 0, R_MONTHS.size() - 1)
	var day_index: int = (day_num - 1) % 7

	# -- Date line: "8th May" at y=6 --
	var dx := _lay_digits(_date_digits, day_of_month, R_DIGITS, SYS02, 380, 6)
	# Suffix
	var suffix_idx := _get_suffix_index(day_of_month)
	_set_region(_suffix_spr, SYS02, R_SUFFIXES[suffix_idx])
	_suffix_spr.position = Vector2(dx + 1, 8)
	dx = dx + 1 + R_SUFFIXES[suffix_idx].size.x * S
	# Month
	_set_region(_month_spr, SYS02, R_MONTHS[month_idx])
	_month_spr.position = Vector2(dx + 4, 6)

	# -- Day name at y=24 --
	_set_region(_day_spr, SYS02, R_DAYS[day_index])
	_day_spr.position = Vector2(385, 24)

	# -- Time at y=42 (gold digits) --
	var time_of_day: String = TimeManager.time_of_day if TimeManager else "day"
	var hour: int = 8
	match time_of_day:
		"day": hour = 12
		"sunset": hour = 17
		"night": hour = 21
	var h1 := hour / 10
	var h2 := hour % 10
	var tx := 470.0
	if h1 > 0:
		_set_region(_time_digits[0], SYS01, R_GOLD[h1])
		_time_digits[0].position = Vector2(tx, 42)
		_time_digits[0].visible = true
		tx += R_GOLD[h1].size.x * S + 1
	else:
		_time_digits[0].visible = false
	_set_region(_time_digits[1], SYS01, R_GOLD[h2])
	_time_digits[1].position = Vector2(tx, 42)
	tx += R_GOLD[h2].size.x * S + 1
	# Colon
	_time_colon.position = Vector2(tx, 44)
	tx += R_COLON.size.x * S + 1
	# Minutes (always 00)
	_set_region(_time_digits[2], SYS01, R_GOLD[0])
	_time_digits[2].position = Vector2(tx, 42)
	tx += R_GOLD[0].size.x * S + 1
	_set_region(_time_digits[3], SYS01, R_GOLD[0])
	_time_digits[3].position = Vector2(tx, 42)

	# Clock hand rotation (360° / 12 hours)
	if _clock_pivot:
		_clock_pivot.rotation_degrees = (hour % 12) * 30.0

	# -- DP at y=57 (gold digits + "DP" label) --
	var dp: int = GameManager.game_data.get("dp", 0) if GameManager else 0
	var dpx := _lay_digits(_dp_digits, dp, R_GOLD, SYS01, 480, 57)
	_dp_label_spr.position = Vector2(dpx + 3, 57)

	# -- Days countdown at y=72 --
	var tournament_day: int = GameManager.game_data.get("tournament_day", 92) if GameManager else 92
	var days_left: int = maxi(tournament_day - day_num, 0)
	var cdx := _lay_digits(_countdown_digits, days_left, R_DIGITS, SYS02, 455, 72)
	_days_text_spr.position = Vector2(cdx + 3, 74)

	# "Until Tournament" below
	_until_spr.position = Vector2(425, 87)


func _get_suffix_index(day: int) -> int:
	if day >= 11 and day <= 13:
		return 3  # th
	match day % 10:
		1: return 0  # st
		2: return 1  # nd
		3: return 2  # rd
		_: return 3  # th


func _on_time_changed(_new_time: String) -> void:
	_update_display()
