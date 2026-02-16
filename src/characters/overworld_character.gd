extends Node2D
## Overworld character using SLA + VER spritesheets for 8-direction movement.
## Each sheet: 512x256, 28 frames (7 per direction) in 3 rows of 10 cols.
## VER = cardinal (S, W, N, E). SLA = diagonal (SW, NW, NE, SE).

@export var sprite_path: String = ""
@export var character_id: String = ""
@export var walk_speed: float = 60.0

enum Direction { S = 0, SW = 1, W = 2, NW = 3, N = 4, NE = 5, E = 6, SE = 7 }

const FRAME_W := 51
const FRAME_H := 85
const COLS := 10
const FRAMES_PER_DIR := 7

const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const SHADOW_RADIUS := Vector2(12.0, 6.0)
const SHADOW_OFFSET_Y := 30.0  # Centered on character's feet
const IDLE_FRAME := 6  # 7th frame (0-indexed) is the standing pose

var current_direction: int = Direction.S
var is_moving: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer

var _frame: int = 0
var _tex_ver: Texture2D  # Cardinal (S, W, N, E)
var _tex_sla: Texture2D  # Diagonal (SW, NW, NE, SE)


func _ready() -> void:
	anim_timer.timeout.connect(_advance_frame)


func _draw() -> void:
	var points := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		points.append(Vector2(cos(angle) * SHADOW_RADIUS.x,
							  sin(angle) * SHADOW_RADIUS.y + SHADOW_OFFSET_Y))
	draw_colored_polygon(points, SHADOW_COLOR)


func load_sprites(ver_path: String, sla_path: String) -> void:
	_tex_ver = null
	_tex_sla = null
	if not ver_path.is_empty() and ResourceLoader.exists(ver_path):
		_tex_ver = load(ver_path) as Texture2D
	if not sla_path.is_empty() and ResourceLoader.exists(sla_path):
		_tex_sla = load(sla_path) as Texture2D
	sprite.region_enabled = true
	_update_frame()


func load_sprite(path: String) -> void:
	sprite_path = path
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	if not tex:
		return
	# Auto-load companion sheet
	if "_sla" in path:
		_tex_sla = tex
		var ver := path.replace("sprites_sla", "sprites_ver").replace("_sla.", "_ver.")
		if ResourceLoader.exists(ver):
			_tex_ver = load(ver) as Texture2D
	elif "_ver" in path:
		_tex_ver = tex
		var sla := path.replace("sprites_ver", "sprites_sla").replace("_ver.", "_sla.")
		if ResourceLoader.exists(sla):
			_tex_sla = load(sla) as Texture2D
	else:
		_tex_ver = tex
	sprite.region_enabled = true
	_update_frame()


func walk(direction: int) -> void:
	current_direction = direction
	is_moving = true
	if _frame >= IDLE_FRAME:
		_frame = 0
	_update_frame()
	if anim_timer.is_stopped():
		anim_timer.start()


func idle(direction: int = -1) -> void:
	if direction >= 0:
		current_direction = direction
	is_moving = false
	_frame = IDLE_FRAME
	_update_frame()
	anim_timer.stop()


func face_towards(target_pos: Vector2) -> void:
	var delta := target_pos - global_position
	idle(vector_to_direction(delta))


static func vector_to_direction(v: Vector2) -> int:
	if v.length_squared() < 0.001:
		return Direction.S
	var angle := fmod(atan2(v.y, v.x) + TAU, TAU)
	var sector := int((angle + PI / 8.0) / (PI / 4.0)) % 8
	# sector: 0=E, 1=SE, 2=S, 3=SW, 4=W, 5=NW, 6=N, 7=NE
	const SECTOR_TO_DIR: Array[int] = [
		Direction.E, Direction.SE, Direction.S, Direction.SW,
		Direction.W, Direction.NW, Direction.N, Direction.NE,
	]
	return SECTOR_TO_DIR[sector]


func _update_frame() -> void:
	# Even directions = cardinal (VER), odd = diagonal (SLA)
	var is_diagonal := (current_direction % 2 == 1)
	var tex: Texture2D = _tex_sla if is_diagonal else _tex_ver
	if not tex:
		tex = _tex_ver if _tex_ver else _tex_sla
	if not tex:
		return
	sprite.texture = tex
	# Each sheet has 4 directions at 7 frames each, packed across 3 rows of 10
	var dir_index := current_direction / 2  # 0-3 within the sheet
	var g := dir_index * FRAMES_PER_DIR + (_frame % FRAMES_PER_DIR)
	var col := g % COLS
	var row := g / COLS
	sprite.region_rect = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
	sprite.flip_h = false


func _advance_frame() -> void:
	if not is_moving:
		return
	_frame = (_frame + 1) % IDLE_FRAME  # Cycle 0-5, skip idle frame
	_update_frame()
